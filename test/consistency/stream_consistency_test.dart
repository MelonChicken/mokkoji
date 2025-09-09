import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mokkoji/data/app_database.dart';
import 'package:mokkoji/data/repositories/unified_event_repository.dart';
import 'package:mokkoji/data/services/event_write_service.dart';
import 'package:mokkoji/data/services/event_change_bus.dart';
import 'package:mokkoji/core/time/app_time.dart';

void main() {
  group('Stream Consistency Tests', () {
    late UnifiedEventRepository repository;
    late EventWriteService writeService;
    late AppDatabase database;
    late EventChangeBus changeBus;

    setUp(() async {
      // Initialize time zones for testing
      await AppTime.ensureInitialized();
      
      // Create test database and services
      database = AppDatabaseHolder.instance();
      changeBus = EventChangeBus.instance;
      repository = UnifiedEventRepository(database);
      writeService = EventWriteService(database, changeBus);
    });

    tearDown(() async {
      AppDatabaseHolder.clear();
    });

    testWidgets('Home timeline and summary show consistent data', (WidgetTester tester) async {
      // Given: A specific KST day
      final testDayKst = AppTime.dayStartKst(DateTime(2025, 9, 9));
      
      // Create test events in UTC
      final event1Draft = EventDraft(
        title: 'Morning Meeting',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 9))),
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 10))),
        sourcePlatform: 'google',
      );
      
      final event2Draft = EventDraft(
        title: 'Lunch',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 12))),
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 13))),
        sourcePlatform: 'internal',
      );

      // When: Add events
      await writeService.addEvent(event1Draft);
      await writeService.addEvent(event2Draft);

      // Then: Both streams should show same count and next event
      final occurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      final summary = await repository.watchTodaySummaryKst(testDayKst).first;

      expect(occurrences.length, equals(2));
      expect(summary.count, equals(2));
      
      // Next event should be the same in both streams
      final nextFromOccurrences = occurrences.firstWhere(
        (occ) => occ.startKst.isAfter(AppTime.nowKst()),
        orElse: () => throw Exception('No next event found'),
      );
      
      expect(summary.next, isNotNull);
      expect(summary.next!.id, equals(nextFromOccurrences.id));
      expect(summary.next!.title, equals(nextFromOccurrences.title));
    });

    testWidgets('Event updates reflect immediately in all streams', (WidgetTester tester) async {
      // Given: An existing event
      final testDayKst = AppTime.dayStartKst(DateTime(2025, 9, 9));
      final originalDraft = EventDraft(
        title: 'Original Title',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 14))),
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 15))),
        sourcePlatform: 'google',
      );
      
      await writeService.addEvent(originalDraft);
      
      // Get the event ID from the occurrences
      final initialOccurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      expect(initialOccurrences.length, equals(1));
      
      final eventId = initialOccurrences.first.id;

      // When: Update the event
      final updatePatch = EventPatch(
        id: eventId,
        title: 'Updated Title',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 15))), // Move by 1 hour
      );
      
      await writeService.updateEvent(updatePatch);

      // Then: Both streams should show updated data immediately
      final updatedOccurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      final updatedSummary = await repository.watchTodaySummaryKst(testDayKst).first;

      expect(updatedOccurrences.length, equals(1));
      expect(updatedSummary.count, equals(1));
      
      final updatedOccurrence = updatedOccurrences.first;
      expect(updatedOccurrence.title, equals('Updated Title'));
      expect(updatedOccurrence.startKst.hour, equals(15)); // Moved to 15:00 KST
    });

    testWidgets('Event deletion removes from all streams immediately', (WidgetTester tester) async {
      // Given: Two existing events
      final testDayKst = AppTime.dayStartKst(DateTime(2025, 9, 9));
      
      await writeService.addEvents([
        EventDraft(
          title: 'Event 1',
          startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 10))),
          endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 11))),
          sourcePlatform: 'google',
        ),
        EventDraft(
          title: 'Event 2',
          startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 14))),
          endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 15))),
          sourcePlatform: 'internal',
        ),
      ]);

      final initialOccurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      expect(initialOccurrences.length, equals(2));

      // When: Delete one event
      final eventToDelete = initialOccurrences.first;
      await writeService.deleteEvent(eventToDelete.id);

      // Then: Both streams should show reduced count
      final remainingOccurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      final remainingSummary = await repository.watchTodaySummaryKst(testDayKst).first;

      expect(remainingOccurrences.length, equals(1));
      expect(remainingSummary.count, equals(1));
      
      // The remaining event should not be the deleted one
      expect(remainingOccurrences.first.id, isNot(equals(eventToDelete.id)));
    });

    test('Boundary cases: Midnight and timezone edge events', () async {
      // Given: Events at KST boundaries
      final testDayKst = AppTime.dayStartKst(DateTime(2025, 9, 9)); // 2025-09-09 00:00 KST
      
      // Event starting at 23:59 previous day UTC (should appear in KST day)
      final prevDayEvent = EventDraft(
        title: 'Previous Day Event',
        startTime: AppTime.fromKstToUtc(testDayKst.subtract(const Duration(minutes: 1))), // 23:59 prev day KST
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 1))), // 01:00 current day KST
        sourcePlatform: 'google',
      );
      
      // Event ending at 00:01 next day KST (should appear in current KST day)
      final spanningEvent = EventDraft(
        title: 'Spanning Event',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 23))), // 23:00 KST
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 25))), // 01:00 next day KST
        sourcePlatform: 'internal',
      );
      
      // All-day event
      final allDayEvent = EventDraft(
        title: 'All Day Event',
        startTime: testDayKst,
        endTime: null, // All-day events typically have no end time
        allDay: true,
        sourcePlatform: 'google',
      );

      await writeService.addEvents([prevDayEvent, spanningEvent, allDayEvent]);

      // When: Query for the KST day
      final occurrences = await repository.watchOccurrencesForDayKst(testDayKst).first;
      final summary = await repository.watchTodaySummaryKst(testDayKst).first;

      // Then: All boundary events should appear
      expect(occurrences.length, equals(3));
      expect(summary.count, equals(3));
      
      final titles = occurrences.map((o) => o.title).toSet();
      expect(titles, containsAll(['Previous Day Event', 'Spanning Event', 'All Day Event']));
      
      // Verify proper KST intersection logic
      for (final occ in occurrences) {
        final dayStart = AppTime.dayStartKst(testDayKst);
        final dayEnd = AppTime.dayEndExclusiveKst(testDayKst);
        
        // Each occurrence should overlap with the day range
        expect(
          occ.startKst.isBefore(dayEnd) && occ.endKst.isAfter(dayStart),
          isTrue,
          reason: 'Event ${occ.title} should overlap with day range',
        );
      }
    });

    test('Stream deduplication works correctly', () async {
      // Given: A test day with events
      final testDayKst = AppTime.dayStartKst(DateTime(2025, 9, 9));
      
      await writeService.addEvent(EventDraft(
        title: 'Test Event',
        startTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 10))),
        endTime: AppTime.fromKstToUtc(testDayKst.add(const Duration(hours: 11))),
        sourcePlatform: 'google',
      ));

      // When: Subscribe to the same stream multiple times
      final stream = repository.watchOccurrencesForDayKst(testDayKst);
      final results = <List<EventOccurrence>>[];
      
      final subscription = stream.listen(results.add);
      
      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Then: Should receive only one emission for same data
      expect(results.length, equals(1));
      expect(results.first.length, equals(1));
      
      subscription.cancel();
    });
  });
}