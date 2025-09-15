import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../core/time/kst.dart';
import '../../core/recurrence/rrule_codec.dart';
import '../../domain/repeat/repeat_engine.dart';
import '../../db/db_signal.dart';
import 'materialization_window.dart';

/// Occurrence instance for materialization
class InstanceOccurrence {
  final DateTime startUtc;
  final DateTime endUtc;
  final String masterEventId;

  const InstanceOccurrence({
    required this.startUtc,
    required this.endUtc,
    required this.masterEventId,
  });

  String get key => '${masterEventId}|${startUtc.toIso8601String()}|${endUtc.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstanceOccurrence &&
          startUtc == other.startUtc &&
          endUtc == other.endUtc &&
          masterEventId == other.masterEventId;

  @override
  int get hashCode => startUtc.hashCode ^ endUtc.hashCode ^ masterEventId.hashCode;
}

/// Existing instance record from database
class ExistingInstance {
  final int? id;
  final String masterEventId;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isDetached;

  const ExistingInstance({
    required this.id,
    required this.masterEventId,
    required this.startUtc,
    required this.endUtc,
    required this.isDetached,
  });

  String get key => '${masterEventId}|${startUtc.toIso8601String()}|${endUtc.toIso8601String()}';
}

/// Manages repeat instance materialization with immediate UI updates
class RepeatMaterializer {
  final Database _db;
  final EventsDao _eventsDao;

  RepeatMaterializer({
    required Database db,
    required EventsDao eventsDao,
  }) : _db = db,
       _eventsDao = eventsDao;

  /// Rebuild instances for a master event within the given window
  /// This is the core method that ensures UI consistency
  Future<void> rebuildWindow({
    required String masterId,
    MaterializationWindow? window,
    bool preserveDetached = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Use standard window if none provided
    final effectiveWindow = window ?? MaterializationWindow.standard();

    if (kDebugMode) {
      debugPrint('[RepeatMaterializer] Starting rebuild for $masterId in $effectiveWindow');
    }

    // Load master event
    final master = await _eventsDao.getById(masterId);
    if (master == null) {
      if (kDebugMode) {
        debugPrint('[RepeatMaterializer] Master event not found: $masterId');
      }
      return;
    }

    // Check if master has recurrence rule
    final repeatRule = RepeatRule.fromRRule(master.rrule);
    if (repeatRule == null || repeatRule.isNone) {
      // No recurrence - remove all instances for this master in window
      await _purgeInstancesInWindow(masterId, effectiveWindow, preserveDetached);
      _logCompletion('No recurrence rule', stopwatch, masterId, 0, 0, 0, 0, 0);
      return;
    }

    // Convert master times to KST for rule expansion
    final masterStartKst = KST.kstAnchorFromUtc(DateTime.parse(master.startDt));
    final masterEndKst = master.endDt != null
        ? KST.kstAnchorFromUtc(DateTime.parse(master.endDt!))
        : masterStartKst.add(Duration(minutes: master.durationMin));

    // Generate occurrences strictly in KST
    final occurrences = RepeatEngine.generate(master,
      effectiveWindow.startKst.toLocal(),
      effectiveWindow.endKst.toLocal()
    );

    // Convert to UTC instances set S
    final generatedSet = <InstanceOccurrence>{};
    for (final occ in occurrences) {
      final startKst = tz.TZDateTime.from(occ.startKst, masterStartKst.location);
      final endKst = tz.TZDateTime.from(occ.endKst, masterEndKst.location);

      generatedSet.add(InstanceOccurrence(
        startUtc: KST.utcFromKst(startKst),
        endUtc: KST.utcFromKst(endKst),
        masterEventId: masterId,
      ));
    }

    // Query existing instances E in window
    final existingInstances = await _getExistingInstancesInWindow(masterId, effectiveWindow);
    final existingSet = <InstanceOccurrence>{};
    final detachedInstances = <ExistingInstance>[];

    for (final existing in existingInstances) {
      if (existing.isDetached && preserveDetached) {
        detachedInstances.add(existing);
      } else {
        existingSet.add(InstanceOccurrence(
          startUtc: existing.startUtc,
          endUtc: existing.endUtc,
          masterEventId: existing.masterEventId,
        ));
      }
    }

    // DIFF: S - E (non-detached) and E (non-detached) - S
    final toInsert = generatedSet.difference(existingSet).toList();
    final toDelete = existingSet.difference(generatedSet).toList();

    // Execute in single transaction
    await _db.transaction((txn) async {
      final batch = txn.batch();

      // Insert new instances
      for (final instance in toInsert) {
        batch.insert('event_instances', {
          'master_event_id': instance.masterEventId,
          'start_utc': instance.startUtc.toIso8601String(),
          'end_utc': instance.endUtc.toIso8601String(),
          'is_detached': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // Delete obsolete instances
      for (final instance in toDelete) {
        batch.delete(
          'event_instances',
          where: 'master_event_id = ? AND start_utc = ? AND end_utc = ? AND is_detached = 0',
          whereArgs: [instance.masterEventId, instance.startUtc.toIso8601String(), instance.endUtc.toIso8601String()],
        );
      }

      await batch.commit(noResult: true);
    });

    _logCompletion(
      'Success',
      stopwatch,
      masterId,
      existingInstances.length,
      generatedSet.length,
      toInsert.length,
      toDelete.length,
      detachedInstances.length,
    );

    // Signal database changes for affected date ranges
    await _signalAffectedRanges(masterId, generatedSet, existingSet, effectiveWindow);
  }

  /// Purge all instances for master in window
  Future<void> _purgeInstancesInWindow(String masterId, MaterializationWindow window, bool preserveDetached) async {
    final deleteCount = await _db.delete(
      'event_instances',
      where: '''
        master_event_id = ? AND
        start_utc >= ? AND
        end_utc <= ? AND
        is_detached = ?
      ''',
      whereArgs: [
        masterId,
        window.startUtc.toIso8601String(),
        window.endUtc.toIso8601String(),
        preserveDetached ? 0 : null, // If preserveDetached is false, delete all (use null to ignore is_detached)
      ],
    );

    if (kDebugMode) {
      debugPrint('[RepeatMaterializer] Purged $deleteCount instances for $masterId');
    }
  }

  /// Get existing instances in window
  Future<List<ExistingInstance>> _getExistingInstancesInWindow(String masterId, MaterializationWindow window) async {
    final results = await _db.query(
      'event_instances',
      where: '''
        master_event_id = ? AND
        start_utc >= ? AND
        end_utc <= ?
      ''',
      whereArgs: [
        masterId,
        window.startUtc.toIso8601String(),
        window.endUtc.toIso8601String(),
      ],
    );

    return results.map((row) => ExistingInstance(
      id: row['id'] as int?,
      masterEventId: row['master_event_id'] as String,
      startUtc: DateTime.parse(row['start_utc'] as String),
      endUtc: DateTime.parse(row['end_utc'] as String),
      isDetached: (row['is_detached'] as int) == 1,
    )).toList();
  }

  /// Signal affected date ranges for provider invalidation
  Future<void> _signalAffectedRanges(
    String masterId,
    Set<InstanceOccurrence> generatedSet,
    Set<InstanceOccurrence> existingSet,
    MaterializationWindow window,
  ) async {
    // Collect all affected date keys from both old and new instances
    final affectedKeys = <String>{};

    // Add keys from generated instances
    for (final instance in generatedSet) {
      final startKst = KST.kstAnchorFromUtc(instance.startUtc);
      final endKst = KST.kstAnchorFromUtc(instance.endUtc);
      affectedKeys.addAll(KST.getAffectedDateKeys(startKst, endKst));
    }

    // Add keys from existing instances that were removed
    for (final instance in existingSet) {
      final startKst = KST.kstAnchorFromUtc(instance.startUtc);
      final endKst = KST.kstAnchorFromUtc(instance.endUtc);
      affectedKeys.addAll(KST.getAffectedDateKeys(startKst, endKst));
    }

    // Signal database changes
    DbSignal.instance.pingEvents();

    if (kDebugMode) {
      debugPrint('[RepeatMaterializer] Signaled ${affectedKeys.length} affected date keys: ${affectedKeys.take(5)}${affectedKeys.length > 5 ? '...' : ''}');
    }
  }

  /// Log materialization completion with timing and counts
  void _logCompletion(
    String status,
    Stopwatch stopwatch,
    String masterId,
    int existingCount,
    int generatedCount,
    int insertedCount,
    int deletedCount,
    int detachedCount,
  ) {
    if (!kDebugMode) return;

    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;

    debugPrint('[RepeatMaterializer] $status for $masterId in ${elapsed}ms: '
               'existing=$existingCount, generated=$generatedCount, '
               'inserted=$insertedCount, deleted=$deletedCount, detached=$detachedCount');
  }

  /// Disable recurrence for a master event
  Future<void> disableRecurrence(String masterId, {MaterializationWindow? window}) async {
    await rebuildWindow(
      masterId: masterId,
      window: window ?? MaterializationWindow.standard(),
      preserveDetached: true,
    );
  }

  /// Clean up all instances when master is deleted
  Future<void> cleanupMaster(String masterId) async {
    final deleteCount = await _db.delete(
      'event_instances',
      where: 'master_event_id = ?',
      whereArgs: [masterId],
    );

    if (kDebugMode) {
      debugPrint('[RepeatMaterializer] Cleaned up $deleteCount instances for deleted master $masterId');
    }

    DbSignal.instance.pingEvents();
  }
}