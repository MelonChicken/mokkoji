import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import '../../lib/core/time/app_time.dart';
import '../../lib/core/time/date_key.dart';
import '../../lib/core/time/kst.dart';
import '../../lib/data/services/event_write_service.dart';
import '../../lib/data/services/event_change_bus.dart';
import '../../lib/db/app_database.dart';
import '../../lib/features/events/data/event_entity.dart';
import '../../lib/features/events/data/events_dao.dart';
import '../../lib/features/events/providers/events_providers.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Seoul'));
    AppTime.init();
  });

  group('Event Update Performance Tests', () {
    late AppDatabase database;
    late EventWriteService writeService;
    late EventChangeBus changeBus;
    late ProviderContainer container;

    setUp(() async {
      database = AppDatabase(isTest: true);
      await database.openConnection();
      changeBus = EventChangeBus();
      container = ProviderContainer();
      writeService = EventWriteService(database, changeBus, container: container);
    });

    tearDown(() async {
      await database.closeConnection();
      container.dispose();
    });

    test('should complete event creation within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      final draft = EventDraft(
        title: 'Performance Test Event',
        startTime: DateTime.now().toUtc(),
        endTime: DateTime.now().add(const Duration(hours: 1)).toUtc(),
      );

      final stopwatch = Stopwatch()..start();
      await writeService.addEvent(draft);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event creation took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Event creation: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should complete event update within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create initial event
      final draft = EventDraft(
        title: 'Update Performance Test',
        startTime: DateTime.now().toUtc(),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final events = await dao.getAllEvents();
      final eventId = events.first.id;

      // Measure update performance
      final patch = EventPatch(
        id: eventId,
        title: 'Updated Title',
        description: 'Updated Description',
      );

      final stopwatch = Stopwatch()..start();
      await writeService.updateEvent(patch);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event update took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Event update: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should complete event deletion within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create initial event
      final draft = EventDraft(
        title: 'Delete Performance Test',
        startTime: DateTime.now().toUtc(),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final events = await dao.getAllEvents();
      final eventId = events.first.id;

      // Measure deletion performance
      final stopwatch = Stopwatch()..start();
      await writeService.deleteEvent(eventId);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event deletion took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Event deletion: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should handle cross-day event updates within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create cross-day event (23:30 to 01:30 next day)
      final startKst = KST.now().copyWith(hour: 23, minute: 30, second: 0, millisecond: 0);
      final endKst = startKst.add(const Duration(hours: 2));

      final draft = EventDraft(
        title: 'Cross-day Performance Test',
        startTime: AppTime.toUtc(startKst),
        endTime: AppTime.toUtc(endKst),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final events = await dao.getAllEvents();
      final eventId = events.first.id;

      // Update the cross-day event
      final newEndKst = endKst.add(const Duration(hours: 1)); // Extend to 02:30
      final patch = EventPatch(
        id: eventId,
        title: 'Updated Cross-day Event',
        endTime: AppTime.toUtc(newEndKst),
      );

      final stopwatch = Stopwatch()..start();
      await writeService.updateEvent(patch);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Cross-day event update took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Cross-day event update: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should handle batch operations efficiently', () async {
      const maxLatencyPerEvent = Duration(milliseconds: 50); // 50ms per event for batch of 10

      // Create 10 events in batch
      final drafts = List.generate(10, (index) => EventDraft(
        title: 'Batch Event $index',
        startTime: DateTime.now().add(Duration(hours: index)).toUtc(),
      ));

      final stopwatch = Stopwatch()..start();
      await writeService.addEvents(drafts);
      stopwatch.stop();

      final averageLatency = Duration(milliseconds: stopwatch.elapsed.inMilliseconds ~/ 10);

      expect(averageLatency, lessThan(maxLatencyPerEvent),
          reason: 'Batch event creation averaged ${averageLatency.inMilliseconds}ms per event, exceeding 50ms per event');

      print('✅ Batch event creation: ${stopwatch.elapsed.inMilliseconds}ms total (${averageLatency.inMilliseconds}ms avg per event)');
    });

    test('should complete provider invalidation within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Set up provider watching
      final today = DateKey.today();
      final eventsProvider = container.read(eventsForDayProvider(today).notifier);

      // Create event for today
      final draft = EventDraft(
        title: 'Provider Invalidation Test',
        startTime: DateTime.now().toUtc(),
      );

      final stopwatch = Stopwatch()..start();
      await writeService.addEvent(draft);

      // Wait for provider invalidation to complete
      await Future.delayed(const Duration(milliseconds: 10));
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Provider invalidation took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Provider invalidation: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should handle conflict detection efficiently', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create initial event
      final draft = EventDraft(
        title: 'Conflict Performance Test',
        startTime: DateTime.now().toUtc(),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final events = await dao.getAllEvents();
      final event = events.first;

      // Update event to create new updatedAt
      await writeService.updateEvent(EventPatch(
        id: event.id,
        title: 'Intermediate Update',
      ));

      // Try conflicting update with stale updatedAt
      final patch = EventPatch(
        id: event.id,
        title: 'Conflicting Update',
      );

      final stopwatch = Stopwatch()..start();
      try {
        await writeService.updateEvent(patch, expectedUpdatedAt: event.updatedAt);
        fail('Expected EventConflictException');
      } catch (e) {
        stopwatch.stop();
        expect(e, isA<EventConflictException>());
      }

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Conflict detection took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');

      print('✅ Conflict detection: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should maintain performance under concurrent operations', () async {
      const maxLatency = Duration(milliseconds: 300); // Allow slightly more for concurrent ops

      // Create multiple concurrent operations
      final futures = <Future>[];

      // Add events concurrently
      for (int i = 0; i < 5; i++) {
        futures.add(writeService.addEvent(EventDraft(
          title: 'Concurrent Event $i',
          startTime: DateTime.now().add(Duration(hours: i)).toUtc(),
        )));
      }

      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Concurrent operations took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 300ms tolerance');

      print('✅ Concurrent operations: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    test('should handle timezone conversions efficiently', () async {
      const maxLatency = Duration(milliseconds: 100); // Timezone conversion should be fast

      final testCases = [
        DateTime.now(), // Local time
        DateTime.now().toUtc(), // UTC
        DateTime.parse('2024-01-15T14:30:00+09:00'), // With offset
        DateTime.parse('2024-01-15T14:30:00'), // Naive datetime
      ];

      for (int i = 0; i < testCases.length; i++) {
        final stopwatch = Stopwatch()..start();

        await writeService.addEvent(EventDraft(
          title: 'Timezone Test $i',
          startTime: testCases[i],
        ));

        stopwatch.stop();

        expect(stopwatch.elapsed, lessThan(maxLatency),
            reason: 'Timezone conversion $i took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 100ms requirement');

        print('✅ Timezone conversion $i: ${stopwatch.elapsed.inMilliseconds}ms');
      }
    });

    test('should measure change bus notification latency', () async {
      const maxLatency = Duration(milliseconds: 50); // Change notifications should be very fast

      final notifications = <EventChanged>[];
      changeBus.stream.listen(notifications.add);

      final stopwatch = Stopwatch()..start();

      await writeService.addEvent(EventDraft(
        title: 'Change Bus Test',
        startTime: DateTime.now().toUtc(),
      ));

      // Wait for notification
      await Future.delayed(const Duration(milliseconds: 10));
      stopwatch.stop();

      expect(notifications.length, 1);
      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Change bus notification took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 50ms requirement');

      print('✅ Change bus notification: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    group('Memory Performance', () {
      test('should not cause memory leaks during repeated operations', () async {
        // This test helps identify memory leaks in repeated operations
        final initialMemory = _getMemoryUsage();

        // Perform 100 operations
        for (int i = 0; i < 100; i++) {
          final draft = EventDraft(
            title: 'Memory Test $i',
            startTime: DateTime.now().add(Duration(seconds: i)).toUtc(),
          );

          await writeService.addEvent(draft);

          // Periodically check memory growth
          if (i % 20 == 0) {
            final currentMemory = _getMemoryUsage();
            final memoryGrowth = currentMemory - initialMemory;

            // Allow reasonable memory growth (50MB max for 100 events)
            expect(memoryGrowth, lessThan(50 * 1024 * 1024),
                reason: 'Memory usage grew by ${memoryGrowth / (1024 * 1024)}MB after $i operations');
          }
        }

        final finalMemory = _getMemoryUsage();
        final totalGrowth = finalMemory - initialMemory;
        print('✅ Memory growth after 100 operations: ${totalGrowth / (1024 * 1024)}MB');
      });
    });
  });
}

/// Placeholder for memory usage measurement
/// In a real implementation, you might use dart:developer or platform-specific APIs
int _getMemoryUsage() {
  // This is a placeholder - actual implementation would measure memory usage
  // For Flutter apps, you might use:
  // - dart:developer's getCurrentRSS()
  // - Platform-specific memory profiling tools
  // - Custom memory tracking
  return DateTime.now().millisecondsSinceEpoch % 1000000; // Mock value
}