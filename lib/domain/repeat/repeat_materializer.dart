import '../../features/events/data/events_dao.dart';
import '../../data/dao/instances_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../core/time/kst.dart';
import '../../db/db_signal.dart';
import 'repeat_engine.dart';
import 'provider_invalidator.dart';

/// Manages the materialization lifecycle of repeating event instances
/// Handles creating, updating, and deleting physical instance records
class RepeatMaterializer {
  final EventsDao eventsDao;
  final InstancesDao instancesDao;

  RepeatMaterializer(this.eventsDao, this.instancesDao);

  /// Materialize instances for a master event within a rolling window
  /// @param master Master event with repeat rule
  /// @param nowKst Current KST time (for testing, defaults to now)
  /// @param backfillDays How many days back to materialize (default 30)
  /// @param futureDays How many days forward to materialize (default 180)
  Future<void> runFor(
    EventEntity master, {
    DateTime? nowKst,
    int backfillDays = 30,
    int futureDays = 180,
  }) async {
    // Skip if master doesn't have a repeat rule
    if (master.rrule == null || master.rrule!.trim().isEmpty) {
      return;
    }

    final now = nowKst ?? KST.nowAsDateTime();
    final fromKst = KST.atStartOfDay(now.subtract(Duration(days: backfillDays)));
    final toKst = KST.atEndOfDay(now.add(Duration(days: futureDays)));

    // Generate desired occurrences using RepeatEngine
    final occurrences = RepeatEngine.generate(master, fromKst, toKst);

    // Convert to InstanceRow format
    final nowUtc = KST.toUtcIso(now);
    final desired = occurrences.map((occ) => InstanceRow(
      parentId: master.id,
      startUtc: KST.toUtcIso(occ.startKst),
      endUtc: KST.toUtcIso(occ.endKst),
      dayKeyKst: KST.dayKey(occ.startKst),
      instanceSeq: occ.seq,
      status: 1,
      detached: 0,
      createdAt: nowUtc,
      updatedAt: nowUtc,
    )).toList();

    // Get existing instances in the same range
    final existing = await instancesDao.findByParentWithin(master.id, fromKst, toKst);

    // Diff existing vs desired to determine changes
    final toInsert = <InstanceRow>[];
    final toUpdate = <InstanceRow>[];
    final toDelete = <InstanceRow>[];

    // Create lookup map for existing instances by (parentId, startUtc)
    final existingMap = <String, InstanceRow>{};
    for (final instance in existing) {
      final key = '${instance.parentId}|${instance.startUtc}';
      existingMap[key] = instance;
    }

    // Track which keys we expect to have
    final desiredKeys = <String>{};

    // Process desired instances
    for (final desired_instance in desired) {
      final key = '${desired_instance.parentId}|${desired_instance.startUtc}';
      desiredKeys.add(key);

      final existingInstance = existingMap[key];
      if (existingInstance == null) {
        // New instance needed
        toInsert.add(desired_instance);
      } else {
        // Check if existing instance needs updates
        final needsUpdate = existingInstance.endUtc != desired_instance.endUtc ||
                           existingInstance.instanceSeq != desired_instance.instanceSeq ||
                           existingInstance.dayKeyKst != desired_instance.dayKeyKst ||
                           existingInstance.status != 1; // Reactivate if was cancelled

        if (needsUpdate) {
          toUpdate.add(existingInstance.copyWith(
            endUtc: desired_instance.endUtc,
            instanceSeq: desired_instance.instanceSeq,
            dayKeyKst: desired_instance.dayKeyKst,
            status: 1, // Reactivate
            updatedAt: nowUtc,
          ));
        }
      }
    }

    // Find instances to delete (exist but not desired, and not detached)
    for (final existingInstance in existing) {
      final key = '${existingInstance.parentId}|${existingInstance.startUtc}';
      if (!desiredKeys.contains(key) && existingInstance.detached == 0) {
        toDelete.add(existingInstance);
      }
    }

    // Apply changes in a batch for performance
    await instancesDao.applyBatch(
      toInsert: toInsert,
      toUpdate: toUpdate,
      toDeleteOrSoft: toDelete,
    );

    // Collect affected day keys for provider invalidation
    final affectedKeys = <String>{
      ...desired.map((d) => d.dayKeyKst),
      ...existing.map((e) => e.dayKeyKst),
    }.toList();

    // Invalidate day providers and signal database changes
    await ProviderInvalidator.invalidateDays(affectedKeys);
    DbSignal.instance.pingEvents();

    // Log results in debug mode
    if (toInsert.isNotEmpty || toUpdate.isNotEmpty || toDelete.isNotEmpty) {
      print('[RepeatMaterializer] ${master.id}: '
            'inserted ${toInsert.length}, '
            'updated ${toUpdate.length}, '
            'deleted ${toDelete.length}, '
            'affected ${affectedKeys.length} days');
    }
  }

  /// Disable repeat materialization for an event
  /// Soft deletes all non-detached instances and preserves user edits
  /// @param masterId Master event ID
  /// @param keepDetached Whether to preserve detached instances (default true)
  Future<void> disable(String masterId, {bool keepDetached = true}) async {
    // Soft delete all instances for this master
    await instancesDao.softDeleteAllByParent(masterId, keepDetached: keepDetached);

    // Get affected day keys for invalidation
    final allInstances = await instancesDao.findByParentAll(masterId);
    final affectedKeys = allInstances.map((i) => i.dayKeyKst).toSet().toList();

    // Invalidate providers and signal changes
    await ProviderInvalidator.invalidateDays(affectedKeys);
    DbSignal.instance.pingEvents();

    print('[RepeatMaterializer] Disabled repeat for $masterId, '
          'affected ${affectedKeys.length} days');
  }

  /// Hard delete all instances when master event is deleted
  /// @param masterId Master event ID
  Future<void> cleanup(String masterId) async {
    // Get affected days before deletion
    final allInstances = await instancesDao.findByParentAll(masterId);
    final affectedKeys = allInstances.map((i) => i.dayKeyKst).toSet().toList();

    // Hard delete all instances
    await instancesDao.hardDeleteAllByParent(masterId);

    // Invalidate providers and signal changes
    await ProviderInvalidator.invalidateDays(affectedKeys);
    DbSignal.instance.pingEvents();

    if (allInstances.isNotEmpty) {
      print('[RepeatMaterializer] Cleaned up ${allInstances.length} instances '
            'for deleted master $masterId');
    }
  }

  /// Get instance count for a master event (for UI feedback)
  /// @param masterId Master event ID
  /// @return Number of active instances
  Future<int> getInstanceCount(String masterId) async {
    return await instancesDao.countByParent(masterId);
  }
}