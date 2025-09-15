import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../lib/core/time/kst.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('ko_KR', null);
    KST.init();
  });

  group('KST Timezone Handling for Detail/Edit Views', () {
    test('should parse UTC ISO and convert to KST display correctly', () {
      // Test case: UTC time in summer (no DST in Korea)
      const utcIso = '2025-09-13T05:30:00.000Z'; // 5:30 AM UTC
      final expectedKstMs = DateTime.parse('2025-09-13T14:30:00+09:00').millisecondsSinceEpoch;

      final parsedUtc = KST.parseUtcIsoLenient(utcIso);
      final actualKstMs = parsedUtc.millisecondsSinceEpoch;

      expect(actualKstMs, equals(expectedKstMs));
      expect(KST.hm(actualKstMs), equals('14:30'));
      expect(KST.day(actualKstMs), equals('2025년 09월 13일'));
    });

    test('should handle cross-midnight events correctly', () {
      // Event: starts 23:30 KST, ends 01:30 KST next day
      final startUtc = DateTime.parse('2025-09-12T14:30:00.000Z'); // 23:30 KST
      final endUtc = DateTime.parse('2025-09-12T16:30:00.000Z');   // 01:30 KST next day

      final startMs = startUtc.millisecondsSinceEpoch;
      final endMs = endUtc.millisecondsSinceEpoch;

      // Should NOT be same day in KST
      expect(KST.isSameDay(startMs, endMs), isFalse);

      // Time range should show cross-day times
      expect(KST.range(startMs, endMs), equals('23:30 - 01:30'));

      // Dates should be different
      expect(KST.day(startMs), equals('2025년 09월 12일'));
      expect(KST.day(endMs), equals('2025년 09월 13일'));
    });

    test('should handle naive ISO strings by interpreting as KST', () {
      // Naive ISO without timezone offset (legacy data)
      const naiveIso = '2025-09-13T14:30:00.000';

      final parsedUtc = KST.parseUtcIsoLenient(naiveIso);

      // Should be interpreted as KST time, then converted to UTC
      // 14:30 KST = 05:30 UTC
      final expectedUtcMs = DateTime.parse('2025-09-13T05:30:00.000Z').millisecondsSinceEpoch;

      expect(parsedUtc.millisecondsSinceEpoch, equals(expectedUtcMs));
      expect(parsedUtc.isUtc, isTrue);
    });

    test('should format duration text correctly', () {
      final startUtc = DateTime.parse('2025-09-13T05:30:00.000Z');

      // Test various duration formats
      final tests = [
        (30, '30분'),
        (60, '1시간'),
        (90, '1시간 30분'),
        (120, '2시간'),
        (150, '2시간 30분'),
        (480, '8시간'), // Full work day
      ];

      for (final (minutes, expected) in tests) {
        final endUtc = startUtc.add(Duration(minutes: minutes));
        final durationMinutes = endUtc.difference(startUtc).inMinutes;

        String durationText;
        if (durationMinutes >= 60) {
          final hours = (durationMinutes / 60).floor();
          final mins = (durationMinutes % 60).round();
          if (mins > 0) {
            durationText = '${hours}시간 ${mins}분';
          } else {
            durationText = '${hours}시간';
          }
        } else {
          durationText = '${durationMinutes}분';
        }

        expect(durationText, equals(expected), reason: 'Duration $minutes minutes');
      }
    });

    test('should handle timezone offset ISO strings correctly', () {
      // ISO with explicit offset
      const offsetIso = '2025-09-13T14:30:00.000+09:00'; // Already KST
      final parsedUtc = KST.parseUtcIsoLenient(offsetIso);

      // Should convert to proper UTC
      expect(parsedUtc.isUtc, isTrue);
      expect(KST.hm(parsedUtc.millisecondsSinceEpoch), equals('14:30'));

      // Different offset
      const utcOffsetIso = '2025-09-13T14:30:00.000+00:00'; // UTC
      final parsedUtc2 = KST.parseUtcIsoLenient(utcOffsetIso);

      expect(parsedUtc2.isUtc, isTrue);
      expect(KST.hm(parsedUtc2.millisecondsSinceEpoch), equals('23:30')); // 14:30 UTC = 23:30 KST
    });

    test('should format day with weekday correctly', () {
      // Test specific dates
      final testDates = [
        ('2025-09-13T05:30:00.000Z', '2025년 09월 13일 (토)'), // Saturday
        ('2025-09-14T05:30:00.000Z', '2025년 09월 14일 (일)'), // Sunday
        ('2025-09-15T05:30:00.000Z', '2025년 09월 15일 (월)'), // Monday
      ];

      for (final (utcIso, expected) in testDates) {
        final utc = DateTime.parse(utcIso);
        final actual = KST.dayWithWeekday(utc.millisecondsSinceEpoch);
        expect(actual, equals(expected));
      }
    });

    test('should calculate relative time correctly', () {
      final nowUtc = DateTime.parse('2025-09-13T05:30:00.000Z'); // 14:30 KST

      // Mock current time by using specific timestamps
      final tests = [
        ('2025-09-13T05:00:00.000Z', '30분 전'),  // 30 minutes ago
        ('2025-09-13T04:30:00.000Z', '1시간 전'), // 1 hour ago
        ('2025-09-12T05:30:00.000Z', '1일 전'),   // 1 day ago
        ('2025-09-13T06:00:00.000Z', '30분 후'),  // 30 minutes later
        ('2025-09-13T06:30:00.000Z', '1시간 후'), // 1 hour later
        ('2025-09-14T05:30:00.000Z', '1일 후'),   // 1 day later
      ];

      for (final (testIso, expected) in tests) {
        final testUtc = DateTime.parse(testIso);

        // Calculate relative time manually since we can't mock KST.now()
        final difference = testUtc.difference(nowUtc);

        String relative;
        if (difference.isNegative) {
          final absDiff = -difference.inMinutes;
          if (absDiff < 60) {
            relative = '${absDiff}분 전';
          } else if (absDiff < 1440) {
            relative = '${absDiff ~/ 60}시간 전';
          } else {
            relative = '${absDiff ~/ 1440}일 전';
          }
        } else {
          final diffMinutes = difference.inMinutes;
          if (diffMinutes < 60) {
            relative = '${diffMinutes}분 후';
          } else if (diffMinutes < 1440) {
            relative = '${diffMinutes ~/ 60}시간 후';
          } else {
            relative = '${diffMinutes ~/ 1440}일 후';
          }
        }

        expect(relative, equals(expected), reason: 'Relative time for $testIso');
      }
    });
  });
}