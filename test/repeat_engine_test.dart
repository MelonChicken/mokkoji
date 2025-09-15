import 'package:flutter_test/flutter_test.dart';
import '../lib/core/time/kst.dart';
import '../lib/features/events/data/event_entity.dart';
import '../lib/domain/repeat/repeat_engine.dart';

void main() {
  setUpAll(() {
    KST.init();
  });

  group('RepeatEngine', () {
    test('should generate daily occurrences correctly', () {
      // Create a daily repeating event starting at 2025-09-14 09:00 KST
      final startKst = DateTime(2025, 9, 14, 9, 0);
      final startUtc = KST.toUtcIso(startKst);
      final endUtc = KST.toUtcIso(startKst.add(Duration(hours: 1)));

      final master = EventEntity(
        id: 'test-daily',
        title: 'Daily Meeting',
        startDt: startUtc,
        endDt: endUtc,
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;INTERVAL=1',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Generate occurrences for 5 days
      final fromKst = DateTime(2025, 9, 14);
      final toKst = DateTime(2025, 9, 19);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      // Should have 5 occurrences (14th, 15th, 16th, 17th, 18th)
      expect(occurrences.length, equals(5));

      // Check first occurrence
      expect(occurrences[0].seq, equals(0));
      expect(occurrences[0].startKst.day, equals(14));
      expect(occurrences[0].startKst.hour, equals(9));

      // Check last occurrence
      expect(occurrences[4].seq, equals(4));
      expect(occurrences[4].startKst.day, equals(18));
      expect(occurrences[4].startKst.hour, equals(9));
    });

    test('should generate weekly occurrences with specific weekdays', () {
      final startKst = DateTime(2025, 9, 15, 14, 30); // Monday
      final startUtc = KST.toUtcIso(startKst);
      final endUtc = KST.toUtcIso(startKst.add(Duration(minutes: 90)));

      final master = EventEntity(
        id: 'test-weekly',
        title: 'Weekly Meeting',
        startDt: startUtc,
        endDt: endUtc,
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 90,
        rrule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR', // Mon, Wed, Fri
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Generate occurrences for 2 weeks
      final fromKst = DateTime(2025, 9, 15);
      final toKst = DateTime(2025, 9, 29);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      // Should have 6 occurrences (Mon/Wed/Fri for 2 weeks)
      expect(occurrences.length, equals(6));

      // Check weekdays
      final weekdays = occurrences.map((o) => o.startKst.weekday).toSet();
      expect(weekdays, equals({DateTime.monday, DateTime.wednesday, DateTime.friday}));
    });

    test('should respect COUNT end condition', () {
      final startKst = DateTime(2025, 9, 14, 10, 0);
      final startUtc = KST.toUtcIso(startKst);

      final master = EventEntity(
        id: 'test-count',
        title: 'Limited Repeat',
        startDt: startUtc,
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;COUNT=3',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Generate occurrences for a wide range
      final fromKst = DateTime(2025, 9, 14);
      final toKst = DateTime(2025, 9, 25);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      // Should have exactly 3 occurrences despite wide range
      expect(occurrences.length, equals(3));
      expect(occurrences[0].startKst.day, equals(14));
      expect(occurrences[1].startKst.day, equals(15));
      expect(occurrences[2].startKst.day, equals(16));
    });

    test('should respect UNTIL end condition', () {
      final startKst = DateTime(2025, 9, 14, 15, 0);
      final startUtc = KST.toUtcIso(startKst);

      final master = EventEntity(
        id: 'test-until',
        title: 'Until End',
        startDt: startUtc,
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: 'FREQ=DAILY;UNTIL=20250916T235959Z', // Until Sep 16
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      final fromKst = DateTime(2025, 9, 14);
      final toKst = DateTime(2025, 9, 20);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      // Should stop at Sep 16 (3 occurrences: 14th, 15th, 16th)
      expect(occurrences.length, equals(3));
      expect(occurrences.last.startKst.day, lessThanOrEqualTo(16));
    });

    test('should handle monthly recurrence correctly', () {
      // Start on the 15th of the month
      final startKst = DateTime(2025, 9, 15, 11, 0);
      final startUtc = KST.toUtcIso(startKst);

      final master = EventEntity(
        id: 'test-monthly',
        title: 'Monthly Meeting',
        startDt: startUtc,
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 2))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 120,
        rrule: 'FREQ=MONTHLY;INTERVAL=1',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Generate for 3 months
      final fromKst = DateTime(2025, 9, 1);
      final toKst = DateTime(2025, 12, 31);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      // Should have 4 occurrences (Sep, Oct, Nov, Dec)
      expect(occurrences.length, equals(4));

      // All should be on the 15th
      for (final occ in occurrences) {
        expect(occ.startKst.day, equals(15));
        expect(occ.startKst.hour, equals(11));
      }

      // Check months
      expect(occurrences[0].startKst.month, equals(9));
      expect(occurrences[1].startKst.month, equals(10));
      expect(occurrences[2].startKst.month, equals(11));
      expect(occurrences[3].startKst.month, equals(12));
    });

    test('should handle cross-day events properly', () {
      // Event from 23:30 to 01:00 next day (90 minutes)
      final startKst = DateTime(2025, 9, 14, 23, 30);
      final startUtc = KST.toUtcIso(startKst);
      final endUtc = KST.toUtcIso(startKst.add(Duration(minutes: 90)));

      final master = EventEntity(
        id: 'test-cross-day',
        title: 'Late Night Event',
        startDt: startUtc,
        endDt: endUtc,
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 90,
        rrule: 'FREQ=DAILY;COUNT=3',
        tzid: 'Asia/Seoul',
        updatedAt: DateTime.now().toIso8601String(),
      );

      final fromKst = DateTime(2025, 9, 14);
      final toKst = DateTime(2025, 9, 17);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      expect(occurrences.length, equals(3));

      // All should start at 23:30
      for (final occ in occurrences) {
        expect(occ.startKst.hour, equals(23));
        expect(occ.startKst.minute, equals(30));
        // End should be 01:00 next day
        expect(occ.endKst.hour, equals(1));
        expect(occ.endKst.minute, equals(0));
        expect(occ.endKst.day, equals(occ.startKst.day + 1));
      }
    });

    test('should return empty list for non-repeating events', () {
      final startKst = DateTime(2025, 9, 14, 12, 0);
      final startUtc = KST.toUtcIso(startKst);

      final master = EventEntity(
        id: 'test-no-repeat',
        title: 'Single Event',
        startDt: startUtc,
        endDt: KST.toUtcIso(startKst.add(Duration(hours: 1))),
        allDay: false,
        sourcePlatform: 'test',
        durationMin: 60,
        rrule: null, // No repeat rule
        updatedAt: DateTime.now().toIso8601String(),
      );

      final fromKst = DateTime(2025, 9, 14);
      final toKst = DateTime(2025, 9, 20);

      final occurrences = RepeatEngine.generate(master, fromKst, toKst);

      expect(occurrences.isEmpty, isTrue);
    });
  });
}