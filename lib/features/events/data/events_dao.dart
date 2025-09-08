import 'package:sqflite/sqflite.dart';
import '../../../db/app_database.dart';
import '../../../db/db_signal.dart';
import 'event_entity.dart';

class EventsDao {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> upsertAll(List<EventEntity> items) async {
    if (items.isEmpty) return;
    final db = await _db;
    await db.transaction((tx) async {
      final batch = tx.batch();
      for (final e in items) {
        batch.insert(
          'events',
          e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    DbSignal.instance.pingEvents(); // ✅ 커밋 후 신호
  }

  Future<void> upsert(EventEntity item) async {
    final db = await _db;
    await db.insert(
      'events',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    DbSignal.instance.pingEvents(); // ✅ 변경 후 신호
  }

  Future<List<EventEntity>> range(
    String startIso,
    String endIso, {
    List<String>? platforms,
  }) async {
    final db = await _db;
    final args = <Object?>[startIso, endIso];
    final where = StringBuffer('deleted_at IS NULL AND start_dt >= ? AND start_dt < ?');
    
    if (platforms != null && platforms.isNotEmpty) {
      where.write(' AND source_platform IN (${List.filled(platforms.length, '?').join(',')})');
      args.addAll(platforms);
    }
    
    final rows = await db.query(
      'events',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'start_dt ASC',
    );
    
    return rows.map(EventEntity.fromMap).toList();
  }

  Future<EventEntity?> getById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : EventEntity.fromMap(rows.first);
  }

  Future<EventEntity?> getByIcalUid(String icalUid) async {
    final db = await _db;
    final rows = await db.query(
      'events',
      where: 'ical_uid = ? AND deleted_at IS NULL',
      whereArgs: [icalUid],
      limit: 1,
    );
    return rows.isEmpty ? null : EventEntity.fromMap(rows.first);
  }

  Future<List<EventEntity>> getByIcalUids(List<String> icalUids) async {
    if (icalUids.isEmpty) return [];
    final db = await _db;
    final placeholders = List.filled(icalUids.length, '?').join(',');
    final rows = await db.query(
      'events',
      where: 'ical_uid IN ($placeholders) AND deleted_at IS NULL',
      whereArgs: icalUids,
    );
    return rows.map(EventEntity.fromMap).toList();
  }

  Future<void> softDelete(String id, String deletedAtIso) async {
    final db = await _db;
    await db.update(
      'events',
      {'deleted_at': deletedAtIso},
      where: 'id = ?',
      whereArgs: [id],
    );
    DbSignal.instance.pingEvents(); // ✅ 변경 후 신호
  }

  Future<void> softDeleteByIcalUid(String icalUid, String deletedAtIso) async {
    final db = await _db;
    await db.update(
      'events',
      {'deleted_at': deletedAtIso},
      where: 'ical_uid = ?',
      whereArgs: [icalUid],
    );
    DbSignal.instance.pingEvents(); // ✅ 변경 후 신호
  }

  Future<void> hardDelete(String id) async {
    final db = await _db;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    DbSignal.instance.pingEvents(); // ✅ 삭제 후 신호
  }

  Future<void> cleanupDeleted({int daysAgo = 30}) async {
    final db = await _db;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysAgo))
        .toIso8601String();
    
    final deleted = await db.delete(
      'events',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoffDate],
    );
    if (deleted > 0) {
      DbSignal.instance.pingEvents(); // ✅ 정리 후 신호
    }
  }

  Future<int> countAll() async {
    final db = await _db;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM events WHERE deleted_at IS NULL'),
    );
    return result ?? 0;
  }

  Future<List<EventEntity>> getRecurringEvents({
    String? startIso,
    String? endIso,
  }) async {
    final db = await _db;
    final where = StringBuffer('deleted_at IS NULL AND (rrule IS NOT NULL OR recurrence_rule IS NOT NULL)');
    final args = <Object?>[];
    
    if (startIso != null && endIso != null) {
      where.write(' AND start_dt >= ? AND start_dt < ?');
      args..add(startIso)..add(endIso);
    }
    
    final rows = await db.query(
      'events',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'start_dt ASC',
    );
    
    return rows.map(EventEntity.fromMap).toList();
  }
}