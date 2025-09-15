import '../../features/events/data/event_entity.dart';
import '../../core/time/kst.dart';
import '../../core/recurrence/rrule_codec.dart';

/// Represents a single occurrence of a repeating event in KST
class OccurrenceKst {
  final DateTime startKst;
  final DateTime endKst;
  final int seq;

  const OccurrenceKst(this.startKst, this.endKst, this.seq);

  @override
  String toString() => 'Occurrence{seq: $seq, start: $startKst, end: $endKst}';
}

/// Engine for generating repeat occurrences in KST from event master records
/// Handles DAILY/WEEKLY/MONTHLY patterns with INTERVAL, BYDAY, UNTIL, and COUNT
class RepeatEngine {
  /// Generate occurrences for a repeating event within KST date range
  /// All calculations done in KST for proper date arithmetic
  static List<OccurrenceKst> generate(
    EventEntity master,
    DateTime fromKst,
    DateTime toKst,
  ) {
    // Parse repeat rule from RRULE field
    final repeatRule = RepeatRule.fromRRule(master.rrule);
    if (repeatRule == null || repeatRule.isNone) {
      return const [];
    }

    // Convert master event times from UTC to KST for calculations
    final startKst = KST.fromUtcIso(master.startDt);
    final endKst = master.endDt != null
        ? KST.fromUtcIso(master.endDt!)
        : startKst.add(Duration(minutes: master.durationMin));

    final duration = endKst.difference(startKst);

    // Parse exception dates from entity
    final exdates = _parseIsoList(master.exdateJson)
        .map(KST.fromUtcIso)
        .map(KST.atStartOfMinute)
        .toSet();

    final rdates = _parseIsoList(master.rdateJson)
        .map(KST.fromUtcIso)
        .map(KST.atStartOfMinute)
        .toSet();

    // Generate seed dates based on frequency
    final List<DateTime> seeds;
    switch (repeatRule.freq) {
      case RepeatFreq.daily:
        seeds = _generateDailySeeds(startKst, fromKst, toKst, repeatRule.interval);
        break;
      case RepeatFreq.weekly:
        seeds = _generateWeeklySeeds(
          startKst, fromKst, toKst, repeatRule.interval, repeatRule.byWeekday);
        break;
      case RepeatFreq.monthly:
        seeds = _generateMonthlySeeds(startKst, fromKst, toKst, repeatRule.interval);
        break;
      case RepeatFreq.none:
        return const [];
    }

    // Apply end conditions and exceptions
    final filteredSeeds = _applyEndTypeAndExceptions(
      startSeed: startKst,
      seeds: seeds,
      endType: repeatRule.endType,
      count: repeatRule.count,
      untilKst: repeatRule.untilKst,
      exdates: exdates,
      rdates: rdates,
    );

    // Convert to occurrences within the requested range
    final occurrences = <OccurrenceKst>[];
    var seq = 0;

    for (final seedStart in filteredSeeds) {
      final seedEnd = seedStart.add(duration);

      // Only include occurrences that overlap with the requested range
      if (seedEnd.isAfter(fromKst) && seedStart.isBefore(toKst)) {
        occurrences.add(OccurrenceKst(seedStart, seedEnd, seq));
      }
      seq++;
    }

    return occurrences;
  }

  /// Generate daily repeat seeds
  static List<DateTime> _generateDailySeeds(
    DateTime startKst,
    DateTime fromKst,
    DateTime toKst,
    int interval,
  ) {
    final seeds = <DateTime>[];

    // Start from the original start date
    var current = startKst;

    // Skip backwards to find the first seed within or before the range
    while (current.isAfter(fromKst)) {
      current = current.subtract(Duration(days: interval));
    }

    // Generate seeds from first occurrence to end of range
    while (current.isBefore(toKst)) {
      if (!current.isBefore(fromKst)) {
        seeds.add(current);
      }
      current = current.add(Duration(days: interval));
    }

    return seeds;
  }

  /// Generate weekly repeat seeds with specific weekdays
  static List<DateTime> _generateWeeklySeeds(
    DateTime startKst,
    DateTime fromKst,
    DateTime toKst,
    int interval,
    Set<int> byWeekday,
  ) {
    if (byWeekday.isEmpty) {
      // Default to the original weekday if none specified
      byWeekday = {startKst.weekday};
    }

    final seeds = <DateTime>[];

    // Find the Monday of the week containing startKst
    final startMonday = startKst.subtract(Duration(days: startKst.weekday - 1));

    // Calculate how many weeks back to go to cover the range
    final weeksBack = ((startMonday.difference(fromKst).inDays) / (7 * interval)).ceil() + 1;
    var current = startMonday.subtract(Duration(days: weeksBack * 7 * interval));

    while (current.isBefore(toKst)) {
      // For this week, add occurrences for selected weekdays
      for (final weekdayNum in byWeekday) {
        // weekdayNum: 1=Monday...7=Sunday, DateTime.weekday: 1=Monday...7=Sunday
        final occurrenceDate = current.add(Duration(days: weekdayNum - 1));

        if (occurrenceDate.isAfter(fromKst.subtract(const Duration(days: 1))) &&
            occurrenceDate.isBefore(toKst)) {
          // Preserve the original time from startKst
          final seedDateTime = DateTime(
            occurrenceDate.year,
            occurrenceDate.month,
            occurrenceDate.day,
            startKst.hour,
            startKst.minute,
            startKst.second,
          );

          // Only include if it's on or after the original start date
          if (!seedDateTime.isBefore(startKst)) {
            seeds.add(seedDateTime);
          }
        }
      }

      // Move to next interval week
      current = current.add(Duration(days: 7 * interval));
    }

    seeds.sort();
    return seeds;
  }

  /// Generate monthly repeat seeds
  static List<DateTime> _generateMonthlySeeds(
    DateTime startKst,
    DateTime fromKst,
    DateTime toKst,
    int interval,
  ) {
    final seeds = <DateTime>[];

    // Start from a month that could contain occurrences in our range
    var currentYear = fromKst.year;
    var currentMonth = fromKst.month;

    // Go back enough months to ensure we don't miss any occurrences
    final monthsBack = interval * 2;
    for (int i = 0; i < monthsBack; i++) {
      currentMonth -= interval;
      while (currentMonth <= 0) {
        currentMonth += 12;
        currentYear--;
      }
    }

    // Generate seeds
    while (currentYear < toKst.year + 1) {
      try {
        // Try to create the occurrence for this month
        final candidate = DateTime(
          currentYear,
          currentMonth,
          startKst.day,
          startKst.hour,
          startKst.minute,
          startKst.second,
        );

        // Check if this month actually has this day (e.g., Jan 31 → Feb 31 doesn't exist)
        if (candidate.month == currentMonth &&
            !candidate.isBefore(startKst) &&
            candidate.isBefore(toKst)) {
          seeds.add(candidate);
        }
      } catch (e) {
        // Invalid date (e.g., Feb 30), skip this occurrence
      }

      // Move to next interval month
      currentMonth += interval;
      while (currentMonth > 12) {
        currentMonth -= 12;
        currentYear++;
      }

      // Safety break
      if (currentYear > toKst.year + 2) break;
    }

    return seeds;
  }

  /// Apply end conditions and exception/additional dates
  static List<DateTime> _applyEndTypeAndExceptions({
    required DateTime startSeed,
    required List<DateTime> seeds,
    required RepeatEnd endType,
    int? count,
    DateTime? untilKst,
    required Set<DateTime> exdates,
    required Set<DateTime> rdates,
  }) {
    final result = <DateTime>[];

    // Sort seeds chronologically
    seeds.sort();

    // Apply count limitation first if specified
    List<DateTime> limitedSeeds = seeds;
    if (endType == RepeatEnd.count && count != null && count > 0) {
      limitedSeeds = seeds.take(count).toList();
    }

    // Apply until date limitation
    if (endType == RepeatEnd.until && untilKst != null) {
      limitedSeeds = limitedSeeds
          .where((seed) => !seed.isAfter(untilKst))
          .toList();
    }

    // Apply exceptions (exdates) - remove dates that match
    for (final seed in limitedSeeds) {
      final seedMinute = KST.atStartOfMinute(seed);
      if (!exdates.contains(seedMinute)) {
        result.add(seed);
      }
    }

    // Add additional dates (rdates)
    for (final rdate in rdates) {
      // Preserve time from original start, just change the date
      final rdateWithTime = DateTime(
        rdate.year,
        rdate.month,
        rdate.day,
        startSeed.hour,
        startSeed.minute,
        startSeed.second,
      );

      if (!result.any((seed) =>
          KST.atStartOfMinute(seed) == KST.atStartOfMinute(rdateWithTime))) {
        result.add(rdateWithTime);
      }
    }

    // Sort final result
    result.sort();
    return result;
  }

  /// Parse JSON array of ISO date strings, handling null/empty gracefully
  static List<String> _parseIsoList(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];

    try {
      // Simple CSV parsing for now - in production might want proper JSON
      return jsonStr.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }
}