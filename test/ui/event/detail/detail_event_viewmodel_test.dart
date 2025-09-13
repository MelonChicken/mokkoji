import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import '../../../../lib/core/time/app_time.dart';
import '../../../../lib/core/time/kst.dart';
import '../../../../lib/data/services/event_write_service.dart';
import '../../../../lib/data/services/event_change_bus.dart';
import '../../../../lib/db/app_database.dart';
import '../../../../lib/features/events/data/event_entity.dart';
import '../../../../lib/features/events/data/events_dao.dart';
import '../../../../lib/ui/event/detail/detail_event_viewmodel.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Seoul'));
    AppTime.init();
  });

  group('DetailEventViewModel Tests', () {
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

    group('Display String Formatting', () {
      test('should format regular event date and time correctly', () async {
        // Create event on 2024-01-15 14:30 KST
        final kstTime = KST.kstZone.dateTime(2024, 1, 15, 14, 30);
        final utcTime = AppTime.toUtc(kstTime);

        final event = EventEntity(
          id: 'test-event',
          title: 'Regular Event',
          startDt: utcTime.toIso8601String(),
          endDt: utcTime.add(const Duration(hours: 1)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        // Add event to database
        final dao = EventsDao();
        await dao.upsert(event);

        // Create ViewModel and test display formatting
        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.dateLine, contains('2024년 1월 15일'));
        expect(state.dateLine, contains('(월)')); // Monday
        expect(state.rangeLine, '14:30 – 15:30 · KST');
        expect(state.isAllDay, false);
      });

      test('should format all-day event correctly', () async {
        final kstDate = KST.kstZone.dateTime(2024, 1, 15);
        final utcDate = AppTime.toUtc(kstDate);

        final event = EventEntity(
          id: 'all-day-event',
          title: 'All Day Event',
          startDt: utcDate.toIso8601String(),
          allDay: true,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.rangeLine, '종일');
        expect(state.isAllDay, true);
      });

      test('should format cross-day event correctly', () async {
        // Event from 23:30 to 01:30 next day
        final startKst = KST.kstZone.dateTime(2024, 1, 15, 23, 30);
        final endKst = startKst.add(const Duration(hours: 2));

        final startUtc = AppTime.toUtc(startKst);
        final endUtc = AppTime.toUtc(endKst);

        final event = EventEntity(
          id: 'cross-day-event',
          title: 'Cross Day Event',
          startDt: startUtc.toIso8601String(),
          endDt: endUtc.toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.isCrossDay, true);
        expect(state.rangeLine, '23:30 – 01:30 · KST');
      });

      test('should detect timezone conversion note', () async {
        // Create event with non-UTC timestamp (simulating offset timezone)
        final event = EventEntity(
          id: 'tz-convert-event',
          title: 'Timezone Conversion Event',
          startDt: '2024-01-15T14:30:00+09:00', // Has offset, not Z suffix
          allDay: false,
          sourcePlatform: 'google',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.tzNote, '✨ 자동 KST 변환');
      });
    });

    group('Source Platform Handling', () {
      test('should map source platforms to Korean chips', () async {
        final testCases = {
          'google': ['구글'],
          'naver': ['네이버'],
          'kakao': ['카카오'],
          'internal': ['내부'],
          'custom': ['custom'], // Unknown platforms pass through
        };

        for (final entry in testCases.entries) {
          final event = EventEntity(
            id: 'source-test-${entry.key}',
            title: 'Source Test Event',
            startDt: DateTime.now().toUtc().toIso8601String(),
            allDay: false,
            sourcePlatform: entry.key,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );

          final dao = EventsDao();
          await dao.upsert(event);

          final detailVm = container.read(detailEventVmProvider(event.id).notifier);
          final state = await detailVm.future;

          expect(state.sourceChips, entry.value);
        }
      });
    });

    group('Feature Detection', () {
      test('should detect event features correctly', () async {
        final event = EventEntity(
          id: 'feature-test',
          title: 'Feature Rich Event',
          description: 'This is a detailed description',
          location: 'Test Location',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          rrule: 'FREQ=DAILY;COUNT=5', // Has recurrence
          url: 'https://example.com/event',
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.hasLocation, true);
        expect(state.hasDescription, true);
        expect(state.hasRecurrence, true);
        expect(state.sourceUrl, 'https://example.com/event');
        expect(state.isEditable, true);
      });

      test('should handle minimal event correctly', () async {
        final event = EventEntity(
          id: 'minimal-test',
          title: 'Minimal Event',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.hasLocation, false);
        expect(state.hasDescription, false);
        expect(state.hasRecurrence, false);
        expect(state.sourceUrl, null);
        expect(state.isEditable, true);
      });
    });

    group('Delete and Restore Operations', () {
      test('should delete event and return deleted entity', () async {
        final event = EventEntity(
          id: 'delete-test',
          title: 'Event to Delete',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);

        // Ensure initial state is loaded
        await detailVm.future;

        // Delete event
        final deletedEvent = await detailVm.deleteEvent();

        expect(deletedEvent, isNotNull);
        expect(deletedEvent!.id, event.id);
        expect(deletedEvent.title, 'Event to Delete');

        // Verify event is soft deleted
        final activeEvents = await dao.getAllEvents();
        expect(activeEvents.length, 0);

        final deletedFromDb = await dao.getByIdIncludingDeleted(event.id);
        expect(deletedFromDb, isNotNull);
        expect(deletedFromDb!.deletedAt, isNotNull);
      });

      test('should restore deleted event', () async {
        final event = EventEntity(
          id: 'restore-test',
          title: 'Event to Restore',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        await detailVm.future;

        // Delete and then restore
        await detailVm.deleteEvent();
        await detailVm.restoreEvent();

        // Verify event is restored
        final activeEvents = await dao.getAllEvents();
        expect(activeEvents.length, 1);
        expect(activeEvents.first.id, event.id);
        expect(activeEvents.first.deletedAt, null);
      });
    });

    group('Share Event Functionality', () {
      test('should build shareable text correctly', () async {
        final event = EventEntity(
          id: 'share-test',
          title: 'Shareable Event',
          description: 'This is a test event for sharing',
          location: 'Test Location',
          startDt: KST.kstZone.dateTime(2024, 1, 15, 14, 30).toUtc().toIso8601String(),
          endDt: KST.kstZone.dateTime(2024, 1, 15, 16, 0).toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        await detailVm.future;

        // Test share functionality (this will only log in debug mode)
        await detailVm.shareEvent();

        // The actual sharing text is built internally, but we can verify
        // the method completes without error
      });
    });

    group('Sync State Formatting', () {
      test('should format sync state with KST time', () async {
        final now = DateTime.now().toUtc();
        final event = EventEntity(
          id: 'sync-test',
          title: 'Sync State Event',
          startDt: now.toIso8601String(),
          allDay: false,
          sourcePlatform: 'google',
          updatedAt: now.toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.syncState, startsWith('최근 동기화 '));
        expect(state.syncState, contains(':')); // Should contain time format
      });

      test('should handle invalid updatedAt gracefully', () async {
        final event = EventEntity(
          id: 'invalid-sync-test',
          title: 'Invalid Sync Event',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: 'invalid-timestamp',
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        final state = await detailVm.future;

        expect(state.syncState, '동기화 정보 없음');
      });
    });

    group('Error Handling', () {
      test('should handle non-existent event', () async {
        final detailVm = container.read(detailEventVmProvider('non-existent').notifier);

        expect(() => detailVm.future, throwsA(contains('Event not found')));
      });

      test('should retry loading on error', () async {
        // Add event, then delete database to simulate error
        final event = EventEntity(
          id: 'retry-test',
          title: 'Retry Test Event',
          startDt: DateTime.now().toUtc().toIso8601String(),
          allDay: false,
          sourcePlatform: 'internal',
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        final dao = EventsDao();
        await dao.upsert(event);

        final detailVm = container.read(detailEventVmProvider(event.id).notifier);
        await detailVm.future; // Initial load should succeed

        // Simulate error condition by closing database
        await database.closeConnection();

        // Retry should trigger reload
        detailVm.retry();

        // This should cause an error since database is closed
        expect(() => detailVm.future, throwsA(isA<Exception>()));
      });
    });
  });
}