import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../lib/core/time/kst.dart';
import '../lib/db/db_signal.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/features/events/data/events_repository.dart';
import '../lib/features/events/data/events_dao.dart';
import '../lib/features/events/data/event_overrides_dao.dart';
import '../lib/features/events/data/events_api.dart';

/// Mock EventsDao for testing
class MockEventsDao implements EventsDao {
  final Map<String, EventEntity> _events = {};

  @override
  Future<EventEntity?> getById(String id) async {
    return _events[id];
  }

  @override
  Future<void> upsert(EventEntity item) async {
    _events[item.id] = item;
    DbSignal.instance.pingEvents(); // Trigger stream update
  }

  @override
  Future<void> upsertAll(List<EventEntity> items) async {
    for (final item in items) {
      _events[item.id] = item;
    }
    DbSignal.instance.pingEvents();
  }

  // Other required methods (not used in this test)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock EventsApi for testing
class MockEventsApi implements EventsApi {
  @override
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  }) async {
    return {'events': [], 'overrides': []};
  }
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko_KR', null);
    KST.init();
  });

  group('Real-time Detail Screen Tests', () {
    late EventsRepository repository;
    late MockEventsDao mockDao;

    setUp(() {
      mockDao = MockEventsDao();
      repository = EventsRepository(
        dao: mockDao,
        overridesDao: EventOverridesDao(),
        api: MockEventsApi(),
      );
    });

    test('should stream initial event data immediately', () async {
      // Create initial event
      final event = EventEntity(
        id: 'test-event',
        title: 'Original Title',
        description: 'Original description',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      // Store in mock DAO
      await mockDao.upsert(event);

      // Watch the stream
      final stream = repository.watchById('test-event');

      // First emission should be the initial data
      final firstEvent = await stream.first;
      expect(firstEvent, isNotNull);
      expect(firstEvent!.title, equals('Original Title'));
      expect(firstEvent.description, equals('Original description'));
    });

    test('should emit updates when event is modified', () async {
      // Create initial event
      final initialEvent = EventEntity(
        id: 'test-update',
        title: 'Initial Title',
        description: 'Initial description',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      await mockDao.upsert(initialEvent);

      // Watch the stream
      final streamController = StreamController<EventEntity?>();
      final subscription = repository.watchById('test-update').listen((event) {
        streamController.add(event);
      });

      // Collect stream emissions
      final emissions = <EventEntity?>[];
      final streamSubscription = streamController.stream.listen((event) {
        emissions.add(event);
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emissions.length, equals(1));
      expect(emissions[0]!.title, equals('Initial Title'));

      // Update the event
      final updatedEvent = initialEvent.copyWith(
        title: 'Updated Title',
        description: 'Updated description',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await mockDao.upsert(updatedEvent);

      // Wait for stream update
      await Future.delayed(const Duration(milliseconds: 10));

      // Should have received the update
      expect(emissions.length, equals(2));
      expect(emissions[1]!.title, equals('Updated Title'));
      expect(emissions[1]!.description, equals('Updated description'));

      // Cleanup
      await subscription.cancel();
      await streamSubscription.cancel();
      streamController.close();
    });

    test('should handle multiple rapid updates correctly', () async {
      // Create initial event
      final event = EventEntity(
        id: 'test-rapid',
        title: 'Version 0',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      await mockDao.upsert(event);

      // Watch the stream
      final streamController = StreamController<EventEntity?>();
      final subscription = repository.watchById('test-rapid').listen((event) {
        streamController.add(event);
      });

      final emissions = <EventEntity?>[];
      final streamSubscription = streamController.stream.listen((event) {
        emissions.add(event);
      });

      // Wait for initial
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emissions.length, equals(1));

      // Perform multiple rapid updates
      for (int i = 1; i <= 5; i++) {
        final updated = event.copyWith(
          title: 'Version $i',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        await mockDao.upsert(updated);
      }

      // Wait for all updates to propagate
      await Future.delayed(const Duration(milliseconds: 50));

      // Should have received all updates (initial + 5 updates = 6 total)
      expect(emissions.length, equals(6));
      expect(emissions.last!.title, equals('Version 5'));

      // Cleanup
      await subscription.cancel();
      await streamSubscription.cancel();
      streamController.close();
    });

    test('should handle event deletion gracefully', () async {
      // Create event
      final event = EventEntity(
        id: 'test-delete',
        title: 'To Be Deleted',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      await mockDao.upsert(event);

      // Watch the stream
      final streamController = StreamController<EventEntity?>();
      final subscription = repository.watchById('test-delete').listen((event) {
        streamController.add(event);
      });

      final emissions = <EventEntity?>[];
      final streamSubscription = streamController.stream.listen((event) {
        emissions.add(event);
      });

      // Wait for initial
      await Future.delayed(const Duration(milliseconds: 10));
      expect(emissions.length, equals(1));
      expect(emissions[0], isNotNull);

      // Simulate deletion by removing from mock DAO
      mockDao._events.remove('test-delete');
      DbSignal.instance.pingEvents();

      // Wait for update
      await Future.delayed(const Duration(milliseconds: 10));

      // Should receive null for deleted event
      expect(emissions.length, equals(2));
      expect(emissions[1], isNull);

      // Cleanup
      await subscription.cancel();
      await streamSubscription.cancel();
      streamController.close();
    });
  });
}