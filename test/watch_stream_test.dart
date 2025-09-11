import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/time/app_time.dart';
import '../lib/data/dao/event_dao.dart';
import '../lib/data/repository/event_repository.dart';

/// Test suite for stream watching functionality and real-time updates
void main() {
  group('Stream Watching Tests', () {
    setUpAll(() async {
      await AppTime.init();
    });

    test('watchBetweenUtc emits initial data immediately', () async {
      // Test case: Stream should emit initial data as soon as subscribed
      final dao = EventDao();
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      
      // Add some initial data
      final initialEvent = EventModel(
        id: 'initial_test',
        source: 'test',
        uid: 'initial_uid',
        title: '초기 데이터',
        start: DateTime(2025, 9, 10, 12, 0).toUtc(),
      );
      
      await dao.upsertAll([initialEvent]);
      
      // Subscribe to stream and expect immediate emission
      final stream = dao.watchBetweenUtc(startMs, endMs);
      final firstEmission = await stream.first;
      
      expect(firstEmission.length, equals(1));
      expect(firstEmission.first['title'], equals('초기 데이터'));
    });

    test('upsertAll triggers stream emission with latest data', () async {
      // Test case: Stream should emit new data when upsertAll is called
      final dao = EventDao();
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      
      final stream = dao.watchBetweenUtc(startMs, endMs);
      final emissions = <List<Map<String, Object?>>>[];
      
      // Start listening to stream
      final subscription = stream.listen(emissions.add);
      
      // Wait for initial emission (empty)
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add an event - this should trigger a new emission
      final newEvent = EventModel(
        id: 'stream_test',
        source: 'test',
        uid: 'stream_uid',
        title: '스트림 테스트 이벤트',
        start: DateTime(2025, 9, 10, 14, 0).toUtc(),
      );
      
      await dao.upsertAll([newEvent]);
      
      // Wait for stream emission
      await Future.delayed(const Duration(milliseconds: 100));
      
      await subscription.cancel();
      
      // Should have at least 2 emissions: initial (empty) + after upsert
      expect(emissions.length, greaterThanOrEqualTo(2));
      
      // Last emission should contain the new event
      final lastEmission = emissions.last;
      expect(lastEmission.length, equals(1));
      expect(lastEmission.first['title'], equals('스트림 테스트 이벤트'));
    });

    test('multiple upserts trigger multiple stream emissions', () async {
      // Test case: Each upsert should trigger a new stream emission
      final dao = EventDao();
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      
      final stream = dao.watchBetweenUtc(startMs, endMs);
      final emissions = <List<Map<String, Object?>>>[];
      
      final subscription = stream.listen(emissions.add);
      
      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add multiple events with delays
      final events = [
        EventModel(
          id: 'multi_1',
          source: 'test',
          uid: 'multi_uid_1',
          title: '멀티 이벤트 1',
          start: DateTime(2025, 9, 10, 9, 0).toUtc(),
        ),
        EventModel(
          id: 'multi_2',
          source: 'test',
          uid: 'multi_uid_2',
          title: '멀티 이벤트 2',
          start: DateTime(2025, 9, 10, 10, 0).toUtc(),
        ),
        EventModel(
          id: 'multi_3',
          source: 'test',
          uid: 'multi_uid_3',
          title: '멀티 이벤트 3',
          start: DateTime(2025, 9, 10, 11, 0).toUtc(),
        ),
      ];
      
      for (final event in events) {
        await dao.upsertAll([event]);
        await Future.delayed(const Duration(milliseconds: 50)); // Allow stream to emit
      }
      
      await subscription.cancel();
      
      // Should have multiple emissions (initial + 3 upserts = at least 4)
      expect(emissions.length, greaterThanOrEqualTo(4));
      
      // Final emission should have all 3 events
      final finalEmission = emissions.last;
      expect(finalEmission.length, equals(3));
    });

    test('stream updates reflect event modifications', () async {
      // Test case: Updating an existing event should be reflected in stream
      final dao = EventDao();
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      
      // Create initial event
      final originalEvent = EventModel(
        id: 'update_test',
        source: 'test',
        uid: 'update_uid',
        title: '원본 제목',
        start: DateTime(2025, 9, 10, 15, 0).toUtc(),
      );
      
      await dao.upsertAll([originalEvent]);
      
      final stream = dao.watchBetweenUtc(startMs, endMs);
      final emissions = <List<Map<String, Object?>>>[];
      final subscription = stream.listen(emissions.add);
      
      // Wait for initial emission with original data
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Update the event
      final updatedEvent = EventModel(
        id: originalEvent.id,
        source: originalEvent.source,
        uid: originalEvent.uid,
        title: '수정된 제목', // Changed title
        start: originalEvent.start,
        location: '추가된 위치', // Added location
      );
      
      await dao.upsertAll([updatedEvent]);
      
      // Wait for updated emission
      await Future.delayed(const Duration(milliseconds: 100));
      
      await subscription.cancel();
      
      // Should have at least 2 emissions
      expect(emissions.length, greaterThanOrEqualTo(2));
      
      // Last emission should show updated data
      final lastEmission = emissions.last;
      expect(lastEmission.length, equals(1));
      expect(lastEmission.first['title'], equals('수정된 제목'));
    });

    test('repository streams work with timezone conversion', () async {
      // Test case: Repository streams should handle timezone conversion correctly
      final dao = EventDao();
      final repository = EventRepository(dao);
      final testDate = DateTime(2025, 9, 10);
      
      final stream = repository.watchEventsForLocalDate(testDate);
      final emissions = <List<EventModel>>[];
      
      final subscription = stream.listen(emissions.add);
      
      // Wait for initial empty emission
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add event in local date range
      final localEvent = EventModel(
        id: 'repo_stream_test',
        source: 'test',
        uid: 'repo_stream_uid',
        title: '레포지토리 스트림 테스트',
        start: DateTime(2025, 9, 10, 16, 0).toUtc(), // 4 PM on test date
      );
      
      await dao.upsertAll([localEvent]);
      
      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));
      
      await subscription.cancel();
      
      // Should have emissions
      expect(emissions.length, greaterThanOrEqualTo(2));
      
      // Last emission should contain the event as EventModel
      final lastEmission = emissions.last;
      expect(lastEmission.length, equals(1));
      expect(lastEmission.first.title, equals('레포지토리 스트림 테스트'));
      expect(lastEmission.first.source, equals('test'));
    });

    test('today events stream updates in real-time', () async {
      // Test case: Today events stream should update when events are added for today
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final todayStream = repository.watchTodayEvents();
      final emissions = <List<EventModel>>[];
      
      final subscription = todayStream.listen(emissions.add);
      
      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add event for today
      final now = DateTime.now();
      final todayEvent = EventModel(
        id: 'today_stream_test',
        source: 'test',
        uid: 'today_stream_uid',
        title: '오늘 스트림 테스트',
        start: DateTime(now.year, now.month, now.day, 17, 0).toUtc(), // 5 PM today
      );
      
      await dao.upsertAll([todayEvent]);
      
      // Wait for emission
      await Future.delayed(const Duration(milliseconds: 100));
      
      await subscription.cancel();
      
      // Should have at least 2 emissions
      expect(emissions.length, greaterThanOrEqualTo(2));
      
      // Check if today's event appears in the stream
      final hasEvent = emissions.any((emission) => 
        emission.any((event) => event.title == '오늘 스트림 테스트'));
      expect(hasEvent, isTrue);
    });

    test('week events stream includes all week events', () async {
      // Test case: Week stream should update with events across the week
      final dao = EventDao();
      final repository = EventRepository(dao);
      
      final weekStart = DateTime(2025, 9, 8); // Monday
      final weekStream = repository.watchEventsForWeek(weekStart);
      final emissions = <List<EventModel>>[];
      
      final subscription = weekStream.listen(emissions.add);
      
      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add events on different days of the week
      final weekEvents = [
        EventModel(
          id: 'monday_event',
          source: 'test',
          uid: 'monday_uid',
          title: '월요일 이벤트',
          start: DateTime(2025, 9, 8, 10, 0).toUtc(), // Monday
        ),
        EventModel(
          id: 'friday_event',
          source: 'test',
          uid: 'friday_uid',
          title: '금요일 이벤트',
          start: DateTime(2025, 9, 12, 15, 0).toUtc(), // Friday
        ),
      ];
      
      await dao.upsertAll(weekEvents);
      
      // Wait for emission
      await Future.delayed(const Duration(milliseconds: 100));
      
      await subscription.cancel();
      
      // Should have emissions with both events
      expect(emissions.length, greaterThanOrEqualTo(2));
      
      final lastEmission = emissions.last;
      expect(lastEmission.length, equals(2));
      
      final titles = lastEmission.map((e) => e.title).toSet();
      expect(titles.contains('월요일 이벤트'), isTrue);
      expect(titles.contains('금요일 이벤트'), isTrue);
    });

    test('multiple concurrent stream subscriptions work independently', () async {
      // Test case: Multiple streams should work without interference
      final dao = EventDao();
      final date1 = DateTime(2025, 9, 10);
      final date2 = DateTime(2025, 9, 11);
      
      final (start1Ms, end1Ms) = dao.utcRangeOfLocalDay(date1);
      final (start2Ms, end2Ms) = dao.utcRangeOfLocalDay(date2);
      
      final stream1 = dao.watchBetweenUtc(start1Ms, end1Ms);
      final stream2 = dao.watchBetweenUtc(start2Ms, end2Ms);
      
      final emissions1 = <List<Map<String, Object?>>>[];
      final emissions2 = <List<Map<String, Object?>>>[];
      
      final sub1 = stream1.listen(emissions1.add);
      final sub2 = stream2.listen(emissions2.add);
      
      // Wait for initial emissions
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add event to date1
      final event1 = EventModel(
        id: 'concurrent_1',
        source: 'test',
        uid: 'concurrent_uid_1',
        title: '첫 번째 날 이벤트',
        start: DateTime(2025, 9, 10, 12, 0).toUtc(),
      );
      
      await dao.upsertAll([event1]);
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add event to date2
      final event2 = EventModel(
        id: 'concurrent_2',
        source: 'test',
        uid: 'concurrent_uid_2',
        title: '두 번째 날 이벤트',
        start: DateTime(2025, 9, 11, 12, 0).toUtc(),
      );
      
      await dao.upsertAll([event2]);
      await Future.delayed(const Duration(milliseconds: 50));
      
      await sub1.cancel();
      await sub2.cancel();
      
      // Both streams should have received updates
      expect(emissions1.length, greaterThanOrEqualTo(2));
      expect(emissions2.length, greaterThanOrEqualTo(2));
      
      // Stream1 should have event1 in final emission
      final final1 = emissions1.last;
      expect(final1.length, equals(1));
      expect(final1.first['title'], equals('첫 번째 날 이벤트'));
      
      // Stream2 should have event2 in final emission  
      final final2 = emissions2.last;
      expect(final2.length, equals(1));
      expect(final2.first['title'], equals('두 번째 날 이벤트'));
    });

    test('stream subscription cleanup works properly', () async {
      // Test case: Cancelled streams should not continue receiving updates
      final dao = EventDao();
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      
      final stream = dao.watchBetweenUtc(startMs, endMs);
      final emissions = <List<Map<String, Object?>>>[];
      
      final subscription = stream.listen(emissions.add);
      
      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Add an event
      final event1 = EventModel(
        id: 'cleanup_test_1',
        source: 'test',
        uid: 'cleanup_uid_1',
        title: '정리 테스트 1',
        start: DateTime(2025, 9, 10, 13, 0).toUtc(),
      );
      
      await dao.upsertAll([event1]);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final emissionsBeforeCancel = emissions.length;
      
      // Cancel subscription
      await subscription.cancel();
      
      // Add another event - this should not trigger new emissions
      final event2 = EventModel(
        id: 'cleanup_test_2',
        source: 'test',
        uid: 'cleanup_uid_2',
        title: '정리 테스트 2',
        start: DateTime(2025, 9, 10, 14, 0).toUtc(),
      );
      
      await dao.upsertAll([event2]);
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Emissions count should not have increased after cancellation
      expect(emissions.length, equals(emissionsBeforeCancel));
    });
  });
}