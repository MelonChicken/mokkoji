import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../db/app_database.dart';
import '../../db/db_signal.dart';
import '../../features/events/data/event_entity.dart';

/// Enhanced Event DAO with real-time streams and detailed upsert logging
/// Provides conversion between ISO8601 strings and UTC milliseconds for efficient querying
class EventDao {
  Future<Database> get _db async => AppDatabase.instance.database;

  /// Stream of database changes for real-time UI updates
  Stream<void> get changes => DbSignal.instance.eventsStream;

  /// Upsert multiple events with detailed logging
  /// Returns a map with insert/update/skip counts
  Future<UpsertStats> upsertAll(List<EventModel> events) async {
    if (events.isEmpty) return UpsertStats(inserted: 0, updated: 0, skipped: 0);
    
    final db = await _db;
    int inserted = 0, updated = 0, skipped = 0;
    
    await db.transaction((txn) async {
      for (final event in events) {
        try {
          // Check if event exists based on source and uid
          final existing = await _findExisting(txn, event.source, event.uid);
          final eventEntity = _toEventEntity(event);
          
          if (existing != null) {
            // Update existing event
            final updateCount = await txn.update(
              'events',
              eventEntity.toMap(),
              where: 'id = ?',
              whereArgs: [existing['id']],
            );
            if (updateCount > 0) updated++;
          } else {
            // Insert new event
            await txn.insert(
              'events',
              eventEntity.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            inserted++;
          }
        } catch (e) {
          skipped++;
          if (kDebugMode) {
            debugPrint('[EventDao] Skip event ${event.title}: $e');
          }
        }
      }
    });
    
    if (kDebugMode) {
      debugPrint('[collect] inserted=$inserted updated=$updated skipped=$skipped');
    }
    
    // Trigger UI updates
    DbSignal.instance.pingEvents();
    
    return UpsertStats(inserted: inserted, updated: updated, skipped: skipped);
  }

  /// Find events between UTC millisecond timestamps
  Future<List<Map<String, Object?>>> findBetweenUtc(int startUtcMs, int endUtcMs) async {
    final db = await _db;
    
    // Convert UTC milliseconds back to ISO8601 strings for existing schema
    final startIso = DateTime.fromMillisecondsSinceEpoch(startUtcMs, isUtc: true).toIso8601String();
    final endIso = DateTime.fromMillisecondsSinceEpoch(endUtcMs, isUtc: true).toIso8601String();
    
    return await db.query(
      'events',
      where: 'deleted_at IS NULL AND start_dt >= ? AND start_dt < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'start_dt ASC',
    );
  }

  /// Watch events between UTC timestamps with real-time updates
  Stream<List<Map<String, Object?>>> watchBetweenUtc(int startUtcMs, int endUtcMs) async* {
    // Initial data
    yield await findBetweenUtc(startUtcMs, endUtcMs);
    
    // Listen for changes and re-query
    await for (final _ in changes) {
      yield await findBetweenUtc(startUtcMs, endUtcMs);
    }
  }

  /// Find recently created events (for debugging)
  Future<List<Map<String, Object?>>> recentCreated(int minutes) async {
    final db = await _db;
    final cutoffTime = DateTime.now()
        .subtract(Duration(minutes: minutes))
        .toIso8601String();
    
    return await db.query(
      'events',
      where: 'updated_at >= ? AND deleted_at IS NULL',
      whereArgs: [cutoffTime],
      orderBy: 'updated_at DESC',
      limit: 50,
    );
  }

  /// Convert local date to UTC millisecond range for efficient querying
  (int, int) utcRangeOfLocalDay(DateTime localDate) {
    final startOfDay = DateTime(localDate.year, localDate.month, localDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (
      startOfDay.toUtc().millisecondsSinceEpoch,
      endOfDay.toUtc().millisecondsSinceEpoch,
    );
  }

  /// Find existing event by source and uid
  Future<Map<String, Object?>?> _findExisting(
    DatabaseExecutor db, 
    String source, 
    String? uid,
  ) async {
    if (uid == null) return null;
    
    final rows = await db.query(
      'events',
      where: 'source_platform = ? AND ical_uid = ? AND deleted_at IS NULL',
      whereArgs: [source, uid],
      limit: 1,
    );
    
    return rows.isEmpty ? null : rows.first;
  }

  /// Convert EventModel to EventEntity for database storage
  EventEntity _toEventEntity(EventModel model) {
    final now = DateTime.now().toUtc().toIso8601String();
    
    return EventEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      startDt: model.start.toIso8601String(),
      endDt: model.end?.toIso8601String(),
      allDay: model.allDay,
      location: model.location,
      sourcePlatform: model.source,
      platformColor: model.platformColor,
      icalUid: model.uid,
      tzid: model.tzid,
      updatedAt: now,
      deletedAt: null,
    );
  }
}

/// Statistics for upsert operations
class UpsertStats {
  final int inserted;
  final int updated;
  final int skipped;

  const UpsertStats({
    required this.inserted,
    required this.updated,
    required this.skipped,
  });

  int get total => inserted + updated;

  @override
  String toString() {
    return 'UpsertStats(inserted: $inserted, updated: $updated, skipped: $skipped)';
  }
}

/// Model class for events during collection
class EventModel {
  final String id;
  final String source;          // google/naver/kakao/internal
  final String? uid;            // external event uid
  final String title;
  final String? description;
  final DateTime start;         // UTC DateTime
  final DateTime? end;          // UTC DateTime
  final bool allDay;
  final String? location;
  final String? tzid;
  final String? platformColor;
  final int priority;

  const EventModel({
    required this.id,
    required this.source,
    this.uid,
    required this.title,
    this.description,
    required this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.tzid,
    this.platformColor,
    this.priority = 1,
  });

  /// Create EventModel from external API data
  factory EventModel.fromExternal({
    required String source,
    required String uid,
    required String title,
    String? description,
    required DateTime startUtc,
    DateTime? endUtc,
    bool allDay = false,
    String? location,
    String? tzid,
    String? color,
  }) {
    return EventModel(
      id: '${source}_$uid',
      source: source,
      uid: uid,
      title: title,
      description: description,
      start: startUtc,
      end: endUtc,
      allDay: allDay,
      location: location,
      tzid: tzid,
      platformColor: color,
    );
  }

  /// Convert database row to EventModel
  factory EventModel.fromRow(Map<String, Object?> row) {
    return EventModel(
      id: row['id'] as String,
      source: row['source_platform'] as String,
      uid: row['ical_uid'] as String?,
      title: row['title'] as String,
      description: row['description'] as String?,
      start: DateTime.parse(row['start_dt'] as String),
      end: row['end_dt'] != null ? DateTime.parse(row['end_dt'] as String) : null,
      allDay: (row['all_day'] as int) == 1,
      location: row['location'] as String?,
      tzid: row['tzid'] as String?,
      platformColor: row['platform_color'] as String?,
      priority: 1, // Default priority
    );
  }
}