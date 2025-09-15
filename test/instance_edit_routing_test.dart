import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/core/time/kst.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/features/events/data/events_repository.dart';
import '../lib/features/events/data/events_dao.dart';
import '../lib/features/events/data/event_overrides_dao.dart';
import '../lib/features/events/data/event_override_entity.dart';
import '../lib/features/events/data/events_api.dart';

// Test API for instance routing
class TestEventsApi implements EventsApi {
  @override
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  }) async {
    return {'events': [], 'overrides': []};
  }
}

void main() {
  group('Instance Edit Routing Test', () {
    late Database testDb;
    late EventsRepository repository;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      KST.init();
    });

    setUp(() async {
      // Create in-memory test database with full schema
      testDb = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          // Events table
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

          // Event instances table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS event_instances (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              master_event_id TEXT NOT NULL,
              start_utc TEXT NOT NULL,
              end_utc TEXT NOT NULL,
              is_detached INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL
            )
          ''');

          // Event overrides table (for completeness)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS event_overrides (
              id TEXT PRIMARY KEY,
              ical_uid TEXT NOT NULL,
              recurrence_id TEXT NOT NULL,
              start_dt TEXT,
              end_dt TEXT,
              all_day INTEGER,
              title TEXT,
              description TEXT,
              location TEXT,
              status TEXT,
              attendees_json TEXT,
              last_modified TEXT NOT NULL
            )
          ''');
        },
      );

      // Create test DAOs and repository
      final eventsDao = TestEventsDao(testDb);
      final overridesDao = TestEventOverridesDao(testDb);
      repository = EventsRepository(
        dao: eventsDao,
        overridesDao: overridesDao,
        api: TestEventsApi(),
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test('getDisplayEventById should return master ID for instances', () async {
      // Create a master event
      final masterId = 'master-123';
      final master = EventEntity(
        id: masterId,
        title: 'Master Event',
        description: 'A recurring event',
        startDt: '2025-09-15T00:00:00.000Z',
        endDt: '2025-09-15T01:00:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        rrule: 'FREQ=DAILY;COUNT=3',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());

      // Create an instance
      final instanceId = await testDb.insert('event_instances', {
        'master_event_id': masterId,
        'start_utc': '2025-09-15T00:00:00.000Z',
        'end_utc': '2025-09-15T01:00:00.000Z',
        'is_detached': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Test getting display event by instance ID
      final instanceDisplayId = 'instance_$instanceId';
      final displayEvent = await repository.getDisplayEventById(instanceDisplayId);

      expect(displayEvent, isNotNull);
      expect(displayEvent!.isInstance, true);
      expect(displayEvent.parentId, equals(masterId));
      expect(displayEvent.title, equals('Master Event'));

      print('✅ Instance $instanceDisplayId correctly routes to master $masterId');
    });

    test('getDisplayEventById should return master directly for master IDs', () async {
      // Create a non-recurring master event
      final masterId = 'master-456';
      final master = EventEntity(
        id: masterId,
        title: 'Single Event',
        description: 'A non-recurring event',
        startDt: '2025-09-15T00:00:00.000Z',
        endDt: '2025-09-15T01:00:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        rrule: null, // No recurrence
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await testDb.insert('events', master.toMap());

      // Test getting display event by master ID
      final displayEvent = await repository.getDisplayEventById(masterId);

      expect(displayEvent, isNotNull);
      expect(displayEvent!.isInstance, false);
      expect(displayEvent.parentId, isNull);
      expect(displayEvent.title, equals('Single Event'));

      print('✅ Master $masterId correctly returns master display event');
    });

    test('instance edit should route to correct master ID', () async {
      // This test validates the logic that would be used in DetailEventSheet._showEditSheet
      final testEventId = 'instance_123';

      // Mock the repository call that would happen in _showEditSheet
      if (testEventId.startsWith('instance_')) {
        // Create a mock instance with known master
        final masterId = 'master-789';
        final master = EventEntity(
          id: masterId,
          title: 'Recurring Meeting',
          startDt: '2025-09-15T00:00:00.000Z',
          endDt: '2025-09-15T01:00:00.000Z',
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        await testDb.insert('events', master.toMap());

        final instanceDbId = int.parse(testEventId.substring(9)); // Extract "123"
        await testDb.insert('event_instances', {
          'id': instanceDbId,
          'master_event_id': masterId,
          'start_utc': '2025-09-15T00:00:00.000Z',
          'end_utc': '2025-09-15T01:00:00.000Z',
          'is_detached': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        // Test the routing logic
        final displayEvent = await repository.getDisplayEventById(testEventId);
        final editEventId = displayEvent?.parentId ?? testEventId;

        expect(editEventId, equals(masterId));
        print('✅ Instance edit $testEventId correctly routes to master $editEventId');
      }
    });
  });
}

// Test DAOs (simplified from smoke test)
class TestEventsDao extends EventsDao {
  final Database _testDb;
  TestEventsDao(this._testDb);

  @override
  Future<Database> get _db async => _testDb;

  @override
  Future<EventEntity?> getById(String id) async {
    final rows = await _testDb.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : EventEntity.fromMap(rows.first);
  }

  @override
  Future<List<EventEntity>> range(String startIso, String endIso, {List<String>? platforms}) async {
    final rows = await _testDb.query(
      'events',
      where: 'deleted_at IS NULL AND start_dt >= ? AND start_dt < ?',
      whereArgs: [startIso, endIso],
      orderBy: 'start_dt ASC',
    );
    return rows.map(EventEntity.fromMap).toList();
  }
}

class TestEventOverridesDao extends EventOverridesDao {
  final Database _testDb;
  TestEventOverridesDao(this._testDb);

  @override
  Future<Database> get _db async => _testDb;

  @override
  Future<List<EventOverrideEntity>> forParentUid(String icalUid, {String? startIso, String? endIso}) async => [];

  @override
  Future<void> upsertAll(List<EventOverrideEntity> items) async => {};

  @override
  Future<int> countAll() async => 0;
}