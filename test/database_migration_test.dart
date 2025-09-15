import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/date_symbol_data_local.dart';
import '../lib/core/time/kst.dart';
import '../lib/core/time/app_time.dart';
import '../lib/data/migrations/002_iso_to_utc_migration.dart';

void main() {
  group('Database Migration Tests', () {
    late Database database;

    setUpAll(() async {
      // Initialize FFI for testing
      sqlfiteFfiInit();
      databaseFactory = databaseFactoryFfi;
      tz_data.initializeTimeZones();
      await initializeDateFormatting('ko_KR', null);
      KST.init();
      await AppTime.init();
    });

    setUp(() async {
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create v1 schema
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
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
        },
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('migration handles empty database gracefully', () async {
      expect(() => IsoToUtcMigration.run(database), returnsNormally);
    });

    test('migration fixes various ISO formats', () async {
      // Insert test data with problematic ISO formats
      await database.insert('events', {
        'id': 'test1',
        'title': 'UTC Event',
        'start_dt': '2025-09-10T02:00:00.000Z',  // Already UTC
        'end_dt': '2025-09-10T03:00:00.000Z',
        'all_day': 0,
        'source_platform': 'test',
        'updated_at': '2025-09-10T02:00:00.000Z',
      });

      await database.insert('events', {
        'id': 'test2',
        'title': 'KST Offset Event',
        'start_dt': '2025-09-10T11:00:00.000+09:00',  // KST with offset
        'end_dt': '2025-09-10T12:00:00.000+09:00',
        'all_day': 0,
        'source_platform': 'test',
        'updated_at': '2025-09-10T02:00:00.000Z',
      });

      await database.insert('events', {
        'id': 'test3',
        'title': 'Naive ISO Event',
        'start_dt': '2025-09-10T11:00:00.000',  // No timezone info
        'end_dt': '2025-09-10T12:00:00.000',
        'all_day': 0,
        'source_platform': 'test',
        'updated_at': '2025-09-10T02:00:00.000Z',
      });

      // Run migration
      await IsoToUtcMigration.run(database);

      // Check results
      final results = await database.query('events', orderBy: 'id');

      expect(results.length, equals(3));

      // test1 should remain unchanged (already UTC)
      expect(results[0]['start_dt'], equals('2025-09-10T02:00:00.000Z'));
      expect(results[0]['end_dt'], equals('2025-09-10T03:00:00.000Z'));

      // test2 should be converted from KST offset to UTC
      expect(results[1]['start_dt'], equals('2025-09-10T02:00:00.000Z'));
      expect(results[1]['end_dt'], equals('2025-09-10T03:00:00.000Z'));

      // test3 should be converted from naive to UTC (interpreted as KST)
      expect(results[2]['start_dt'], equals('2025-09-10T02:00:00.000Z'));
      expect(results[2]['end_dt'], equals('2025-09-10T03:00:00.000Z'));
    });

    test('migration handles malformed timestamps gracefully', () async {
      // Insert event with malformed timestamp
      await database.insert('events', {
        'id': 'bad1',
        'title': 'Bad Timestamp Event',
        'start_dt': 'not-a-date',
        'end_dt': '2025-13-40T99:99:99.999Z',  // Invalid date
        'all_day': 0,
        'source_platform': 'test',
        'updated_at': '2025-09-10T02:00:00.000Z',
      });

      // Migration should not crash
      expect(() => IsoToUtcMigration.run(database), returnsNormally);

      // Event should still exist but timestamps unchanged
      final results = await database.query('events', where: 'id = ?', whereArgs: ['bad1']);
      expect(results.length, equals(1));
      expect(results[0]['start_dt'], equals('not-a-date')); // Left unchanged
    });

    test('migration is idempotent', () async {
      // Insert test data
      await database.insert('events', {
        'id': 'idempotent1',
        'title': 'Idempotent Test',
        'start_dt': '2025-09-10T11:00:00.000+09:00',
        'end_dt': '2025-09-10T12:00:00.000+09:00',
        'all_day': 0,
        'source_platform': 'test',
        'updated_at': '2025-09-10T02:00:00.000Z',
      });

      // Run migration twice
      await IsoToUtcMigration.run(database);
      await IsoToUtcMigration.run(database);

      // Result should be the same
      final results = await database.query('events', where: 'id = ?', whereArgs: ['idempotent1']);
      expect(results.length, equals(1));
      expect(results[0]['start_dt'], equals('2025-09-10T02:00:00.000Z'));
      expect(results[0]['end_dt'], equals('2025-09-10T03:00:00.000Z'));
    });

    test('migration handles missing columns gracefully', () async {
      // Create table without datetime columns
      await database.execute('''
        CREATE TABLE test_table (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL
        )
      ''');

      await database.insert('test_table', {
        'id': 'test1',
        'title': 'Test Event',
      });

      // Migration should not crash when checking this table
      expect(() => IsoToUtcMigration.run(database), returnsNormally);
    });
  });
}