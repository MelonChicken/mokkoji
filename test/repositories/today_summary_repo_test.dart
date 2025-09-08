import 'package:flutter_test/flutter_test.dart';
import 'package:mokkoji/data/repositories/today_summary_repository.dart';
import 'package:mokkoji/features/events/data/events_dao.dart';
import 'package:mokkoji/features/events/data/event_entity.dart';
import 'package:mokkoji/data/models/today_summary_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockEventsDao extends EventsDao {
  final List<EventEntity> _events = [];

  void addEvent(EventEntity event) {
    _events.add(event);
  }

  void clearEvents() {
    _events.clear();
  }

  @override
  Future<List<EventEntity>> range(
    String startIso,
    String endIso, {
    List<String>? platforms,
  }) async {
    final start = DateTime.parse(startIso);
    final end = DateTime.parse(endIso);
    
    return _events.where((event) {
      final eventStart = DateTime.parse(event.startDt);
      return eventStart.isAfter(start.subtract(const Duration(microseconds: 1))) &&
             eventStart.isBefore(end) &&
             event.deletedAt == null;
    }).toList()..sort((a, b) => a.startDt.compareTo(b.startDt));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TodaySummaryRepository Tests', () {
    late MockEventsDao mockDao;
    late TodaySummaryRepository repository;

    setUp(() {
      mockDao = MockEventsDao();
      repository = TodaySummaryRepository(dao: mockDao);
    });

    tearDown(() {
      repository.dispose();
    });

    test('returns correct count for zero events', () async {
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 0);
      expect(data?.next, isNull);
      expect(data?.offline, false);
    });

    test('returns correct count for single event today', () async {
      final today = DateTime.now();
      final todayEvent = EventEntity(
        id: '1',
        title: 'Test Event',
        startDt: today.toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(todayEvent);
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 1);
    });

    test('returns correct count for multiple events today', () async {
      final today = DateTime.now();
      final events = [
        EventEntity(
          id: '1',
          title: 'Event 1',
          startDt: today.add(const Duration(hours: 1)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'google',
          updatedAt: DateTime.now().toIso8601String(),
        ),
        EventEntity(
          id: '2',
          title: 'Event 2',
          startDt: today.add(const Duration(hours: 2)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'kakao',
          updatedAt: DateTime.now().toIso8601String(),
        ),
        EventEntity(
          id: '3',
          title: 'Event 3',
          startDt: today.add(const Duration(hours: 3)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'naver',
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];
      
      for (final event in events) {
        mockDao.addEvent(event);
      }
      
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 3);
    });

    test('finds next upcoming event correctly', () async {
      final now = DateTime.now();
      final pastEvent = EventEntity(
        id: '1',
        title: 'Past Event',
        startDt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      final nextEvent = EventEntity(
        id: '2',
        title: 'Next Event',
        startDt: now.add(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'kakao',
        location: 'Test Location',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      final laterEvent = EventEntity(
        id: '3',
        title: 'Later Event',
        startDt: now.add(const Duration(hours: 2)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'naver',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(pastEvent);
      mockDao.addEvent(nextEvent);
      mockDao.addEvent(laterEvent);
      
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.next?.title, 'Next Event');
      expect(data?.next?.sourcePlatform, 'kakao');
      expect(data?.next?.location, 'Test Location');
    });

    test('handles events with RRULE recurrence', () async {
      final today = DateTime.now();
      final recurringEvent = EventEntity(
        id: '1',
        title: 'Weekly Meeting',
        startDt: today.add(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        rrule: 'FREQ=WEEKLY;BYDAY=MO',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(recurringEvent);
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 1);
      expect(data?.next?.title, 'Weekly Meeting');
    });

    test('excludes deleted events from count', () async {
      final today = DateTime.now();
      final activeEvent = EventEntity(
        id: '1',
        title: 'Active Event',
        startDt: today.add(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      final deletedEvent = EventEntity(
        id: '2',
        title: 'Deleted Event',
        startDt: today.add(const Duration(hours: 2)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
        deletedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(activeEvent);
      mockDao.addEvent(deletedEvent);
      
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 1);
      expect(data?.next?.title, 'Active Event');
    });

    test('excludes events from other days', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      
      final todayEvent = EventEntity(
        id: '1',
        title: 'Today Event',
        startDt: today.add(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      final yesterdayEvent = EventEntity(
        id: '2',
        title: 'Yesterday Event',
        startDt: yesterday.toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      final tomorrowEvent = EventEntity(
        id: '3',
        title: 'Tomorrow Event',
        startDt: tomorrow.toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(todayEvent);
      mockDao.addEvent(yesterdayEvent);
      mockDao.addEvent(tomorrowEvent);
      
      await repository.forceRefresh();
      
      final data = repository.currentData;
      expect(data?.count, 1);
      expect(data?.next?.title, 'Today Event');
    });

    test('stream emits updates when data changes', () async {
      final streamData = <TodaySummaryData>[];
      final subscription = repository.stream.listen(streamData.add);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      final today = DateTime.now();
      final event = EventEntity(
        id: '1',
        title: 'New Event',
        startDt: today.add(const Duration(hours: 1)).toIso8601String(),
        allDay: false,
        sourcePlatform: 'google',
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      mockDao.addEvent(event);
      await repository.forceRefresh();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(streamData.length, greaterThanOrEqualTo(2));
      expect(streamData.last.count, 1);
      
      subscription.cancel();
    });
  });
}