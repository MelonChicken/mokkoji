import 'package:sqflite/sqflite.dart';
import '../../db/app_database.dart';
import '../../core/time/kst.dart';

/// Data class for event instance row
class InstanceRow {
  final int? id;
  final String parentId;
  final String startUtc;        // ISO 8601 Z
  final String endUtc;          // ISO 8601 Z
  final String dayKeyKst;       // 'YYYY-MM-DD' for KST display
  final int instanceSeq;        // 0..N order from rule
  final int status;             // 1=active, 0=cancelled(soft)
  final int detached;           // per-instance edit detached from master
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const InstanceRow({
    this.id,
    required this.parentId,
    required this.startUtc,
    required this.endUtc,
    required this.dayKeyKst,
    required this.instanceSeq,
    this.status = 1,
    this.detached = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'parent_id': parentId,
    'start_utc': startUtc,
    'end_utc': endUtc,
    'day_key_kst': dayKeyKst,
    'instance_seq': instanceSeq,
    'status': status,
    'detached': detached,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };

  static InstanceRow fromMap(Map<String, Object?> m) => InstanceRow(
    id: m['id'] as int?,
    parentId: m['parent_id'] as String,
    startUtc: m['start_utc'] as String,
    endUtc: m['end_utc'] as String,
    dayKeyKst: m['day_key_kst'] as String,
    instanceSeq: m['instance_seq'] as int,
    status: (m['status'] as int?) ?? 1,
    detached: (m['detached'] as int?) ?? 0,
    createdAt: m['created_at'] as String,
    updatedAt: m['updated_at'] as String,
    deletedAt: m['deleted_at'] as String?,
  );

  InstanceRow copyWith({
    int? id,
    String? parentId,
    String? startUtc,
    String? endUtc,
    String? dayKeyKst,
    int? instanceSeq,
    int? status,
    int? detached,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
  }) => InstanceRow(
    id: id ?? this.id,
    parentId: parentId ?? this.parentId,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    dayKeyKst: dayKeyKst ?? this.dayKeyKst,
    instanceSeq: instanceSeq ?? this.instanceSeq,
    status: status ?? this.status,
    detached: detached ?? this.detached,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  @override
  String toString() =>
    'InstanceRow{id: $id, parent: $parentId, seq: $instanceSeq, '
    'start: $startUtc, day: $dayKeyKst, status: $status, detached: $detached}';
}

/// DAO for event instances table with efficient batch operations
class InstancesDao {
  final Database db;

  InstancesDao(this.db);

  /// Find instances by parent event within KST date range
  Future<List<InstanceRow>> findByParentWithin(
    String parentId,
    DateTime fromKst,
    DateTime toKst
  ) async {
    // Convert KST range to day keys for efficient lookup
    final startKey = _kstToDayKey(fromKst);
    final endKey = _kstToDayKey(toKst);

    final result = await db.query(
      'event_instances',
      where: 'parent_id = ? AND day_key_kst >= ? AND day_key_kst <= ? AND deleted_at IS NULL',
      whereArgs: [parentId, startKey, endKey],
      orderBy: 'start_utc ASC',
    );

    return result.map(InstanceRow.fromMap).toList();
  }

  /// Find all instances for a specific KST day
  Future<List<InstanceRow>> findByDayKey(String dayKeyKst) async {
    final result = await db.query(
      'event_instances',
      where: 'day_key_kst = ? AND status = 1 AND deleted_at IS NULL',
      whereArgs: [dayKeyKst],
      orderBy: 'start_utc ASC',
    );

    return result.map(InstanceRow.fromMap).toList();
  }

  /// Find instances by parent ID (all, including soft deleted)
  Future<List<InstanceRow>> findByParentAll(String parentId) async {
    final result = await db.query(
      'event_instances',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'instance_seq ASC',
    );

    return result.map(InstanceRow.fromMap).toList();
  }

  /// Apply batch operations efficiently (target: ≤200ms)
  Future<void> applyBatch({
    required List<InstanceRow> toInsert,
    required List<InstanceRow> toUpdate,
    required List<InstanceRow> toDeleteOrSoft,
  }) async {
    if (toInsert.isEmpty && toUpdate.isEmpty && toDeleteOrSoft.isEmpty) {
      return; // Nothing to do
    }

    final batch = db.batch();

    // Insert new instances
    for (final instance in toInsert) {
      batch.insert('event_instances', instance.toMap());
    }

    // Update existing instances
    for (final instance in toUpdate) {
      if (instance.id == null) continue;
      batch.update(
        'event_instances',
        instance.toMap(),
        where: 'id = ?',
        whereArgs: [instance.id],
      );
    }

    // Delete or soft delete instances
    final now = DateTime.now().toUtc().toIso8601String();
    for (final instance in toDeleteOrSoft) {
      if (instance.id == null) continue;

      if (instance.detached == 1) {
        // Soft delete detached instances to preserve user edits
        batch.update(
          'event_instances',
          {
            'status': 0,
            'deleted_at': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [instance.id],
        );
      } else {
        // Hard delete non-detached instances
        batch.delete(
          'event_instances',
          where: 'id = ?',
          whereArgs: [instance.id],
        );
      }
    }

    // Execute batch efficiently
    await batch.commit(noResult: true);
  }

  /// Soft delete all instances by parent, optionally keeping detached ones
  Future<void> softDeleteAllByParent(String parentId, {bool keepDetached = true}) async {
    final now = DateTime.now().toUtc().toIso8601String();

    if (keepDetached) {
      // Only delete non-detached instances
      await db.update(
        'event_instances',
        {
          'status': 0,
          'deleted_at': now,
          'updated_at': now,
        },
        where: 'parent_id = ? AND detached = 0 AND deleted_at IS NULL',
        whereArgs: [parentId],
      );
    } else {
      // Delete all instances for this parent
      await db.update(
        'event_instances',
        {
          'status': 0,
          'deleted_at': now,
          'updated_at': now,
        },
        where: 'parent_id = ? AND deleted_at IS NULL',
        whereArgs: [parentId],
      );
    }
  }

  /// Hard delete all instances by parent (for when master event is deleted)
  Future<void> hardDeleteAllByParent(String parentId) async {
    await db.delete(
      'event_instances',
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );
  }

  /// Mark instance as detached (edited individually)
  Future<void> markDetached(int instanceId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'event_instances',
      {
        'detached': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [instanceId],
    );
  }

  /// Get instance by ID
  Future<InstanceRow?> getById(int id) async {
    final result = await db.query(
      'event_instances',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return InstanceRow.fromMap(result.first);
  }

  /// Count active instances for a parent
  Future<int> countByParent(String parentId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM event_instances '
      'WHERE parent_id = ? AND status = 1 AND deleted_at IS NULL',
      [parentId],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Helper to convert KST DateTime to day key string
  String _kstToDayKey(DateTime kstDateTime) {
    return '${kstDateTime.year.toString().padLeft(4, '0')}-'
           '${kstDateTime.month.toString().padLeft(2, '0')}-'
           '${kstDateTime.day.toString().padLeft(2, '0')}';
  }
}

/// Extension to create InstancesDao from AppDatabase
extension AppDatabaseInstances on AppDatabase {
  Future<InstancesDao> get instancesDao async {
    final db = await database;
    return InstancesDao(db);
  }
}