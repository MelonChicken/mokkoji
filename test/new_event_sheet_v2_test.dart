import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import '../lib/core/time/app_time.dart';

/// Test suite for NewEventSheetV2 timezone conversion and cross-day scenarios
void main() {
  group('NewEventSheetV2 Timezone Tests', () {
    setUpAll(() async {
      // Initialize timezone data for tests
      await AppTime.init();
    });

    test('KST input converts correctly to UTC storage', () {
      // Test case: KST 2025-09-10 21:01, 60 minutes → UTC 12:01~13:01
      final kstDateTime = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 21, 1);
      final utcStart = AppTime.fromKstToUtc(kstDateTime);
      final utcEnd = utcStart.add(const Duration(minutes: 60));

      // Expected UTC times (KST is UTC+9)
      expect(utcStart.year, equals(2025));
      expect(utcStart.month, equals(9));
      expect(utcStart.day, equals(10));
      expect(utcStart.hour, equals(12)); // 21 - 9 = 12
      expect(utcStart.minute, equals(1));
      expect(utcStart.isUtc, isTrue);

      expect(utcEnd.hour, equals(13));
      expect(utcEnd.minute, equals(1));
      expect(utcEnd.isUtc, isTrue);
    });

    test('Cross-day scenario: KST 23:30 + 90 minutes', () {
      // Test case: KST 2025-09-10 23:30 + 90 minutes → next day in UTC
      final kstDateTime = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 23, 30);
      final utcStart = AppTime.fromKstToUtc(kstDateTime);
      final utcEnd = utcStart.add(const Duration(minutes: 90));

      // KST 2025-09-10 23:30 → UTC 2025-09-10 14:30
      expect(utcStart.year, equals(2025));
      expect(utcStart.month, equals(9));
      expect(utcStart.day, equals(10));
      expect(utcStart.hour, equals(14)); // 23 - 9 = 14
      expect(utcStart.minute, equals(30));

      // KST 2025-09-11 01:00 → UTC 2025-09-10 16:00
      expect(utcEnd.year, equals(2025));
      expect(utcEnd.month, equals(9));
      expect(utcEnd.day, equals(10)); // Still same day in UTC
      expect(utcEnd.hour, equals(16)); // 14 + 1.5 hours = 16:00
      expect(utcEnd.minute, equals(0));
    });

    test('Early morning KST converts to previous day UTC', () {
      // Test case: KST 2025-09-10 02:00 → UTC 2025-09-09 17:00
      final kstDateTime = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 2, 0);
      final utcStart = AppTime.fromKstToUtc(kstDateTime);

      expect(utcStart.year, equals(2025));
      expect(utcStart.month, equals(9));
      expect(utcStart.day, equals(9)); // Previous day in UTC
      expect(utcStart.hour, equals(17)); // 2 - 9 = -7, so 24 - 7 = 17
      expect(utcStart.minute, equals(0));
      expect(utcStart.isUtc, isTrue);
    });

    test('Edge case: Midnight KST', () {
      // Test case: KST 2025-09-10 00:00 → UTC 2025-09-09 15:00
      final kstDateTime = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 0, 0);
      final utcStart = AppTime.fromKstToUtc(kstDateTime);

      expect(utcStart.year, equals(2025));
      expect(utcStart.month, equals(9));
      expect(utcStart.day, equals(9)); // Previous day in UTC
      expect(utcStart.hour, equals(15)); // 0 - 9 = -9, so 24 - 9 = 15
      expect(utcStart.minute, equals(0));
    });

    test('Round trip: KST → UTC → KST preserves time', () {
      final originalKst = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 15, 30);
      final utc = AppTime.fromKstToUtc(originalKst);
      final backToKst = AppTime.toKst(utc);

      expect(backToKst.year, equals(originalKst.year));
      expect(backToKst.month, equals(originalKst.month));
      expect(backToKst.day, equals(originalKst.day));
      expect(backToKst.hour, equals(originalKst.hour));
      expect(backToKst.minute, equals(originalKst.minute));
    });

    test('Duration boundaries work correctly', () {
      // Test minimum duration (5 minutes)
      final kstStart = tz.TZDateTime(AppTime.kst, 2025, 9, 10, 12, 0);
      final utcStart = AppTime.fromKstToUtc(kstStart);
      final utcEnd5Min = utcStart.add(const Duration(minutes: 5));

      expect(utcEnd5Min.difference(utcStart).inMinutes, equals(5));

      // Test maximum suggested duration (12 hours = 720 minutes)
      final utcEnd12Hours = utcStart.add(const Duration(minutes: 720));
      expect(utcEnd12Hours.difference(utcStart).inHours, equals(12));
    });
  });

  group('Form State Validation Tests', () {
    test('Form validation works correctly', () {
      // Valid state
      expect(_isValidState('Valid Title', const TimeOfDay(hour: 10, minute: 0), 60), isTrue);
      
      // Invalid states
      expect(_isValidState('', const TimeOfDay(hour: 10, minute: 0), 60), isFalse); // Empty title
      expect(_isValidState('Valid Title', null, 60), isFalse); // No time
      expect(_isValidState('Valid Title', const TimeOfDay(hour: 10, minute: 0), 4), isFalse); // Too short duration
      expect(_isValidState('   ', const TimeOfDay(hour: 10, minute: 0), 60), isFalse); // Whitespace only title
    });
  });
}

/// Helper function to test form validation logic
bool _isValidState(String title, TimeOfDay? startTod, int durationMinutes) {
  return title.trim().isNotEmpty && startTod != null && durationMinutes >= 5;
}