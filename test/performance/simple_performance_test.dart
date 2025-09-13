import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import '../../lib/core/time/app_time.dart';
import '../../lib/data/services/event_write_service.dart';
import '../../lib/data/services/event_change_bus.dart';
import '../../lib/db/app_database.dart';
import '../../lib/features/events/data/events_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Seoul'));
    AppTime.init();
  });

  group('Performance Tests', () {
    late EventWriteService writeService;
    late EventChangeBus changeBus;

    setUp(() async {
      changeBus = EventChangeBus.instance;
      writeService = EventWriteService(AppDatabase.instance, changeBus);
    });

    test('Event creation should complete within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      final draft = EventDraft(
        title: 'Performance Test Event',
        startTime: DateTime.now().toUtc(),
        endTime: DateTime.now().add(const Duration(hours: 1)).toUtc(),
      );

      final stopwatch = Stopwatch()..start();
      await writeService.addEvent(draft);
      stopwatch.stop();

      print('Event creation: ${stopwatch.elapsed.inMilliseconds}ms');

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event creation took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');
    });

    test('Event update should complete within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create initial event
      final draft = EventDraft(
        title: 'Update Performance Test',
        startTime: DateTime.now().toUtc(),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final events = await dao.range(rangeStart, rangeEnd);
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

      print('Event update: ${stopwatch.elapsed.inMilliseconds}ms');

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event update took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');
    });

    test('Event deletion should complete within 200ms', () async {
      const maxLatency = Duration(milliseconds: 200);

      // Create initial event
      final draft = EventDraft(
        title: 'Delete Performance Test',
        startTime: DateTime.now().toUtc(),
      );
      await writeService.addEvent(draft);

      final dao = EventsDao();
      final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      final events = await dao.range(rangeStart, rangeEnd);
      final eventId = events.first.id;

      // Measure deletion performance
      final stopwatch = Stopwatch()..start();
      await writeService.deleteEvent(eventId);
      stopwatch.stop();

      print('Event deletion: ${stopwatch.elapsed.inMilliseconds}ms');

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Event deletion took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 200ms requirement');
    });

    test('Batch operations should be efficient', () async {
      const maxLatencyPerEvent = Duration(milliseconds: 50); // 50ms per event for batch of 5

      // Create 5 events in batch
      final drafts = List.generate(5, (index) => EventDraft(
        title: 'Batch Event $index',
        startTime: DateTime.now().add(Duration(hours: index)).toUtc(),
      ));

      final stopwatch = Stopwatch()..start();
      await writeService.addEvents(drafts);
      stopwatch.stop();

      final averageLatency = Duration(milliseconds: stopwatch.elapsed.inMilliseconds ~/ 5);

      print('Batch creation: ${stopwatch.elapsed.inMilliseconds}ms total (${averageLatency.inMilliseconds}ms avg per event)');

      expect(averageLatency, lessThan(maxLatencyPerEvent),
          reason: 'Batch event creation averaged ${averageLatency.inMilliseconds}ms per event, exceeding 50ms per event');
    });

    test('Change bus notifications should be fast', () async {
      const maxLatency = Duration(milliseconds: 50);

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

      print('Change bus notification: ${stopwatch.elapsed.inMilliseconds}ms');

      expect(stopwatch.elapsed, lessThan(maxLatency),
          reason: 'Change bus notification took ${stopwatch.elapsed.inMilliseconds}ms, exceeding 50ms requirement');
    });
  });
}