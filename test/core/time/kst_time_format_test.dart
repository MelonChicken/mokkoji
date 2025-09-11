import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mokkoji_app/core/time/kst.dart';

void main() {
  group('KST Time Format Tests', () {
    setUpAll(() async {
      // Initialize locale data for Korean formatting
      await initializeDateFormatting('ko_KR', null);
      // Initialize KST for all tests
      KST.init();
    });

    group('Basic formatting', () {
      test('should format KST day correctly', () {
        // Test various dates to ensure consistency
        final testCases = [
          (DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch, '2025년 01월 15일'),
          (DateTime(2025, 12, 31, 23, 59).millisecondsSinceEpoch, '2025년 12월 31일'),
          (DateTime(2025, 6, 1, 0, 0).millisecondsSinceEpoch, '2025년 06월 01일'),
        ];

        for (final (ms, expected) in testCases) {
          expect(KST.day(ms), expected, reason: 'Failed for timestamp $ms');
        }
      });

      test('should format KST time correctly', () {
        final testCases = [
          (DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch, '14:30'),
          (DateTime(2025, 1, 15, 0, 0).millisecondsSinceEpoch, '00:00'),
          (DateTime(2025, 1, 15, 23, 59).millisecondsSinceEpoch, '23:59'),
          (DateTime(2025, 1, 15, 9, 5).millisecondsSinceEpoch, '09:05'),
        ];

        for (final (ms, expected) in testCases) {
          expect(KST.hm(ms), expected, reason: 'Failed for timestamp $ms');
        }
      });

      test('should format day with weekday correctly', () {
        // January 15, 2025 is a Wednesday
        final ms = DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch;
        expect(KST.dayWithWeekday(ms), '2025년 01월 15일 (수)');
      });

      test('should format detailed datetime correctly', () {
        final ms = DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch;
        expect(KST.dayTime(ms), '2025년 01월 15일 14:30');
      });
    });

    group('Time range formatting', () {
      test('should format single time range', () {
        final startMs = DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch;
        expect(KST.range(startMs, null), '14:30');
      });

      test('should format time range with start and end', () {
        final startMs = DateTime(2025, 1, 15, 14, 30).millisecondsSinceEpoch;
        final endMs = DateTime(2025, 1, 15, 16, 45).millisecondsSinceEpoch;
        expect(KST.range(startMs, endMs), '14:30 - 16:45');
      });
    });

    group('ISO string compatibility helpers', () {
      test('should convert ISO string to KST day format', () {
        final testCases = [
          ('2025-01-15T05:30:00.000Z', '2025년 01월 15일'), // UTC 5:30 = KST 14:30
          ('2025-12-31T14:59:00.000Z', '2025년 12월 31일'), // UTC 14:59 = KST 23:59
          ('2025-06-01T15:00:00.000Z', '2025년 06월 02일'), // UTC 15:00 = KST next day 00:00
        ];

        for (final (iso, expected) in testCases) {
          expect(KST.dayFromIso(iso), expected, reason: 'Failed for ISO: $iso');
        }
      });

      test('should convert ISO string to KST time format', () {
        final testCases = [
          ('2025-01-15T05:30:00.000Z', '14:30'), // UTC 5:30 = KST 14:30
          ('2025-01-15T15:00:00.000Z', '00:00'), // UTC 15:00 = KST next day 00:00
          ('2025-01-15T14:59:59.999Z', '23:59'), // UTC 14:59:59 = KST 23:59:59 (rounded down)
        ];

        for (final (iso, expected) in testCases) {
          expect(KST.hmFromIso(iso), expected, reason: 'Failed for ISO: $iso');
        }
      });

      test('should format ISO range correctly', () {
        final startIso = '2025-01-15T05:30:00.000Z'; // KST 14:30
        final endIso = '2025-01-15T07:45:00.000Z';   // KST 16:45
        expect(KST.rangeFromIso(startIso, endIso), '14:30 - 16:45');

        expect(KST.rangeFromIso(startIso, null), '14:30');
      });
    });

    group('Timezone conversion edge cases', () {
      test('should handle cross-midnight events correctly', () {
        // UTC date that becomes next day in KST
        final utcMs = DateTime.utc(2025, 1, 15, 15, 30).millisecondsSinceEpoch; // UTC 15:30
        expect(KST.day(utcMs), '2025년 01월 16일'); // Should be next day in KST
        expect(KST.hm(utcMs), '00:30'); // Should be 00:30 KST
      });

      test('should handle daylight saving time periods', () {
        // Korea doesn't have DST, but test around typical DST periods
        final springMs = DateTime.utc(2025, 3, 15, 5, 30).millisecondsSinceEpoch;
        final fallMs = DateTime.utc(2025, 11, 15, 5, 30).millisecondsSinceEpoch;
        
        expect(KST.hm(springMs), '14:30'); // Always UTC+9, no DST
        expect(KST.hm(fallMs), '14:30');   // Always UTC+9, no DST
      });
    });

    group('Day boundary calculations', () {
      test('should calculate start of day correctly in UTC', () {
        // Test KST midnight should be 15:00 UTC previous day
        final kstNoonMs = DateTime.utc(2025, 1, 15, 3, 0).millisecondsSinceEpoch; // UTC 03:00 = KST 12:00
        final startOfDayUtcMs = KST.startOfDay(kstNoonMs);
        final startOfDayUtc = DateTime.fromMillisecondsSinceEpoch(startOfDayUtcMs, isUtc: true);
        
        expect(startOfDayUtc.year, 2025);
        expect(startOfDayUtc.month, 1);
        expect(startOfDayUtc.day, 14); // Previous day in UTC
        expect(startOfDayUtc.hour, 15); // 15:00 UTC = 00:00 KST
        expect(startOfDayUtc.minute, 0);
      });

      test('should calculate end of day correctly in UTC', () {
        final kstNoonMs = DateTime.utc(2025, 1, 15, 3, 0).millisecondsSinceEpoch; // UTC 03:00 = KST 12:00
        final endOfDayUtcMs = KST.endOfDay(kstNoonMs);
        final endOfDayUtc = DateTime.fromMillisecondsSinceEpoch(endOfDayUtcMs, isUtc: true);
        
        expect(endOfDayUtc.year, 2025);
        expect(endOfDayUtc.month, 1);
        expect(endOfDayUtc.day, 15); // Same day in UTC  
        expect(endOfDayUtc.hour, 15); // 15:00 UTC = 00:00 KST next day
        expect(endOfDayUtc.minute, 0);
      });

      test('should identify same KST day correctly', () {
        final kstMorningMs = DateTime.utc(2025, 1, 14, 16, 0).millisecondsSinceEpoch; // UTC 16:00 = KST 01:00 Jan 15
        final kstEveningMs = DateTime.utc(2025, 1, 15, 14, 0).millisecondsSinceEpoch; // UTC 14:00 = KST 23:00 Jan 15
        final nextDayMs = DateTime.utc(2025, 1, 15, 16, 0).millisecondsSinceEpoch;    // UTC 16:00 = KST 01:00 Jan 16
        
        expect(KST.isSameDay(kstMorningMs, kstEveningMs), true);
        expect(KST.isSameDay(kstEveningMs, nextDayMs), false);
      });
    });

    group('Relative time formatting', () {
      test('should format relative time for past events', () {
        final now = DateTime.now();
        
        // 30 minutes ago
        final thirtyMinAgo = now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch;
        expect(KST.relative(thirtyMinAgo), '30분 전');
        
        // 2 hours ago
        final twoHoursAgo = now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
        expect(KST.relative(twoHoursAgo), '2시간 전');
        
        // 1 day ago
        final oneDayAgo = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;
        expect(KST.relative(oneDayAgo), '1일 전');
      });

      test('should format relative time for future events', () {
        final now = DateTime.now();
        
        // 45 minutes later (allow for 44-45 due to timing)
        final fortyFiveMinLater = now.add(const Duration(minutes: 45)).millisecondsSinceEpoch;
        final result = KST.relative(fortyFiveMinLater);
        expect(result, anyOf('44분 후', '45분 후'));
        
        // 3 hours later (allow for 2-3 due to timing)
        final threeHoursLater = now.add(const Duration(hours: 3)).millisecondsSinceEpoch;
        final threeHourResult = KST.relative(threeHoursLater);
        expect(threeHourResult, anyOf('2시간 후', '3시간 후'));
        
        // 2 days later (allow for 1-2 due to timing)
        final twoDaysLater = now.add(const Duration(days: 2)).millisecondsSinceEpoch;
        final twoDayResult = KST.relative(twoDaysLater);
        expect(twoDayResult, anyOf('1일 후', '2일 후'));
      });
    });

    group('KST input helpers', () {
      test('should convert KST input to UTC milliseconds', () {
        // KST 2025-01-15 14:30:00 should be UTC 2025-01-15 05:30:00
        final utcMs = KST.toUtcMs(
          year: 2025,
          month: 1,
          day: 15,
          hour: 14,
          minute: 30,
        );
        
        final utcDateTime = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
        expect(utcDateTime.year, 2025);
        expect(utcDateTime.month, 1);
        expect(utcDateTime.day, 15);
        expect(utcDateTime.hour, 5); // 14 - 9 = 5
        expect(utcDateTime.minute, 30);
      });

      test('should handle KST midnight to UTC conversion', () {
        // KST midnight should be 15:00 UTC previous day
        final utcMs = KST.toUtcMs(
          year: 2025,
          month: 1,
          day: 15,
          hour: 0,
          minute: 0,
        );
        
        final utcDateTime = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
        expect(utcDateTime.year, 2025);
        expect(utcDateTime.month, 1);
        expect(utcDateTime.day, 14); // Previous day
        expect(utcDateTime.hour, 15); // 0 - 9 + 24 = 15
        expect(utcDateTime.minute, 0);
      });
    });

    group('Initialization and state', () {
      test('should report initialization status correctly', () {
        expect(KST.isInitialized, true);
        expect(KST.timezoneInfo, 'Asia/Seoul');
      });

      test('should handle multiple init calls gracefully', () {
        // Should not throw or cause issues
        expect(() => KST.init(), returnsNormally);
        expect(() => KST.init(), returnsNormally);
        expect(KST.isInitialized, true);
      });
    });

    group('Error handling', () {
      test('should handle invalid ISO strings gracefully', () {
        expect(() => KST.dayFromIso('invalid-iso'), throwsA(isA<FormatException>()));
        expect(() => KST.hmFromIso('not-a-date'), throwsA(isA<FormatException>()));
      });

      test('should validate UTC requirement for ISO strings', () {
        // Non-UTC ISO strings should fail assertion
        expect(() => KST.dayFromIso('2025-01-15T14:30:00'), throwsA(isA<AssertionError>()));
      });
    });

    group('Integration with existing system', () {
      test('should maintain consistency with existing time formats', () {
        // Test that KST helpers produce same results as replaced DateFormat calls
        final testUtcMs = DateTime.utc(2025, 1, 15, 5, 30).millisecondsSinceEpoch; // UTC 05:30 = KST 14:30
        
        // Day format should match Korean locale
        expect(KST.day(testUtcMs), '2025년 01월 15일');
        
        // Time format should match HH:mm
        expect(KST.hm(testUtcMs), '14:30');
        
        // Weekday should be in Korean
        expect(KST.dayWithWeekday(testUtcMs), contains('(수)')); // Wednesday
      });

      test('should handle EventEntity ISO string format', () {
        // Test with typical EventEntity startDt/endDt format
        final startIso = '2025-01-15T05:30:00.000Z';
        final endIso = '2025-01-15T07:45:00.000Z';
        
        expect(KST.dayFromIso(startIso), '2025년 01월 15일');
        expect(KST.rangeFromIso(startIso, endIso), '14:30 - 16:45');
      });
    });
  });
}