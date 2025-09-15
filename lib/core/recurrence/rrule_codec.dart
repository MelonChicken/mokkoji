/// iCalendar RRULE codec for repeat rule serialization/deserialization
/// Supports DAILY/WEEKLY/MONTHLY with INTERVAL, BYDAY, UNTIL, and COUNT

enum RepeatFreq {
  none,
  daily,
  weekly,
  monthly,
}

enum RepeatEnd {
  none,   // Forever
  count,  // Count occurrences
  until,  // Until date
}

class RepeatRule {
  final RepeatFreq freq;
  final int interval;           // 1+ (every N days/weeks/months)
  final Set<int> byWeekday;     // 1=Mon..7=Sun (for weekly)
  final RepeatEnd endType;
  final int? count;             // Number of occurrences (when endType=count)
  final DateTime? untilKst;     // End date in KST (when endType=until)

  const RepeatRule({
    this.freq = RepeatFreq.none,
    this.interval = 1,
    this.byWeekday = const {},
    this.endType = RepeatEnd.none,
    this.count,
    this.untilKst,
  });

  /// Check if this is a valid repeat rule
  bool get isValid {
    if (freq == RepeatFreq.none) return true;

    if (interval < 1) return false;

    // Weekly must have at least one weekday selected
    if (freq == RepeatFreq.weekly && byWeekday.isEmpty) return false;

    // Validate end conditions
    if (endType == RepeatEnd.count && (count == null || count! <= 0)) return false;
    if (endType == RepeatEnd.until && untilKst == null) return false;

    // Validate weekday values (1-7)
    if (byWeekday.any((day) => day < 1 || day > 7)) return false;

    return true;
  }

  /// Check if this rule has no repetition
  bool get isNone => freq == RepeatFreq.none;

  /// Get a human-readable summary
  String getSummary() {
    if (freq == RepeatFreq.none) return '반복 없음';

    String summary = '';

    switch (freq) {
      case RepeatFreq.daily:
        if (interval == 1) {
          summary = '매일';
        } else {
          summary = '$interval일마다';
        }
        break;

      case RepeatFreq.weekly:
        if (interval == 1) {
          summary = '매주';
        } else {
          summary = '$interval주마다';
        }

        if (byWeekday.isNotEmpty) {
          final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
          final selectedDays = byWeekday.toList()..sort();
          final dayLabels = selectedDays.map((day) => dayNames[day - 1]).join(', ');
          summary += ' ($dayLabels)';
        }
        break;

      case RepeatFreq.monthly:
        if (interval == 1) {
          summary = '매월';
        } else {
          summary = '$interval개월마다';
        }
        break;

      case RepeatFreq.none:
        return '반복 없음';
    }

    // Add end condition
    switch (endType) {
      case RepeatEnd.count:
        summary += ', ${count}회';
        break;
      case RepeatEnd.until:
        if (untilKst != null) {
          final date = untilKst!;
          summary += ', ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}까지';
        }
        break;
      case RepeatEnd.none:
        // No end condition
        break;
    }

    return summary;
  }

  /// Convert to iCalendar RRULE string
  String? toRRule(DateTime anchorKst) {
    if (freq == RepeatFreq.none || !isValid) return null;

    final parts = <String>[];

    // FREQ
    switch (freq) {
      case RepeatFreq.daily:
        parts.add('FREQ=DAILY');
        break;
      case RepeatFreq.weekly:
        parts.add('FREQ=WEEKLY');
        break;
      case RepeatFreq.monthly:
        parts.add('FREQ=MONTHLY');
        break;
      case RepeatFreq.none:
        return null;
    }

    // INTERVAL (only if > 1)
    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }

    // BYDAY (for weekly)
    if (freq == RepeatFreq.weekly && byWeekday.isNotEmpty) {
      // Convert 1=Mon..7=Sun to RFC weekdays: MO,TU,WE,TH,FR,SA,SU
      final rfcDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final selectedDays = byWeekday.toList()..sort();
      final dayStrings = selectedDays.map((day) => rfcDays[day - 1]);
      parts.add('BYDAY=${dayStrings.join(',')}');
    }

    // End conditions
    switch (endType) {
      case RepeatEnd.count:
        if (count != null) {
          parts.add('COUNT=$count');
        }
        break;
      case RepeatEnd.until:
        if (untilKst != null) {
          // Convert KST date to UTC for UNTIL (RFC requires UTC)
          final utcDate = DateTime(untilKst!.year, untilKst!.month, untilKst!.day, 23, 59, 59).toUtc();
          final utcString = utcDate.toIso8601String().replaceAll(RegExp(r'[:\-]'), '').split('.')[0] + 'Z';
          parts.add('UNTIL=$utcString');
        }
        break;
      case RepeatEnd.none:
        // No end condition
        break;
    }

    return parts.join(';');
  }

  /// Parse iCalendar RRULE string to RepeatRule
  static RepeatRule? fromRRule(String? rrule) {
    if (rrule == null || rrule.trim().isEmpty) {
      return const RepeatRule(); // No repetition
    }

    try {
      final parts = rrule.split(';');
      final params = <String, String>{};

      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          params[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      // Parse FREQ
      RepeatFreq freq = RepeatFreq.none;
      switch (params['FREQ']?.toUpperCase()) {
        case 'DAILY':
          freq = RepeatFreq.daily;
          break;
        case 'WEEKLY':
          freq = RepeatFreq.weekly;
          break;
        case 'MONTHLY':
          freq = RepeatFreq.monthly;
          break;
        default:
          return const RepeatRule(); // Unsupported frequency
      }

      // Parse INTERVAL
      final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

      // Parse BYDAY (for weekly)
      Set<int> byWeekday = {};
      if (params['BYDAY'] != null) {
        final dayMap = {
          'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4,
          'FR': 5, 'SA': 6, 'SU': 7,
        };

        final dayStrings = params['BYDAY']!.split(',');
        for (final dayString in dayStrings) {
          final day = dayMap[dayString.trim().toUpperCase()];
          if (day != null) {
            byWeekday.add(day);
          }
        }
      }

      // Parse end conditions
      RepeatEnd endType = RepeatEnd.none;
      int? count;
      DateTime? untilKst;

      if (params['COUNT'] != null) {
        count = int.tryParse(params['COUNT']!);
        if (count != null && count > 0) {
          endType = RepeatEnd.count;
        }
      } else if (params['UNTIL'] != null) {
        // Parse UNTIL date (usually in UTC format YYYYMMDDTHHMMSSZ)
        final untilString = params['UNTIL']!;
        try {
          final year = int.parse(untilString.substring(0, 4));
          final month = int.parse(untilString.substring(4, 6));
          final day = int.parse(untilString.substring(6, 8));

          // Convert from UTC to KST date (ignoring time for simplicity)
          untilKst = DateTime(year, month, day);
          endType = RepeatEnd.until;
        } catch (e) {
          // Ignore invalid UNTIL format
        }
      }

      return RepeatRule(
        freq: freq,
        interval: interval,
        byWeekday: byWeekday,
        endType: endType,
        count: count,
        untilKst: untilKst,
      );

    } catch (e) {
      // Return no repetition on parse error
      return const RepeatRule();
    }
  }

  /// Copy with modifications
  RepeatRule copyWith({
    RepeatFreq? freq,
    int? interval,
    Set<int>? byWeekday,
    RepeatEnd? endType,
    int? count,
    DateTime? untilKst,
  }) {
    return RepeatRule(
      freq: freq ?? this.freq,
      interval: interval ?? this.interval,
      byWeekday: byWeekday ?? this.byWeekday,
      endType: endType ?? this.endType,
      count: count ?? this.count,
      untilKst: untilKst ?? this.untilKst,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatRule &&
          runtimeType == other.runtimeType &&
          freq == other.freq &&
          interval == other.interval &&
          byWeekday == other.byWeekday &&
          endType == other.endType &&
          count == other.count &&
          untilKst == other.untilKst;

  @override
  int get hashCode =>
      freq.hashCode ^
      interval.hashCode ^
      byWeekday.hashCode ^
      endType.hashCode ^
      count.hashCode ^
      untilKst.hashCode;

  @override
  String toString() => getSummary();
}