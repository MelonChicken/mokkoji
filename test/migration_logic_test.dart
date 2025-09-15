import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/date_symbol_data_local.dart';
import '../lib/core/time/kst.dart';
import '../lib/core/time/app_time.dart';

void main() {
  group('Migration Logic Tests', () {
    setUpAll(() async {
      tz_data.initializeTimeZones();
      await initializeDateFormatting('ko_KR', null);
      KST.init();
      await AppTime.init();
    });

    group('KST.parseUtcIsoLenient for migration', () {
      test('correctly handles UTC timestamps', () {
        const utcIso = '2025-09-10T02:00:00.000Z';
        final result = KST.parseUtcIsoLenient(utcIso);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals(utcIso));
      });

      test('converts KST offset to UTC', () {
        const kstIso = '2025-09-10T11:00:00.000+09:00';
        final result = KST.parseUtcIsoLenient(kstIso);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals('2025-09-10T02:00:00.000Z'));
      });

      test('converts naive ISO as KST to UTC', () {
        const naiveIso = '2025-09-10T11:00:00.000';
        final result = KST.parseUtcIsoLenient(naiveIso);
        
        expect(result.isUtc, isTrue);
        expect(result.toIso8601String(), equals('2025-09-10T02:00:00.000Z'));
      });

      test('handles various timezone formats', () {
        final testCases = [
          ('2025-09-10T11:00:00+09:00', '2025-09-10T02:00:00.000Z'),
          ('2025-09-10T11:00:00+0900', '2025-09-10T02:00:00.000Z'),
          ('2025-09-10T05:00:00-05:00', '2025-09-10T10:00:00.000Z'),
          ('2025-09-10T11:00:00.123+09:00', '2025-09-10T02:00:00.123Z'),
        ];

        for (final (input, expected) in testCases) {
          final result = KST.parseUtcIsoLenient(input);
          expect(result.isUtc, isTrue, reason: 'Input: $input');
          expect(result.toIso8601String(), equals(expected), reason: 'Input: $input');
        }
      });

      test('throws on malformed dates', () {
        final malformedCases = [
          'not-a-date',
          '2025-02-30T10:00:00.000Z',
          '2025-09-10T25:00:00.000Z',
          '',
        ];

        for (final iso in malformedCases) {
          expect(() => KST.parseUtcIsoLenient(iso), throwsA(isA<FormatException>()),
                 reason: 'Should throw for: $iso');
        }
      });
    });

    group('Migration scenarios simulation', () {
      test('simulates database migration scenario', () {
        // Simulate events that would be found in legacy database
        final legacyEvents = [
          {
            'id': 'event1',
            'title': 'Already UTC Event',
            'start_dt': '2025-09-10T02:00:00.000Z',
            'end_dt': '2025-09-10T03:00:00.000Z',
          },
          {
            'id': 'event2',
            'title': 'KST Offset Event',
            'start_dt': '2025-09-10T11:00:00.000+09:00',
            'end_dt': '2025-09-10T12:00:00.000+09:00',
          },
          {
            'id': 'event3',
            'title': 'Naive ISO Event',
            'start_dt': '2025-09-10T11:00:00.000',
            'end_dt': '2025-09-10T12:00:00.000',
          },
          {
            'id': 'event4',
            'title': 'Malformed Event',
            'start_dt': 'invalid-date',
            'end_dt': '2025-99-99T99:99:99.999Z',
          },
        ];

        final migrationResults = <String, Map<String, dynamic>>{};

        // Simulate migration process
        for (final event in legacyEvents) {
          final id = event['id'] as String;
          final startDt = event['start_dt'] as String;
          final endDt = event['end_dt'] as String;

          String? fixedStartDt;
          String? fixedEndDt;
          int skipCount = 0;

          // Try to fix start_dt
          try {
            final utc = KST.parseUtcIsoLenient(startDt);
            final fixedIso = utc.toIso8601String();
            if (fixedIso != startDt) {
              fixedStartDt = fixedIso;
            }
          } catch (e) {
            skipCount++;
          }

          // Try to fix end_dt
          try {
            final utc = KST.parseUtcIsoLenient(endDt);
            final fixedIso = utc.toIso8601String();
            if (fixedIso != endDt) {
              fixedEndDt = fixedIso;
            }
          } catch (e) {
            skipCount++;
          }

          migrationResults[id] = {
            'original_start': startDt,
            'original_end': endDt,
            'fixed_start': fixedStartDt ?? startDt,
            'fixed_end': fixedEndDt ?? endDt,
            'skip_count': skipCount,
          };
        }

        // Verify results
        expect(migrationResults['event1']!['fixed_start'], equals('2025-09-10T02:00:00.000Z'));
        expect(migrationResults['event1']!['skip_count'], equals(0));

        expect(migrationResults['event2']!['fixed_start'], equals('2025-09-10T02:00:00.000Z'));
        expect(migrationResults['event2']!['fixed_end'], equals('2025-09-10T03:00:00.000Z'));
        expect(migrationResults['event2']!['skip_count'], equals(0));

        expect(migrationResults['event3']!['fixed_start'], equals('2025-09-10T02:00:00.000Z'));
        expect(migrationResults['event3']!['fixed_end'], equals('2025-09-10T03:00:00.000Z'));
        expect(migrationResults['event3']!['skip_count'], equals(0));

        // Malformed event should be skipped
        expect(migrationResults['event4']!['fixed_start'], equals('invalid-date'));
        expect(migrationResults['event4']!['skip_count'], equals(2));
      });
    });

    group('Edge cases', () {
      test('handles cross-midnight events', () {
        // Event that spans midnight in KST
        const startIso = '2025-09-10T14:30:00.000Z'; // 23:30 KST
        const endIso = '2025-09-10T16:30:00.000Z';   // 01:30 next day KST

        final startResult = KST.parseUtcIsoLenient(startIso);
        final endResult = KST.parseUtcIsoLenient(endIso);

        expect(startResult.isUtc, isTrue);
        expect(endResult.isUtc, isTrue);
        expect(startResult.toIso8601String(), equals(startIso));
        expect(endResult.toIso8601String(), equals(endIso));
      });

      test('handles same timestamp in different formats', () {
        // All represent the same moment in time
        final equivalentTimestamps = [
          '2025-09-10T02:00:00.000Z',
          '2025-09-10T11:00:00.000+09:00',
          '2025-09-10T11:00:00.000', // Naive, interpreted as KST
        ];

        final results = equivalentTimestamps.map(KST.parseUtcIsoLenient).toList();
        
        // All should result in the same UTC milliseconds
        for (int i = 1; i < results.length; i++) {
          expect(results[i].millisecondsSinceEpoch, 
                 equals(results[0].millisecondsSinceEpoch),
                 reason: 'Timestamp ${equivalentTimestamps[i]} should equal ${equivalentTimestamps[0]}');
        }
      });
    });
  });
}