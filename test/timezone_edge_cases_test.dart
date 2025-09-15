import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import '../lib/core/time/kst.dart';
import '../lib/core/time/app_time.dart';

void main() {
  group('Timezone Edge Cases and UTC Enforcement', () {
    setUpAll(() async {
      tz_data.initializeTimeZones();
      await initializeDateFormatting('ko_KR', null);
      KST.init();
      await AppTime.init();
    });

    group('KST.parseUtcIsoLenient', () {
      test('handles UTC ISO with Z suffix', () {
        const isoUtc = '2025-09-10T02:00:00.000Z';
        final result = KST.parseUtcIsoLenient(isoUtc);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals(isoUtc));
      });

      test('handles KST offset ISO (+09:00)', () {
        const isoKst = '2025-09-10T11:00:00.000+09:00';  // 11AM KST
        final result = KST.parseUtcIsoLenient(isoKst);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals('2025-09-10T02:00:00.000Z')); // 2AM UTC
      });

      test('handles naive ISO (no timezone) as KST', () {
        const isoNaive = '2025-09-10T11:00:00.000';  // Assume KST
        final result = KST.parseUtcIsoLenient(isoNaive);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals('2025-09-10T02:00:00.000Z')); // 2AM UTC
      });

      test('handles various offset formats', () {
        final testCases = [
          ('2025-09-10T11:00:00+09:00', '2025-09-10T02:00:00.000Z'),   // +09:00
          ('2025-09-10T11:00:00+0900', '2025-09-10T02:00:00.000Z'),    // +0900
          ('2025-09-10T05:00:00-05:00', '2025-09-10T10:00:00.000Z'),   // EST
          ('2025-09-10T11:00:00.123+09:00', '2025-09-10T02:00:00.123Z'), // with millis
        ];

        for (final (input, expected) in testCases) {
          final result = KST.parseUtcIsoLenient(input);
          expect(result.isUtc, isTrue, reason: 'Input: $input');
          expect(result.toIso8601String(), equals(expected), reason: 'Input: $input');
        }
      });
    });

    group('KST formatting with lenient parser', () {
      test('dayFromIso handles non-UTC input without crash', () {
        const testCases = [
          '2025-09-10T02:00:00.000Z',        // UTC
          '2025-09-10T11:00:00.000+09:00',   // KST offset
          '2025-09-10T11:00:00.000',         // Naive (treated as KST)
        ];

        for (final iso in testCases) {
          expect(() => KST.dayFromIso(iso), returnsNormally, reason: 'ISO: $iso');
          final result = KST.dayFromIso(iso);
          expect(result, contains('2025년 09월 10일'), reason: 'ISO: $iso');
        }
      });

      test('hmFromIso handles non-UTC input without crash', () {
        final testCases = [
          ('2025-09-10T02:00:00.000Z', '11:00'),        // UTC 2AM → KST 11AM
          ('2025-09-10T11:00:00.000+09:00', '11:00'),   // KST 11AM → KST 11AM
          ('2025-09-10T11:00:00.000', '11:00'),         // Naive 11AM → KST 11AM
        ];

        for (final (iso, expectedTime) in testCases) {
          expect(() => KST.hmFromIso(iso), returnsNormally, reason: 'ISO: $iso');
          final result = KST.hmFromIso(iso);
          expect(result, equals(expectedTime), reason: 'ISO: $iso');
        }
      });

      test('rangeFromIso handles mixed timezone inputs', () {
        const startIso = '2025-09-10T11:00:00.000+09:00';  // KST offset
        const endIso = '2025-09-10T04:30:00.000Z';          // UTC

        expect(() => KST.rangeFromIso(startIso, endIso), returnsNormally);
        final result = KST.rangeFromIso(startIso, endIso);
        expect(result, equals('11:00 - 13:30')); // Both converted to KST
      });
    });

    group('Cross-midnight and boundary cases', () {
      test('handles events crossing midnight boundary', () {
        // Event: 23:30 KST → 01:30 next day KST
        const startIso = '2025-09-10T14:30:00.000Z';  // 23:30 KST
        const endIso = '2025-09-10T16:30:00.000Z';    // 01:30 next day KST

        expect(() {
          KST.dayFromIso(startIso);
          KST.dayFromIso(endIso);
          KST.rangeFromIso(startIso, endIso);
        }, returnsNormally);

        expect(KST.hmFromIso(startIso), equals('23:30'));
        expect(KST.hmFromIso(endIso), equals('01:30'));
      });

      test('handles DST transition edge cases', () {
        // Note: Korea doesn't use DST, but test various UTC offsets
        final testCases = [
          '2025-03-10T07:00:00.000Z',  // Various UTC times
          '2025-11-03T06:00:00.000Z',
          '2025-12-31T15:00:00.000Z',  // New Year's Eve
          '2025-01-01T15:00:00.000Z',  // New Year's Day
        ];

        for (final iso in testCases) {
          expect(() => KST.dayFromIso(iso), returnsNormally, reason: 'ISO: $iso');
          expect(() => KST.hmFromIso(iso), returnsNormally, reason: 'ISO: $iso');
        }
      });

      test('extreme timezone offsets', () {
        final extremeCases = [
          '2025-09-10T11:00:00+14:00',  // UTC+14 (Line Islands)
          '2025-09-10T11:00:00-12:00',  // UTC-12 (Baker Island)
          '2025-09-10T11:00:00+05:45',  // UTC+5:45 (Nepal)
          '2025-09-10T11:00:00-03:30',  // UTC-3:30 (Newfoundland)
        ];

        for (final iso in extremeCases) {
          expect(() => KST.parseUtcIsoLenient(iso), returnsNormally, reason: 'ISO: $iso');
          final result = KST.parseUtcIsoLenient(iso);
          expect(result.isUtc, isTrue, reason: 'ISO: $iso');
        }
      });
    });

    group('Error handling and malformed input', () {
      test('handles malformed ISO strings gracefully', () {
        final malformedCases = [
          'not-a-date',
          '2025-02-30T10:00:00.000Z',  // Invalid day
          '2025-09-10T25:00:00.000Z',  // Invalid hour
          '',                          // Empty string
        ];

        for (final iso in malformedCases) {
          expect(() => KST.parseUtcIsoLenient(iso), throwsA(isA<FormatException>()), 
                 reason: 'Should throw for malformed ISO: $iso');
        }
      });

      test('preserves microseconds precision', () {
        const isoWithMicros = '2025-09-10T11:00:00.123456+09:00';
        final result = KST.parseUtcIsoLenient(isoWithMicros);
        
        expect(result.isUtc, isTrue);
        // Note: DateTime.parse may not preserve full microsecond precision
        expect(result.millisecond, equals(123));
      });
    });

    group('Performance and edge case validation', () {
      test('consistent results for equivalent timestamps', () {
        // All of these represent the same moment in time
        final equivalentIsos = [
          '2025-09-10T02:00:00.000Z',      // UTC
          '2025-09-10T11:00:00.000+09:00', // KST with offset
          '2025-09-10T11:00:00.000',       // Naive (interpreted as KST)
        ];

        final results = equivalentIsos.map(KST.parseUtcIsoLenient).toList();
        
        // All should result in the same UTC timestamp
        for (int i = 1; i < results.length; i++) {
          expect(results[i].millisecondsSinceEpoch, 
                 equals(results[0].millisecondsSinceEpoch),
                 reason: 'ISO ${equivalentIsos[i]} should equal ${equivalentIsos[0]}');
        }

        // All should format to the same KST display
        final displayResults = equivalentIsos.map(KST.dayFromIso).toList();
        for (int i = 1; i < displayResults.length; i++) {
          expect(displayResults[i], equals(displayResults[0]),
                 reason: 'Display for ${equivalentIsos[i]} should equal ${equivalentIsos[0]}');
        }
      });

      test('year boundary transitions', () {
        final yearBoundaryCases = [
          '2024-12-31T23:59:59.999Z',  // Last moment of 2024 UTC
          '2025-01-01T00:00:00.000Z',  // First moment of 2025 UTC
          '2024-12-31T14:59:59.999Z',  // Last moment of 2024 KST (UTC)
          '2024-12-31T15:00:00.000Z',  // First moment of 2025 KST (UTC)
        ];

        for (final iso in yearBoundaryCases) {
          expect(() => KST.parseUtcIsoLenient(iso), returnsNormally, reason: 'ISO: $iso');
          expect(() => KST.dayFromIso(iso), returnsNormally, reason: 'ISO: $iso');
          
          final result = KST.parseUtcIsoLenient(iso);
          expect(result.isUtc, isTrue, reason: 'ISO: $iso');
        }
      });
    });
  });
}