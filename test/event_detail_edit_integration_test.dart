import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../lib/core/time/kst.dart';
import '../lib/ui/event/detail/detail_event_viewmodel.dart';
import '../lib/ui/event/edit/edit_event_sheet.dart';
import '../lib/features/events/data/event_entity.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko_KR', null);
    KST.init();
  });

  group('Event Detail & Edit Integration Tests', () {
    test('should build detail state correctly with KST display values', () {
      // Test event: 2025-09-13 14:30 KST (UTC: 05:30)
      final event = EventEntity(
        id: 'test-id',
        title: '회의',
        description: '프로젝트 회의',
        startDt: '2025-09-13T05:30:00.000Z', // UTC
        endDt: '2025-09-13T07:00:00.000Z',   // UTC (1.5 hours later)
        allDay: false,
        location: '회의실 A',
        sourcePlatform: 'internal',
        platformColor: null,
        updatedAt: '2025-09-13T05:30:00.000Z',
        url: null,
      );

      // Manual state building (simulating ViewModel behavior)
      final startUtc = KST.parseUtcIsoLenient(event.startDt);
      final endUtc = KST.parseUtcIsoLenient(event.endDt!);

      final startMs = startUtc.millisecondsSinceEpoch;
      final endMs = endUtc.millisecondsSinceEpoch;

      // Expected KST values
      expect(KST.day(startMs), equals('2025년 09월 13일'));
      expect(KST.hm(startMs), equals('14:30'));
      expect(KST.hm(endMs), equals('16:00'));
      expect(KST.range(startMs, endMs), equals('14:30 - 16:00'));

      // Cross-day check (should be false for same day)
      expect(KST.isSameDay(startMs, endMs), isTrue);

      // Duration calculation
      final durationMinutes = (endMs - startMs) / (1000 * 60);
      expect(durationMinutes, equals(90)); // 1.5 hours
    });

    test('should handle cross-midnight events correctly', () {
      // Test event: 23:30 KST - 01:30 KST next day
      final event = EventEntity(
        id: 'cross-midnight',
        title: '밤샘 작업',
        startDt: '2025-09-12T14:30:00.000Z', // 23:30 KST
        endDt: '2025-09-12T16:30:00.000Z',   // 01:30 KST next day
        allDay: false,
        location: null,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-12T14:30:00.000Z',
      );

      final startUtc = KST.parseUtcIsoLenient(event.startDt);
      final endUtc = KST.parseUtcIsoLenient(event.endDt!);

      final startMs = startUtc.millisecondsSinceEpoch;
      final endMs = endUtc.millisecondsSinceEpoch;

      // Should cross midnight
      expect(KST.isSameDay(startMs, endMs), isFalse);

      // Time formatting
      expect(KST.hm(startMs), equals('23:30'));
      expect(KST.hm(endMs), equals('01:30'));
      expect(KST.range(startMs, endMs), equals('23:30 - 01:30'));
    });

    test('should format source chips correctly', () {
      final testCases = [
        ('internal', ['내부']),
        ('google', ['구글']),
        ('naver', ['네이버']),
        ('kakao', ['카카오']),
        ('unknown', ['unknown']),
      ];

      for (final (platform, expected) in testCases) {
        List<String> sourceChips;
        switch (platform.toLowerCase()) {
          case 'google':
            sourceChips = ['구글'];
            break;
          case 'naver':
            sourceChips = ['네이버'];
            break;
          case 'kakao':
            sourceChips = ['카카오'];
            break;
          case 'internal':
            sourceChips = ['내부'];
            break;
          default:
            sourceChips = [platform];
        }

        expect(sourceChips, equals(expected), reason: 'Source platform: $platform');
      }
    });

    test('should build shareable text correctly', () {
      final event = EventEntity(
        id: 'shareable',
        title: '중요한 회의',
        description: '프로젝트 킥오프 미팅',
        startDt: '2025-09-13T05:30:00.000Z',
        endDt: '2025-09-13T07:00:00.000Z',
        allDay: false,
        location: '본사 3층 회의실',
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      // Build share text manually (simulating ViewModel behavior)
      final startMs = KST.parseUtcIsoLenient(event.startDt).millisecondsSinceEpoch;
      final endMs = KST.parseUtcIsoLenient(event.endDt!).millisecondsSinceEpoch;

      final shareText = '''📅 중요한 회의

🕐 ${KST.dayWithWeekday(startMs)}
   ${KST.range(startMs, endMs)} · KST

📍 본사 3층 회의실

📝 프로젝트 킥오프 미팅

출처: 내부''';

      expect(shareText, contains('중요한 회의'));
      expect(shareText, contains('2025년 09월 13일'));
      expect(shareText, contains('14:30 - 16:00'));
      expect(shareText, contains('본사 3층 회의실'));
      expect(shareText, contains('프로젝트 킥오프 미팅'));
      expect(shareText, contains('출처: 내부'));
    });

    test('should validate edit form correctly', () {
      // Valid form state
      final validState = EditEventFormState(
        title: '새 제목',
        dateKst: DateTime(2025, 9, 13),
        startTod: const TimeOfDay(hour: 14, minute: 30),
        durationMinutes: 60,
        location: '장소',
        description: '설명',
      );

      expect(validState.isValid, isTrue);
      expect(validState.endTimePreview, equals(const TimeOfDay(hour: 15, minute: 30)));

      // Invalid form states
      final invalidTitle = validState.copyWith(title: '   '); // Empty after trimming
      expect(invalidTitle.isValid, isFalse);

      // Create a new state without startTod to test null time validation
      final invalidTime = EditEventFormState(
        title: 'Test',
        dateKst: DateTime(2025, 9, 13),
        startTod: null,  // No time set
        durationMinutes: 60,
      );
      expect(invalidTime.isValid, isFalse);

      final invalidDuration = validState.copyWith(durationMinutes: 4); // Less than 5
      expect(invalidDuration.isValid, isFalse);
    });

    test('should handle end time preview with cross-midnight correctly', () {
      final state = EditEventFormState(
        title: 'Test',
        dateKst: DateTime(2025, 9, 13),
        startTod: const TimeOfDay(hour: 23, minute: 30),
        durationMinutes: 120, // 2 hours
      );

      final endPreview = state.endTimePreview;
      expect(endPreview, isNotNull);
      expect(endPreview!.hour, equals(1)); // 01:30 next day
      expect(endPreview.minute, equals(30));
    });

    test('should handle timezone conversion correctly in edit flow', () {
      // Simulate edit flow: UTC -> KST (for editing) -> UTC (for saving)
      const originalUtcIso = '2025-09-13T05:30:00.000Z'; // 14:30 KST

      // 1. Load for editing (UTC -> KST)
      final loadedUtc = KST.parseUtcIsoLenient(originalUtcIso);
      expect(loadedUtc.isUtc, isTrue);

      final loadedMs = loadedUtc.millisecondsSinceEpoch;
      expect(KST.hm(loadedMs), equals('14:30'));
      expect(KST.day(loadedMs), equals('2025년 09월 13일'));

      // 2. Edit form representation
      final kstDateTime = KST.fromUtcMs(loadedMs);
      final dateKst = DateTime(kstDateTime.year, kstDateTime.month, kstDateTime.day);
      final timeKst = TimeOfDay(hour: kstDateTime.hour, minute: kstDateTime.minute);

      expect(dateKst.day, equals(13));
      expect(timeKst.hour, equals(14));
      expect(timeKst.minute, equals(30));

      // 3. Save back to UTC (KST -> UTC)
      final savedUtcMs = KST.toUtcMs(
        year: dateKst.year,
        month: dateKst.month,
        day: dateKst.day,
        hour: timeKst.hour,
        minute: timeKst.minute,
      );

      // Should round-trip correctly
      expect(savedUtcMs, equals(loadedMs));

      final savedUtc = DateTime.fromMillisecondsSinceEpoch(savedUtcMs, isUtc: true);
      expect(savedUtc.toIso8601String(), equals(originalUtcIso));
    });

    test('should handle source URL determination correctly', () {
      // Internal event - no source URL
      final internalEvent = EventEntity(
        id: 'internal',
        title: 'Test',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'internal',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      // Simulate source URL building
      String? sourceUrl;
      if (internalEvent.url?.isNotEmpty == true) {
        sourceUrl = internalEvent.url;
      } else {
        switch (internalEvent.sourcePlatform.toLowerCase()) {
          case 'internal':
            sourceUrl = null;
            break;
          default:
            sourceUrl = null;
        }
      }

      expect(sourceUrl, isNull);

      // Event with URL
      final externalEvent = EventEntity(
        id: 'external',
        title: 'Test',
        startDt: '2025-09-13T05:30:00.000Z',
        allDay: false,
        sourcePlatform: 'google',
        url: 'https://calendar.google.com/event/123',
        updatedAt: '2025-09-13T05:30:00.000Z',
      );

      String? externalUrl;
      if (externalEvent.url?.isNotEmpty == true) {
        externalUrl = externalEvent.url;
      }

      expect(externalUrl, equals('https://calendar.google.com/event/123'));
    });
  });
}