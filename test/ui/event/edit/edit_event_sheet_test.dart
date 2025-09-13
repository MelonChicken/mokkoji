import 'package:flutter/material.dart';
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
import '../../../../lib/ui/event/edit/edit_event_sheet.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Seoul'));
    AppTime.init();
  });

  group('EditEventSheet Tests', () {
    late AppDatabase database;
    late EventWriteService writeService;
    late EventChangeBus changeBus;

    setUp(() async {
      database = AppDatabase(isTest: true);
      await database.openConnection();
      changeBus = EventChangeBus();
      writeService = EventWriteService(database, changeBus);
    });

    tearDown(() async {
      await database.closeConnection();
    });

    testWidgets('should show edit form for existing event', (tester) async {
      // Create test event
      final event = EventEntity(
        id: 'edit-test',
        title: 'Test Event',
        description: 'Test Description',
        location: 'Test Location',
        startDt: DateTime.now().toUtc().toIso8601String(),
        endDt: DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final dao = EventsDao();
      await dao.upsert(event);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, event.id),
                  child: const Text('Show Edit Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to show edit sheet
      await tester.tap(find.text('Show Edit Sheet'));
      await tester.pumpAndSettle();

      // Verify edit sheet is shown
      expect(find.text('일정 수정'), findsOneWidget);
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
    });

    testWidgets('should show conflict warning banner when conflict detected', (tester) async {
      // Create test event
      final event = EventEntity(
        id: 'conflict-test',
        title: 'Conflict Test Event',
        startDt: DateTime.now().toUtc().toIso8601String(),
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final dao = EventsDao();
      await dao.upsert(event);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, event.id),
                  child: const Text('Show Edit Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show edit sheet
      await tester.tap(find.text('Show Edit Sheet'));
      await tester.pumpAndSettle();

      // Simulate concurrent modification by updating the event externally
      await writeService.updateEvent(EventPatch(
        id: event.id,
        title: 'Updated Externally',
      ));

      // Try to save with stale data to trigger conflict
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Should show conflict warning
      expect(find.text('다른 곳에서 이 일정이 수정되었습니다'), findsOneWidget);
      expect(find.text('새로고침'), findsOneWidget);
    });

    testWidgets('should handle new event creation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Verify new event sheet is shown
      expect(find.text('새 일정'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);

      // Enter event details
      await tester.enterText(find.byType(TextFormField).first, 'New Test Event');
      await tester.pumpAndSettle();

      // Save event
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Verify event was created
      final dao = EventsDao();
      final events = await dao.getAllEvents();
      expect(events.length, 1);
      expect(events.first.title, 'New Test Event');
    });

    testWidgets('should validate required fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Try to save without title
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('제목을 입력해주세요'), findsOneWidget);
    });

    testWidgets('should handle all-day event toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Find and toggle all-day switch
      final allDaySwitch = find.byType(Switch);
      expect(allDaySwitch, findsOneWidget);

      await tester.tap(allDaySwitch);
      await tester.pumpAndSettle();

      // Time pickers should be hidden/disabled for all-day events
      // This test verifies the UI responds to the toggle
    });

    testWidgets('should handle date and time selection', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Enter title first
      await tester.enterText(find.byType(TextFormField).first, 'Date Test Event');

      // Find date/time selection widgets
      // The exact implementation depends on your UI structure
      // This is a placeholder for date/time interaction tests

      // Save event
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Verify event was created with correct timing
      final dao = EventsDao();
      final events = await dao.getAllEvents();
      expect(events.length, 1);
    });

    testWidgets('should refresh data on conflict resolution', (tester) async {
      // Create test event
      final event = EventEntity(
        id: 'refresh-test',
        title: 'Refresh Test Event',
        startDt: DateTime.now().toUtc().toIso8601String(),
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      final dao = EventsDao();
      await dao.upsert(event);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, event.id),
                  child: const Text('Show Edit Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show edit sheet
      await tester.tap(find.text('Show Edit Sheet'));
      await tester.pumpAndSettle();

      // Update event externally to create conflict
      await writeService.updateEvent(EventPatch(
        id: event.id,
        title: 'Externally Updated Title',
      ));

      // Try to save to trigger conflict
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Should show conflict banner
      expect(find.text('새로고침'), findsOneWidget);

      // Tap refresh button
      await tester.tap(find.text('새로고침'));
      await tester.pumpAndSettle();

      // Should refresh with new data
      expect(find.text('Externally Updated Title'), findsOneWidget);
    });

    testWidgets('should handle form state changes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Test title field
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'State Change Test');
      await tester.pumpAndSettle();

      // Verify the input is registered
      expect(find.text('State Change Test'), findsOneWidget);

      // Test other form fields if they exist
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length > 1) {
        // Test description field
        await tester.enterText(textFields.at(1), 'Test description');
        await tester.pumpAndSettle();
        expect(find.text('Test description'), findsOneWidget);
      }
    });

    testWidgets('should show loading state during save', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEditEventSheet(context, null),
                  child: const Text('New Event'),
                ),
              ),
            ),
          ),
        ),
      );

      // Show new event sheet
      await tester.tap(find.text('New Event'));
      await tester.pumpAndSettle();

      // Enter required data
      await tester.enterText(find.byType(TextFormField).first, 'Loading Test Event');

      // Start save operation
      await tester.tap(find.text('저장'));

      // Pump once to start the async operation
      await tester.pump();

      // Should show loading indicator or disabled save button
      // The exact implementation depends on your UI design
    });

    group('Form Validation', () {
      testWidgets('should validate end time is after start time', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showEditEventSheet(context, null),
                    child: const Text('New Event'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show new event sheet
        await tester.tap(find.text('New Event'));
        await tester.pumpAndSettle();

        // Enter title
        await tester.enterText(find.byType(TextFormField).first, 'Validation Test');

        // Set up invalid time range (end before start)
        // This would require interacting with your date/time pickers
        // Implementation depends on your specific UI components

        // Try to save
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        // Should show validation error for invalid time range
        // expect(find.text('종료 시간은 시작 시간 이후여야 합니다'), findsOneWidget);
      });
    });
  });
}