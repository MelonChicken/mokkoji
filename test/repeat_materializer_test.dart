import 'package:flutter_test/flutter_test.dart';
import '../lib/core/time/kst.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/features/events/data/events_dao.dart';
import '../lib/data/dao/instances_dao.dart';
import '../lib/domain/repeat/repeat_materializer.dart';
import '../lib/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    KST.init();
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RepeatMaterializer', () {
    late Database testDb;
    late EventsDao eventsDao;
    late InstancesDao instancesDao;
    late RepeatMaterializer materializer;

    setUp(() async {
      // Create in-memory database for testing
      testDb = await openDatabase(
        ':memory:',
        version: 5,
        onCreate: (db, version) async {
          // Create events table
          await db.execute('''
            CREATE TABLE events (
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

          // Create instances table
          await db.execute('''
            CREATE TABLE event_instances (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              parent_id TEXT NOT NULL,
              start_utc TEXT NOT NULL,
              end_utc   TEXT NOT NULL,
              day_key_kst TEXT NOT NULL,
              instance_seq INTEGER NOT NULL,
              status INTEGER NOT NULL DEFAULT 1,
              detached INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');

          await db.execute('''
            CREATE UNIQUE INDEX uq_inst_parent_start
            ON event_instances(parent_id, start_utc)
          ''');
        },
      );

      eventsDao = EventsDao();
      instancesDao = InstancesDao(testDb);
      materializer = RepeatMaterializer(eventsDao, instancesDao);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('should materialize daily repeat instances', () async {
      // Create a daily repeating event
      final startKst = DateTime(2025, 9, 14, 9, 0);
      final master = EventEntity(
        id: 'daily-test',
        title: 'Daily Meeting',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=3',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Insert master event
      await testDb.insert('events', master.toMap());

      // Materialize instances
      await materializer.runFor(master, nowKst: DateTime(2025, 9, 14, 8, 0));

      // Check instances were created
      final instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(3));

      // Verify sequence and dates
      expect(instances[0].instanceSeq, equals(0));
      expect(instances[1].instanceSeq, equals(1));
      expect(instances[2].instanceSeq, equals(2));

      // Verify day keys
      expect(instances[0].dayKeyKst, equals('2025-09-14'));
      expect(instances[1].dayKeyKst, equals('2025-09-15'));
      expect(instances[2].dayKeyKst, equals('2025-09-16'));
    });

    test('should update existing instances when rule changes', () async {
      final startKst = DateTime(2025, 9, 14, 10, 0);
      var master = EventEntity(
        id: 'update-test',
        title: 'Updated Meeting',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=2',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());

      // Initial materialization
      await materializer.runFor(master);
      var instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(2));

      // Update the rule to have 4 occurrences
      master = master.copyWith(
        rrule: 'FREQ=DAILY;COUNT=4',
        updatedAt: DateTime.now().toIso8601String(),
      );
      await testDb.update('events', master.toMap(), where: 'id = ?', whereArgs: [master.id]);

      // Re-materialize
      await materializer.runFor(master);
      instances = await instancesDao.findByParentAll(master.id);

      // Should now have 4 instances
      expect(instances.length, equals(4));
    });

    test('should preserve detached instances when disabling repeat', () async {
      final startKst = DateTime(2025, 9, 14, 11, 0);
      final master = EventEntity(
        id: 'detached-test',
        title: 'Meeting with Edits',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=3',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.runFor(master);

      var instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(3));

      // Mark middle instance as detached
      final middleInstance = instances[1];
      await instancesDao.markDetached(middleInstance.id!);

      // Disable repeat
      await materializer.disable(master.id, keepDetached: true);

      // Check results
      instances = await instancesDao.findByParentAll(master.id);

      // Should have 1 detached instance remaining, others soft deleted
      final activeInstances = instances.where((i) => i.status == 1).toList();
      final deletedInstances = instances.where((i) => i.status == 0).toList();

      expect(activeInstances.length, equals(1));
      expect(activeInstances[0].detached, equals(1));
      expect(deletedInstances.length, equals(2));
    });

    test('should handle cross-day events correctly', () async {
      // Event from 23:30 to 01:30 next day
      final startKst = DateTime(2025, 9, 14, 23, 30);
      final master = EventEntity(
        id: 'cross-day-test',
        title: 'Late Night Event',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 2))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 120,
        rrule: 'FREQ=DAILY;COUNT=2',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.runFor(master);

      final instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(2));

      // Both instances should have day_key_kst based on start day (not end day)
      expect(instances[0].dayKeyKst, equals('2025-09-14'));
      expect(instances[1].dayKeyKst, equals('2025-09-15'));

      // Verify times
      final inst1Start = KST.fromUtcIso(instances[0].startUtc);
      final inst1End = KST.fromUtcIso(instances[0].endUtc);

      expect(inst1Start.hour, equals(23));
      expect(inst1Start.minute, equals(30));
      expect(inst1End.hour, equals(1));
      expect(inst1End.minute, equals(30));
      expect(inst1End.day, equals(inst1Start.day + 1)); // Next day
    });

    test('should clean up all instances when master is deleted', () async {
      final startKst = DateTime(2025, 9, 14, 12, 0);
      final master = EventEntity(
        id: 'cleanup-test',
        title: 'To Be Deleted',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=3',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.runFor(master);

      var instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(3));

      // Clean up (simulate master deletion)
      await materializer.cleanup(master.id);

      // All instances should be gone
      instances = await instancesDao.findByParentAll(master.id);
      expect(instances.length, equals(0));
    });

    test('should get correct instance count', () async {
      final startKst = DateTime(2025, 9, 14, 13, 0);
      final master = EventEntity(
        id: 'count-test',
        title: 'Count Me',
        startDt: KST.toUtcIso(startKst),
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=5',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());
      await materializer.runFor(master);

      final count = await materializer.getInstanceCount(master.id);
      expect(count, equals(5));
    });
  });
}