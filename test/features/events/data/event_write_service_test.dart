import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import '../../../../lib/core/time/app_time.dart';
import '../../../../lib/core/time/date_key.dart';
import '../../../../lib/core/time/kst.dart';
import '../../../../lib/data/services/event_write_service.dart';
import '../../../../lib/data/services/event_change_bus.dart';
import '../../../../lib/db/app_database.dart';
import '../../../../lib/features/events/data/event_entity.dart';
import '../../../../lib/features/events/data/events_dao.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Seoul'));
    AppTime.init();
  });

  group('EventWriteService Tests', () {
    late AppDatabase database;
    late EventWriteService writeService;
    late EventChangeBus changeBus;
    late ProviderContainer container;

    setUp(() async {
      database = AppDatabase.instance;
      await database.database; // Initialize database
      changeBus = EventChangeBus();
      container = ProviderContainer();
      writeService = EventWriteService(database, changeBus, container: container);
    });

    tearDown(() async {
      await database.close();
      container.dispose();
    });

    group('Cross-day Event Handling', () {
      test('should detect cross-day events spanning midnight', () async {
        // Create event from 23:30 to 01:30 next day (KST)
        final startKst = KST.now().copyWith(hour: 23, minute: 30, second: 0, millisecond: 0);
        final endKst = startKst.add(const Duration(hours: 2)); // Next day 01:30

        final startUtc = KST.toUtc(startKst);
        final endUtc = KST.toUtc(endKst);

        final draft = EventDraft(
          title: 'Cross-day Event',
          startTime: startUtc,
          endTime: endUtc,
        );

        await writeService.addEvent(draft);

        // Verify event was stored correctly
        final dao = EventsDao();
        final events = await dao.range(
          startUtc.subtract(const Duration(hours: 1)).toIso8601String(),
          endUtc.add(const Duration(hours: 1)).toIso8601String(),
        );

        expect(events.length, 1);
        final event = events.first;

        // Verify times are stored as UTC
        expect(event.startDt.endsWith('Z'), true);
        expect(event.endDt?.endsWith('Z'), true);

        // Verify the event spans midnight when converted to KST
        final storedStartKst = AppTime.toKst(DateTime.parse(event.startDt));
        final storedEndKst = AppTime.toKst(DateTime.parse(event.endDt!));

        expect(storedStartKst.hour, 23);
        expect(storedEndKst.hour, 1);
        expect(storedEndKst.day, storedStartKst.day + 1);
      });

      test('should handle cross-day all-day events', () async {
        final startKst = KST.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        final endKst = startKst.add(const Duration(days: 2)); // 2-day event

        final startUtc = KST.toUtc(startKst);
        final endUtc = KST.toUtc(endKst);

        final draft = EventDraft(
          title: 'Multi-day All Day Event',
          startTime: startUtc,
          endTime: endUtc,
          allDay: true,
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final events = await dao.range(
          startUtc.subtract(const Duration(hours: 1)).toIso8601String(),
          endUtc.add(const Duration(hours: 1)).toIso8601String(),
        );

        expect(events.length, 1);
        expect(events.first.allDay, true);
      });
    });

    group('Deletion and Undo Functionality', () {
      test('should soft delete event and allow restore', () async {
        // Create event
        final draft = EventDraft(
          title: 'Test Event for Deletion',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        expect(events.length, 1);
        final eventId = events.first.id;

        // Delete event (soft delete)
        final deletedEvent = await writeService.deleteEvent(eventId);
        expect(deletedEvent, isNotNull);
        expect(deletedEvent!.title, 'Test Event for Deletion');

        // Verify event is not in regular query
        final activeEvents = await dao.range(rangeStart, rangeEnd);
        expect(activeEvents.length, 0);

        // Verify event exists in deleted query
        final deletedEventFromDb = await dao.getByIdIncludingDeleted(eventId);
        expect(deletedEventFromDb, isNotNull);
        expect(deletedEventFromDb!.deletedAt, isNotNull);

        // Restore event
        await writeService.restoreEvent(eventId);

        // Verify event is restored
        final restoredEvents = await dao.range(rangeStart, rangeEnd);
        expect(restoredEvents.length, 1);
        expect(restoredEvents.first.deletedAt, isNull);
      });

      test('should hard delete event permanently', () async {
        final draft = EventDraft(
          title: 'Test Event for Hard Deletion',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final eventId = events.first.id;

        // Hard delete event
        final deletedEvent = await writeService.deleteEvent(eventId, hard: true);
        expect(deletedEvent, isNotNull);

        // Verify event is completely gone
        final activeEvents = await dao.range(rangeStart, rangeEnd);
        expect(activeEvents.length, 0);

        final deletedEventFromDb = await dao.getByIdIncludingDeleted(eventId);
        expect(deletedEventFromDb, isNull);
      });

      test('should emit change events for delete and restore', () async {
        final changeEvents = <EventChanged>[];
        changeBus.stream.listen(changeEvents.add);

        final draft = EventDraft(
          title: 'Test Event for Change Events',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final eventId = events.first.id;

        // Clear create event
        changeEvents.clear();

        // Delete event
        await writeService.deleteEvent(eventId);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 10));

        expect(changeEvents.length, 1);
        expect(changeEvents.first.type, EventChangeType.deleted);
        expect(changeEvents.first.eventId, eventId);

        changeEvents.clear();

        // Restore event
        await writeService.restoreEvent(eventId);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(changeEvents.length, 1);
        expect(changeEvents.first.type, EventChangeType.updated);
        expect(changeEvents.first.eventId, eventId);
      });
    });

    group('Conflict Detection', () {
      test('should detect concurrent modification conflicts', () async {
        final draft = EventDraft(
          title: 'Test Event for Conflict',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final originalEvent = events.first;
        final originalUpdatedAt = originalEvent.updatedAt;

        // Simulate concurrent modification by updating the event
        final patch1 = EventPatch(
          id: originalEvent.id,
          title: 'Updated by User 1',
        );

        await writeService.updateEvent(patch1);

        // Try to update with stale updatedAt timestamp
        final patch2 = EventPatch(
          id: originalEvent.id,
          title: 'Updated by User 2',
        );

        expect(
          () => writeService.updateEvent(patch2, expectedUpdatedAt: originalUpdatedAt),
          throwsA(isA<EventConflictException>()),
        );
      });

      test('should provide detailed conflict information', () async {
        final draft = EventDraft(
          title: 'Test Event for Detailed Conflict',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final originalEvent = events.first;
        final originalUpdatedAt = originalEvent.updatedAt;

        // Update event to create newer updatedAt
        await writeService.updateEvent(EventPatch(
          id: originalEvent.id,
          title: 'Intermediate Update',
        ));

        // Get the new updatedAt
        final updatedEvents = await dao.range(rangeStart, rangeEnd);
        final newUpdatedAt = updatedEvents.first.updatedAt;

        // Try to update with stale updatedAt
        try {
          await writeService.updateEvent(
            EventPatch(id: originalEvent.id, title: 'Conflicting Update'),
            expectedUpdatedAt: originalUpdatedAt,
          );
          fail('Expected EventConflictException');
        } catch (e) {
          expect(e, isA<EventConflictException>());
          final conflict = e as EventConflictException;

          expect(conflict.eventId, originalEvent.id);
          expect(conflict.expectedUpdatedAt, originalUpdatedAt);
          expect(conflict.actualUpdatedAt, newUpdatedAt);
          expect(conflict.message, contains('다른 곳에서 이 일정이 수정되었습니다'));
        }
      });

      test('should allow update with correct updatedAt', () async {
        final draft = EventDraft(
          title: 'Test Event for Successful Update',
          startTime: DateTime.now().toUtc(),
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final originalEvent = events.first;

        // Update with correct updatedAt should succeed
        final patch = EventPatch(
          id: originalEvent.id,
          title: 'Successfully Updated',
        );

        await writeService.updateEvent(patch, expectedUpdatedAt: originalEvent.updatedAt);

        final updatedEvents = await dao.range(rangeStart, rangeEnd);
        expect(updatedEvents.first.title, 'Successfully Updated');
      });
    });

    group('UTC Enforcement', () {
      test('should convert non-UTC timestamps to UTC with warning', () async {
        // Create a non-UTC DateTime (local time)
        final localTime = DateTime(2024, 1, 15, 14, 30); // No timezone info

        final draft = EventDraft(
          title: 'Test Non-UTC Time',
          startTime: localTime, // This should be converted to UTC
        );

        // This should succeed with automatic UTC conversion
        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        expect(events.length, 1);

        final event = events.first;
        expect(event.startDt.endsWith('Z'), true); // Should be UTC
      });

      test('should preserve UTC timestamps without conversion', () async {
        final utcTime = DateTime.now().toUtc();

        final draft = EventDraft(
          title: 'Test UTC Time',
          startTime: utcTime,
        );

        await writeService.addEvent(draft);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        final event = events.first;

        final storedTime = DateTime.parse(event.startDt);
        expect(storedTime.isUtc, true);
        expect(storedTime.millisecondsSinceEpoch, utcTime.millisecondsSinceEpoch);
      });
    });

    group('Batch Operations', () {
      test('should handle batch event creation with UTC enforcement', () async {
        final drafts = List.generate(5, (index) => EventDraft(
          title: 'Batch Event $index',
          startTime: DateTime.now().add(Duration(hours: index)).toUtc(),
        ));

        await writeService.addEvents(drafts);

        final dao = EventsDao();
        final rangeStart = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        final rangeEnd = DateTime.now().add(const Duration(days: 1)).toIso8601String();

        final events = await dao.range(rangeStart, rangeEnd);
        expect(events.length, 5);

        // Verify all events have UTC timestamps
        for (final event in events) {
          expect(event.startDt.endsWith('Z'), true);
        }
      });

      test('should emit batch change events', () async {
        final changeEvents = <EventChanged>[];
        changeBus.stream.listen(changeEvents.add);

        final drafts = List.generate(3, (index) => EventDraft(
          title: 'Batch Change Event $index',
          startTime: DateTime.now().add(Duration(hours: index)).toUtc(),
        ));

        await writeService.addEvents(drafts);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(changeEvents.length, 3);
        expect(changeEvents.every((e) => e.type == EventChangeType.created), true);
      });
    });
  });
}