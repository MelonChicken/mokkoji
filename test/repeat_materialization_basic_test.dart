import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/core/time/kst.dart';
import '../lib/data/repeat/repeat_materializer.dart';
import '../lib/data/repeat/materialization_window.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/domain/repeat/repeat_engine.dart';

// Mock EventsDao for testing
class MockEventsDao {
  final Database db;
  MockEventsDao(this.db);

  Future<EventEntity?> getById(String id) async {
    final rows = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : EventEntity.fromMap(rows.first);
  }
}

void main() {
  group('Repeat Materialization Basic Tests', () {
    late Database testDb;
    late MockEventsDao mockEventsDao;
    late RepeatMaterializer materializer;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      KST.init();
    });

    setUp(() async {
      // Create in-memory test database
      testDb = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          // Create events table (based on AppDatabase schema)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS events (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              start_dt TEXT NOT NULL,
              end_dt TEXT,
              all_day INTEGER NOT NULL,
              location TEXT,
              source_platform TEXT NOT NULL,
              platform_color TEXT,
              recurrence_rule TEXT,
              status TEXT,
              attendees_json TEXT,
              updated_at TEXT NOT NULL,
              deleted_at TEXT,
              ical_uid TEXT,
              dtstamp TEXT,
              sequence INTEGER,
              rrule TEXT,
              rdate_json TEXT,
              exdate_json TEXT,
              tzid TEXT,
              transparency TEXT,
              url TEXT,
              categories_json TEXT,
              organizer_email TEXT,
              geo_lat REAL,
              geo_lng REAL,
              duration_min INTEGER NOT NULL DEFAULT 60
            )
          ''');

          // Create event_instances table
          await db.execute('''
            CREATE TABLE event_instances (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              master_event_id TEXT NOT NULL,
              start_utc TEXT NOT NULL,
              end_utc TEXT NOT NULL,
              is_detached INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (master_event_id) REFERENCES events (id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE UNIQUE INDEX idx_event_instances_unique
            ON event_instances (master_event_id, start_utc, end_utc)
          ''');
        },
      );

      mockEventsDao = MockEventsDao(testDb);
      materializer = RepeatMaterializer(
        db: testDb,
        eventsDao: mockEventsDao,
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('should create instances for daily recurring event', () async {
      // Create a daily recurring event
      final masterId = 'test-daily-event';
      final master = EventEntity(
        id: masterId,
        title: 'Daily Standup',
        description: 'Team standup meeting',
        startDt: '2025-09-14T09:00:00.000Z', // KST 18:00
        endDt: '2025-09-14T10:00:00.000Z',   // KST 19:00
        durationMin: 60,
        allDay: false,
        sourcePlatform: 'internal',
        rrule: 'FREQ=DAILY;COUNT=5', // 5 occurrences
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      // Insert master event
      await testDb.insert('events', master.toMap());

      // Materialize instances
      await materializer.rebuildWindow(masterId: masterId);

      // Check that instances were created
      final instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
        orderBy: 'start_utc ASC',
      );

      expect(instances.length, equals(5));

      // Verify the instances are consecutive days
      expect(instances[0]['start_utc'], equals('2025-09-14T09:00:00.000Z'));
      expect(instances[1]['start_utc'], equals('2025-09-15T09:00:00.000Z'));
      expect(instances[2]['start_utc'], equals('2025-09-16T09:00:00.000Z'));
      expect(instances[3]['start_utc'], equals('2025-09-17T09:00:00.000Z'));
      expect(instances[4]['start_utc'], equals('2025-09-18T09:00:00.000Z'));
    });

    test('should remove instances when recurrence is disabled', () async {
      // Create and materialize a recurring event first
      final masterId = 'test-disable-event';
      final master = EventEntity(
        id: masterId,
        title: 'Weekly Meeting',
        description: 'Team meeting',
        startDt: '2025-09-14T09:00:00.000Z',
        endDt: '2025-09-14T10:00:00.000Z',
        durationMin: 60,
        allDay: false,
        sourcePlatform: 'internal',
        rrule: 'FREQ=WEEKLY;COUNT=3',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.rebuildWindow(masterId: masterId);

      // Verify instances were created
      var instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
      );
      expect(instances.length, equals(3));

      // Now disable recurrence by removing rrule
      await testDb.update(
        'events',
        {'rrule': null},
        where: 'id = ?',
        whereArgs: [masterId],
      );

      // Rebuild window (this should remove all instances)
      await materializer.rebuildWindow(masterId: masterId);

      // Verify instances were removed
      instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
      );
      expect(instances.length, equals(0));
    });

    test('should preserve detached instances when recurrence changes', () async {
      final masterId = 'test-detached-event';
      final master = EventEntity(
        id: masterId,
        title: 'Flexible Meeting',
        description: 'Meeting that can be edited',
        startDt: '2025-09-14T09:00:00.000Z',
        endDt: '2025-09-14T10:00:00.000Z',
        durationMin: 60,
        allDay: false,
        sourcePlatform: 'internal',
        rrule: 'FREQ=DAILY;COUNT=3',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.rebuildWindow(masterId: masterId);

      // Mark the second instance as detached
      var instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
        orderBy: 'start_utc ASC',
      );
      expect(instances.length, equals(3));

      final secondInstanceId = instances[1]['id'] as int;
      await testDb.update(
        'event_instances',
        {'is_detached': 1},
        where: 'id = ?',
        whereArgs: [secondInstanceId],
      );

      // Change recurrence to reduce count
      await testDb.update(
        'events',
        {'rrule': 'FREQ=DAILY;COUNT=2'},
        where: 'id = ?',
        whereArgs: [masterId],
      );

      // Rebuild window
      await materializer.rebuildWindow(masterId: masterId);

      // Should have 2 regular instances + 1 detached (preserved)
      instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
        orderBy: 'start_utc ASC',
      );

      expect(instances.length, equals(3));
      expect(instances[1]['is_detached'], equals(1));
    });
  });
}