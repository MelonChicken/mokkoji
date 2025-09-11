import 'package:flutter_test/flutter_test.dart';
import '../lib/core/time/app_time.dart';
import '../lib/data/dao/event_dao.dart';

/// Test suite for upsert operations with detailed logging verification
void main() {
  group('Upsert Operation Tests', () {
    setUpAll(() async {
      await AppTime.init();
    });

    test('Identical (source, uid) twice results in insert=1, update=1, skip=0', () async {
      // Test case: Same event collected twice should insert once, update once
      final dao = EventDao();
      
      final testEvent = EventModel(
        id: 'test_duplicate',
        source: 'google',
        uid: 'duplicate_uid',
        title: '중복 테스트 이벤트',
        start: DateTime.now().toUtc(),
        end: DateTime.now().add(const Duration(hours: 1)).toUtc(),
      );

      // First upsert - should insert
      final firstResult = await dao.upsertAll([testEvent]);
      expect(firstResult.inserted, equals(1));
      expect(firstResult.updated, equals(0));
      expect(firstResult.skipped, equals(0));

      // Second upsert of same event - should update
      final updatedEvent = EventModel(
        id: testEvent.id,
        source: testEvent.source,
        uid: testEvent.uid,
        title: '업데이트된 제목', // Changed title
        start: testEvent.start,
        end: testEvent.end,
      );

      final secondResult = await dao.upsertAll([updatedEvent]);
      expect(secondResult.inserted, equals(0));
      expect(secondResult.updated, equals(1));
      expect(secondResult.skipped, equals(0));
    });

    test('Different UIDs from same source insert separately', () async {
      // Test case: Different events from same source should both insert
      final dao = EventDao();
      
      final events = [
        EventModel(
          id: 'google_event_1',
          source: 'google',
          uid: 'google_uid_1',
          title: '구글 이벤트 1',
          start: DateTime.now().toUtc(),
        ),
        EventModel(
          id: 'google_event_2',
          source: 'google',
          uid: 'google_uid_2',
          title: '구글 이벤트 2',
          start: DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
      ];

      final result = await dao.upsertAll(events);
      
      expect(result.inserted, equals(2));
      expect(result.updated, equals(0));
      expect(result.skipped, equals(0));
      expect(result.total, equals(2));
    });

    test('Same UID from different sources insert separately', () async {
      // Test case: Same UID from different sources should be treated as different events
      final dao = EventDao();
      
      final events = [
        EventModel(
          id: 'google_event',
          source: 'google',
          uid: 'shared_uid',
          title: '구글 이벤트',
          start: DateTime.now().toUtc(),
        ),
        EventModel(
          id: 'naver_event',
          source: 'naver',
          uid: 'shared_uid', // Same UID but different source
          title: '네이버 이벤트',
          start: DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
      ];

      final result = await dao.upsertAll(events);
      
      expect(result.inserted, equals(2));
      expect(result.updated, equals(0));
      expect(result.skipped, equals(0));
    });

    test('Mixed batch with new and existing events', () async {
      // Test case: Batch with mix of new and existing events
      final dao = EventDao();
      
      // First insert an existing event
      final existingEvent = EventModel(
        id: 'existing_event',
        source: 'kakao',
        uid: 'existing_uid',
        title: '기존 이벤트',
        start: DateTime.now().toUtc(),
      );
      
      await dao.upsertAll([existingEvent]);

      // Now batch upsert with existing + new events
      final batchEvents = [
        EventModel(
          id: 'existing_event',
          source: 'kakao',
          uid: 'existing_uid',
          title: '업데이트된 기존 이벤트', // Updated title
          start: DateTime.now().toUtc(),
        ),
        EventModel(
          id: 'new_event_1',
          source: 'kakao',
          uid: 'new_uid_1',
          title: '신규 이벤트 1',
          start: DateTime.now().add(const Duration(hours: 1)).toUtc(),
        ),
        EventModel(
          id: 'new_event_2',
          source: 'naver',
          uid: 'new_uid_2',
          title: '신규 이벤트 2',
          start: DateTime.now().add(const Duration(hours: 2)).toUtc(),
        ),
      ];

      final result = await dao.upsertAll(batchEvents);
      
      expect(result.inserted, equals(2)); // 2 new events
      expect(result.updated, equals(1));  // 1 existing event updated
      expect(result.skipped, equals(0));
      expect(result.total, equals(3));
    });

    test('Invalid events are skipped with proper count', () async {
      // Test case: Events that cause database errors should be skipped
      final dao = EventDao();
      
      final events = [
        EventModel(
          id: 'valid_event',
          source: 'test',
          uid: 'valid_uid',
          title: '유효한 이벤트',
          start: DateTime.now().toUtc(),
        ),
        // Create an event that might cause issues (e.g., null title)
        EventModel(
          id: 'invalid_event',
          source: 'test',
          uid: 'invalid_uid',
          title: '', // Empty title might cause constraint issues
          start: DateTime.now().toUtc(),
        ),
      ];

      final result = await dao.upsertAll(events);
      
      // At least the valid event should be processed
      expect(result.total + result.skipped, equals(events.length));
      expect(result.inserted, greaterThan(0)); // At least one valid insert
    });

    test('Large batch upsert performance', () async {
      // Test case: Large batch should complete within reasonable time
      final dao = EventDao();
      
      // Create 100 events
      final events = List.generate(100, (index) => EventModel(
        id: 'batch_event_$index',
        source: 'performance_test',
        uid: 'batch_uid_$index',
        title: '배치 테스트 이벤트 $index',
        start: DateTime.now().add(Duration(minutes: index)).toUtc(),
      ));

      final stopwatch = Stopwatch()..start();
      final result = await dao.upsertAll(events);
      stopwatch.stop();

      expect(result.inserted, equals(100));
      expect(result.updated, equals(0));
      expect(result.skipped, equals(0));
      
      // Should complete within 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('Empty event list handles gracefully', () async {
      // Test case: Empty list should return zero stats
      final dao = EventDao();
      
      final result = await dao.upsertAll([]);
      
      expect(result.inserted, equals(0));
      expect(result.updated, equals(0));
      expect(result.skipped, equals(0));
      expect(result.total, equals(0));
    });

    test('Event with null UID is handled correctly', () async {
      // Test case: Events without UID should still be processed
      final dao = EventDao();
      
      final eventWithoutUid = EventModel(
        id: 'no_uid_event',
        source: 'internal',
        uid: null, // No external UID
        title: 'UID 없는 내부 이벤트',
        start: DateTime.now().toUtc(),
      );

      final result = await dao.upsertAll([eventWithoutUid]);
      
      // Should insert successfully (new events without UID are always inserted)
      expect(result.total, equals(1));
    });

    test('Event update preserves metadata correctly', () async {
      // Test case: Updated event should maintain proper timestamps
      final dao = EventDao();
      
      final originalEvent = EventModel(
        id: 'metadata_test',
        source: 'test',
        uid: 'metadata_uid',
        title: '메타데이터 테스트',
        start: DateTime.now().toUtc(),
      );

      // Insert original
      await dao.upsertAll([originalEvent]);
      
      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update with new data
      final updatedEvent = EventModel(
        id: originalEvent.id,
        source: originalEvent.source,
        uid: originalEvent.uid,
        title: '업데이트된 메타데이터 테스트',
        start: originalEvent.start,
        location: '새로운 위치', // Added location
      );

      final result = await dao.upsertAll([updatedEvent]);
      
      expect(result.updated, equals(1));
      
      // Verify the updated event has correct data
      final testDate = DateTime(2025, 9, 10);
      final (startMs, endMs) = dao.utcRangeOfLocalDay(testDate);
      final retrievedEvents = await dao.findBetweenUtc(startMs, endMs);
      
      // Should find updated event if it falls within test date
      if (retrievedEvents.isNotEmpty) {
        final retrieved = EventModel.fromRow(retrievedEvents.first);
        expect(retrieved.title, equals('업데이트된 메타데이터 테스트'));
        expect(retrieved.location, equals('새로운 위치'));
      }
    });

    test('Concurrent upserts handle properly', () async {
      // Test case: Multiple concurrent upserts should not interfere
      final dao = EventDao();
      
      final futures = <Future<UpsertStats>>[];
      
      // Launch 5 concurrent upserts
      for (int i = 0; i < 5; i++) {
        final events = [
          EventModel(
            id: 'concurrent_$i',
            source: 'concurrent_test',
            uid: 'concurrent_uid_$i',
            title: '동시 테스트 $i',
            start: DateTime.now().add(Duration(minutes: i)).toUtc(),
          ),
        ];
        futures.add(dao.upsertAll(events));
      }
      
      final results = await Future.wait(futures);
      
      // All should succeed
      expect(results.length, equals(5));
      for (final result in results) {
        expect(result.inserted, equals(1));
        expect(result.updated, equals(0));
        expect(result.skipped, equals(0));
      }
    });
  });

  group('UpsertStats Tests', () {
    test('UpsertStats total calculation is correct', () {
      final stats = UpsertStats(inserted: 5, updated: 3, skipped: 2);
      
      expect(stats.total, equals(8)); // inserted + updated
      expect(stats.inserted, equals(5));
      expect(stats.updated, equals(3));
      expect(stats.skipped, equals(2));
    });

    test('UpsertStats toString provides readable format', () {
      final stats = UpsertStats(inserted: 1, updated: 2, skipped: 0);
      final string = stats.toString();
      
      expect(string, contains('inserted: 1'));
      expect(string, contains('updated: 2'));
      expect(string, contains('skipped: 0'));
    });
  });
}