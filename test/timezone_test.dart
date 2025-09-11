import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import '../lib/core/time/app_time.dart';
import '../lib/data/dao/event_dao.dart';
import '../lib/data/repository/event_repository.dart';

/// Test suite for timezone conversion and date boundary handling
void main() {
  group('Timezone Conversion Tests', () {
    setUpAll(() async {
      // Initialize timezone data for tests
      await AppTime.init();
    });

    test('Local today 23:30 event is included in same day query', () async {
      // Test case: Local 23:30 event should be found when querying for that day
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      // Create event for local today at 23:30
      final localToday = DateTime(2025, 9, 10); // Test date
      final localEvent = EventModel(
        id: 'test_late_event',
        source: 'test',
        uid: 'late_event_uid',
        title: '늦은 저녁 회의',
        start: DateTime(2025, 9, 10, 23, 30).toUtc(),
        end: DateTime(2025, 9, 11, 0, 30).toUtc(), // Cross midnight
      );

      // Store the event
      await dao.upsertAll([localEvent]);

      // Query for events on the same local day
      final eventsForDay = await repository.getEventsForLocalDate(localToday);

      // Verify the event is found
      expect(eventsForDay.length, equals(1));
      expect(eventsForDay.first.title, equals('늦은 저녁 회의'));
      expect(eventsForDay.first.id, equals('test_late_event'));
    });

    test('Local tomorrow 00:10 event is included in tomorrow query', () async {
      // Test case: Event at 00:10 should be found when querying for tomorrow
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final localTomorrow = DateTime(2025, 9, 11); // Next day
      final localEvent = EventModel(
        id: 'test_early_event',
        source: 'test', 
        uid: 'early_event_uid',
        title: '새벽 회의',
        start: DateTime(2025, 9, 11, 0, 10).toUtc(),
        end: DateTime(2025, 9, 11, 1, 10).toUtc(),
      );

      // Store the event
      await dao.upsertAll([localEvent]);

      // Query for events on tomorrow
      final eventsForDay = await repository.getEventsForLocalDate(localTomorrow);

      // Verify the event is found
      expect(eventsForDay.length, equals(1));
      expect(eventsForDay.first.title, equals('새벽 회의'));
      expect(eventsForDay.first.id, equals('test_early_event'));
    });

    test('Cross-day event spanning midnight is handled correctly', () async {
      // Test case: Event starting before midnight and ending after midnight
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final eventDay = DateTime(2025, 9, 10);
      final crossDayEvent = EventModel(
        id: 'test_cross_day',
        source: 'test',
        uid: 'cross_day_uid',
        title: '자정 넘김 이벤트',
        start: DateTime(2025, 9, 10, 23, 30).toUtc(),
        end: DateTime(2025, 9, 11, 1, 30).toUtc(), // 2 hours duration
      );

      await dao.upsertAll([crossDayEvent]);

      // Event should appear in the start day query
      final eventsStartDay = await repository.getEventsForLocalDate(eventDay);
      expect(eventsStartDay.length, equals(1));
      expect(eventsStartDay.first.title, equals('자정 넘김 이벤트'));

      // Event should NOT appear in the next day query (starts on previous day)
      final nextDay = DateTime(2025, 9, 11);
      final eventsNextDay = await repository.getEventsForLocalDate(nextDay);
      expect(eventsNextDay.length, equals(0));
    });

    test('UTC range conversion preserves local day boundaries', () {
      // Test the core UTC conversion logic
      final dao = EventDao();
      
      // Test local date
      final localDate = DateTime(2025, 9, 10); // September 10, 2025
      
      // Get UTC range for this local date
      final (startUtcMs, endUtcMs) = dao.utcRangeOfLocalDay(localDate);
      
      // Convert back to DateTime for verification
      final startUtc = DateTime.fromMillisecondsSinceEpoch(startUtcMs, isUtc: true);
      final endUtc = DateTime.fromMillisecondsSinceEpoch(endUtcMs, isUtc: true);
      
      // Verify the range covers exactly 24 hours
      final duration = endUtc.difference(startUtc);
      expect(duration.inHours, equals(24));
      
      // Verify start is midnight of the local date in UTC
      final localStart = DateTime(2025, 9, 10, 0, 0, 0);
      final expectedStartUtc = localStart.toUtc();
      expect(startUtc.year, equals(expectedStartUtc.year));
      expect(startUtc.month, equals(expectedStartUtc.month));
      expect(startUtc.day, equals(expectedStartUtc.day));
      expect(startUtc.hour, equals(expectedStartUtc.hour));
    });

    test('Multiple events on same day are all retrieved', () async {
      // Test that multiple events on the same local day are all found
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final testDate = DateTime(2025, 9, 10);
      final events = [
        EventModel(
          id: 'morning_event',
          source: 'test',
          uid: 'morning_uid',
          title: '오전 회의',
          start: DateTime(2025, 9, 10, 9, 0).toUtc(),
          end: DateTime(2025, 9, 10, 10, 0).toUtc(),
        ),
        EventModel(
          id: 'afternoon_event',
          source: 'test',
          uid: 'afternoon_uid',
          title: '오후 회의',
          start: DateTime(2025, 9, 10, 14, 0).toUtc(),
          end: DateTime(2025, 9, 10, 15, 0).toUtc(),
        ),
        EventModel(
          id: 'evening_event',
          source: 'test',
          uid: 'evening_uid',
          title: '저녁 회의',
          start: DateTime(2025, 9, 10, 20, 0).toUtc(),
          end: DateTime(2025, 9, 10, 21, 0).toUtc(),
        ),
      ];

      await dao.upsertAll(events);

      final retrievedEvents = await repository.getEventsForLocalDate(testDate);
      
      expect(retrievedEvents.length, equals(3));
      
      // Verify all events are present
      final titles = retrievedEvents.map((e) => e.title).toSet();
      expect(titles.contains('오전 회의'), isTrue);
      expect(titles.contains('오후 회의'), isTrue);
      expect(titles.contains('저녁 회의'), isTrue);
    });

    test('Events from different days do not interfere', () async {
      // Test that events from different days are properly separated
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final events = [
        EventModel(
          id: 'day1_event',
          source: 'test',
          uid: 'day1_uid',
          title: '1일차 이벤트',
          start: DateTime(2025, 9, 10, 12, 0).toUtc(),
          end: DateTime(2025, 9, 10, 13, 0).toUtc(),
        ),
        EventModel(
          id: 'day2_event',
          source: 'test',
          uid: 'day2_uid',
          title: '2일차 이벤트',
          start: DateTime(2025, 9, 11, 12, 0).toUtc(),
          end: DateTime(2025, 9, 11, 13, 0).toUtc(),
        ),
        EventModel(
          id: 'day3_event',
          source: 'test',
          uid: 'day3_uid',
          title: '3일차 이벤트',
          start: DateTime(2025, 9, 12, 12, 0).toUtc(),
          end: DateTime(2025, 9, 12, 13, 0).toUtc(),
        ),
      ];

      await dao.upsertAll(events);

      // Query each day separately
      final day1Events = await repository.getEventsForLocalDate(DateTime(2025, 9, 10));
      final day2Events = await repository.getEventsForLocalDate(DateTime(2025, 9, 11));
      final day3Events = await repository.getEventsForLocalDate(DateTime(2025, 9, 12));

      // Each day should have exactly one event
      expect(day1Events.length, equals(1));
      expect(day2Events.length, equals(1));
      expect(day3Events.length, equals(1));

      // Verify correct events are returned for each day
      expect(day1Events.first.title, equals('1일차 이벤트'));
      expect(day2Events.first.title, equals('2일차 이벤트'));
      expect(day3Events.first.title, equals('3일차 이벤트'));
    });

    test('All-day events are handled correctly across timezone boundaries', () async {
      // Test all-day events that span across timezone boundaries
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final allDayEvent = EventModel(
        id: 'all_day_event',
        source: 'test',
        uid: 'all_day_uid',
        title: '종일 이벤트',
        start: DateTime(2025, 9, 10, 0, 0).toUtc(), // Start of day UTC
        end: DateTime(2025, 9, 11, 0, 0).toUtc(),   // End of day UTC
        allDay: true,
      );

      await dao.upsertAll([allDayEvent]);

      final eventsForDay = await repository.getEventsForLocalDate(DateTime(2025, 9, 10));
      
      expect(eventsForDay.length, equals(1));
      expect(eventsForDay.first.title, equals('종일 이벤트'));
      expect(eventsForDay.first.allDay, isTrue);
    });
  });

  group('Date Range Tests', () {
    test('Week range includes all 7 days', () async {
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      // Create events for each day of the week
      final weekStart = DateTime(2025, 9, 8); // Monday
      final events = <EventModel>[];
      
      for (int i = 0; i < 7; i++) {
        final eventDate = weekStart.add(Duration(days: i));
        events.add(EventModel(
          id: 'week_event_$i',
          source: 'test',
          uid: 'week_uid_$i',
          title: '${i + 1}일차 이벤트',
          start: eventDate.copyWith(hour: 12).toUtc(),
          end: eventDate.copyWith(hour: 13).toUtc(),
        ));
      }
      
      await dao.upsertAll(events);
      
      final weekEvents = await repository.watchEventsForWeek(weekStart).first;
      
      expect(weekEvents.length, equals(7));
    });

    test('Month range includes all days in month', () async {
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      // Create events for first, middle, and last day of September 2025
      final events = [
        EventModel(
          id: 'month_start',
          source: 'test',
          uid: 'start_uid',
          title: '월초 이벤트',
          start: DateTime(2025, 9, 1, 12).toUtc(),
        ),
        EventModel(
          id: 'month_mid',
          source: 'test',
          uid: 'mid_uid',
          title: '월중 이벤트',
          start: DateTime(2025, 9, 15, 12).toUtc(),
        ),
        EventModel(
          id: 'month_end',
          source: 'test',
          uid: 'end_uid',
          title: '월말 이벤트',
          start: DateTime(2025, 9, 30, 12).toUtc(),
        ),
      ];
      
      await dao.upsertAll(events);
      
      final monthStart = DateTime(2025, 9, 1);
      final monthEvents = await repository.watchEventsForMonth(monthStart).first;
      
      expect(monthEvents.length, equals(3));
      
      final titles = monthEvents.map((e) => e.title).toSet();
      expect(titles.contains('월초 이벤트'), isTrue);
      expect(titles.contains('월중 이벤트'), isTrue);
      expect(titles.contains('월말 이벤트'), isTrue);
    });
  });
}