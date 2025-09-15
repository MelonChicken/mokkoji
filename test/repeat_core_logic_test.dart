import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/core/time/kst.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/domain/repeat/repeat_engine.dart';

void main() {
  group('Repeat Core Logic Tests', () {
    late Database testDb;

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
          // Create events table (simplified for testing)
          await db.execute('''
            CREATE TABLE events (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              start_dt TEXT NOT NULL,
              end_dt TEXT,
              rrule TEXT,
              updated_at TEXT NOT NULL,
              all_day INTEGER NOT NULL DEFAULT 0,
              duration_min INTEGER NOT NULL DEFAULT 60,
              source_platform TEXT NOT NULL DEFAULT 'internal'
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
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE UNIQUE INDEX idx_event_instances_unique
            ON event_instances (master_event_id, start_utc, end_utc)
          ''');
        },
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('should generate correct occurrences for daily rule', () async {
      // Create a simple daily event
      final masterId = 'test-daily';
      final masterStartUtc = '2025-09-14T09:00:00.000Z'; // KST 18:00
      final masterEndUtc = '2025-09-14T10:00:00.000Z';   // KST 19:00
      final rrule = 'FREQ=DAILY;COUNT=3';

      // Insert master event
      await testDb.insert('events', {
        'id': masterId,
        'title': 'Daily Test',
        'start_dt': masterStartUtc,
        'end_dt': masterEndUtc,
        'rrule': rrule,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Load the master event
      final masterRows = await testDb.query('events', where: 'id = ?', whereArgs: [masterId]);
      expect(masterRows.length, equals(1));
      final master = EventEntity.fromMap(masterRows.first);

      // Generate occurrences using RepeatEngine
      final startRange = DateTime(2025, 9, 14); // KST start of range
      final endRange = DateTime(2025, 9, 20);   // KST end of range

      final occurrences = RepeatEngine.generate(master, startRange, endRange);

      expect(occurrences.length, equals(3));

      // Verify the occurrences are on consecutive days
      expect(occurrences[0].startKst.day, equals(14));
      expect(occurrences[1].startKst.day, equals(15));
      expect(occurrences[2].startKst.day, equals(16));

      // All should be at the same time (18:00 KST)
      for (final occ in occurrences) {
        expect(occ.startKst.hour, equals(18));
        expect(occ.startKst.minute, equals(0));
        expect(occ.endKst.hour, equals(19));
        expect(occ.endKst.minute, equals(0));
      }
    });

    test('should generate correct occurrences for weekly rule', () async {
      final masterId = 'test-weekly';
      final masterStartUtc = '2025-09-15T09:00:00.000Z'; // Monday KST 18:00
      final masterEndUtc = '2025-09-15T10:00:00.000Z';   // Monday KST 19:00
      final rrule = 'FREQ=WEEKLY;COUNT=2';

      await testDb.insert('events', {
        'id': masterId,
        'title': 'Weekly Test',
        'start_dt': masterStartUtc,
        'end_dt': masterEndUtc,
        'rrule': rrule,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final masterRows = await testDb.query('events', where: 'id = ?', whereArgs: [masterId]);
      final master = EventEntity.fromMap(masterRows.first);

      // Generate occurrences
      final startRange = DateTime(2025, 9, 14);
      final endRange = DateTime(2025, 10, 1);

      final occurrences = RepeatEngine.generate(master, startRange, endRange);

      expect(occurrences.length, equals(2));

      // Should be on consecutive Mondays
      expect(occurrences[0].startKst.day, equals(15)); // Sep 15 (Monday)
      expect(occurrences[1].startKst.day, equals(22)); // Sep 22 (Monday)

      // Both should be Mondays
      expect(occurrences[0].startKst.weekday, equals(DateTime.monday));
      expect(occurrences[1].startKst.weekday, equals(DateTime.monday));
    });

    test('should handle instance materialization workflow', () async {
      final masterId = 'test-materialize';
      final masterStartUtc = '2025-09-14T09:00:00.000Z';
      final masterEndUtc = '2025-09-14T10:00:00.000Z';
      final rrule = 'FREQ=DAILY;COUNT=3';

      // Insert master event
      await testDb.insert('events', {
        'id': masterId,
        'title': 'Materialize Test',
        'start_dt': masterStartUtc,
        'end_dt': masterEndUtc,
        'rrule': rrule,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Load master and generate occurrences
      final masterRows = await testDb.query('events', where: 'id = ?', whereArgs: [masterId]);
      final master = EventEntity.fromMap(masterRows.first);

      final startRange = DateTime(2025, 9, 14);
      final endRange = DateTime(2025, 9, 20);
      final occurrences = RepeatEngine.generate(master, startRange, endRange);

      // Materialize instances manually (simulating RepeatMaterializer logic)
      for (final occ in occurrences) {
        // Convert KST occurrence back to UTC for storage
        final startUtc = KST.toUtcIso(occ.startKst);
        final endUtc = KST.toUtcIso(occ.endKst);

        await testDb.insert('event_instances', {
          'master_event_id': masterId,
          'start_utc': startUtc,
          'end_utc': endUtc,
          'is_detached': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // Verify instances were created correctly
      final instances = await testDb.query(
        'event_instances',
        where: 'master_event_id = ?',
        whereArgs: [masterId],
        orderBy: 'start_utc ASC',
      );

      expect(instances.length, equals(3));

      // Verify UTC times are stored correctly
      expect(instances[0]['start_utc'], equals('2025-09-14T09:00:00.000Z'));
      expect(instances[1]['start_utc'], equals('2025-09-15T09:00:00.000Z'));
      expect(instances[2]['start_utc'], equals('2025-09-16T09:00:00.000Z'));
    });

    test('should handle no recurrence rule correctly', () async {
      final masterId = 'test-no-recurrence';
      final masterStartUtc = '2025-09-14T09:00:00.000Z';
      final masterEndUtc = '2025-09-14T10:00:00.000Z';

      // Insert master event WITHOUT rrule
      await testDb.insert('events', {
        'id': masterId,
        'title': 'No Recurrence Test',
        'start_dt': masterStartUtc,
        'end_dt': masterEndUtc,
        'rrule': null, // No recurrence rule
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final masterRows = await testDb.query('events', where: 'id = ?', whereArgs: [masterId]);
      final master = EventEntity.fromMap(masterRows.first);

      final startRange = DateTime(2025, 9, 14);
      final endRange = DateTime(2025, 9, 20);
      final occurrences = RepeatEngine.generate(master, startRange, endRange);

      // Should generate no occurrences for non-recurring events
      expect(occurrences.length, equals(0));
    });
  });
}