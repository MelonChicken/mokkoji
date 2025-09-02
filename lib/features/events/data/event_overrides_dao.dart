import 'package:sqflite/sqflite.dart';
import '../../../db/app_database.dart';
import '../../../db/db_signal.dart';
import 'event_override_entity.dart';

class EventOverridesDao {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> upsertAll(List<EventOverrideEntity> items) async {
    if (items.isEmpty) return;
    final db = await _db;
    await db.transaction((tx) async {
      final batch = tx.batch();
      for (final o in items) {
        batch.insert(
          'event_overrides',
          o.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    DbSignal.instance.pingOverrides(); // ✅ 커밋 후 신호
  }

  Future<List<EventOverrideEntity>> forParentUid(
    String icalUid, {
    String? startIso,
    String? endIso,
  }) async {
    final db = await _db;
    final where = StringBuffer('ical_uid = ?');
    final args = <Object?>[icalUid];
    
    if (startIso != null && endIso != null) {
      where.write(' AND recurrence_id >= ? AND recurrence_id < ?');
      args..add(startIso)..add(endIso);
    }
    
    final rows = await db.query(
      'event_overrides',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'recurrence_id ASC',
    );
    
    return rows.map(EventOverrideEntity.fromMap).toList();
  }

  Future<EventOverrideEntity?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'event_overrides',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : EventOverrideEntity.fromMap(rows.first);
  }

  Future<EventOverrideEntity?> getByRecurrenceId(
    String icalUid,
    String recurrenceId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'event_overrides',
      where: 'ical_uid = ? AND recurrence_id = ?',
      whereArgs: [icalUid, recurrenceId],
      limit: 1,
    );
    return rows.isEmpty ? null : EventOverrideEntity.fromMap(rows.first);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(
      'event_overrides',
      where: 'id = ?',
      whereArgs: [id],
    );
    DbSignal.instance.pingOverrides(); // ✅ 삭제 후 신호
  }

  Future<void> deleteByParentUid(String icalUid) async {
    final db = await _db;
    final deleted = await db.delete(
      'event_overrides',
      where: 'ical_uid = ?',
      whereArgs: [icalUid],
    );
    if (deleted > 0) {
      DbSignal.instance.pingOverrides(); // ✅ 삭제 후 신호
    }
  }

  Future<int> countAll() async {
    final db = await _db;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM event_overrides'),
    );
    return result ?? 0;
  }
}