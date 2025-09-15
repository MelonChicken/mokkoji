import 'package:timezone/timezone.dart' as tz;
import '../../core/time/kst.dart';

/// Represents a time window for repeat materialization
class MaterializationWindow {
  final tz.TZDateTime startKst;
  final tz.TZDateTime endKst;
  final DateTime startUtc;
  final DateTime endUtc;

  const MaterializationWindow({
    required this.startKst,
    required this.endKst,
    required this.startUtc,
    required this.endUtc,
  });

  /// Create a standard window around a reference time
  /// @param nowKst Reference KST time (defaults to current time)
  /// @param backDays Days to look back (default 14)
  /// @param forwardDays Days to look forward (default 180)
  factory MaterializationWindow.standard({
    tz.TZDateTime? nowKst,
    int backDays = 14,
    int forwardDays = 180,
  }) {
    final now = nowKst ?? KST.now();

    // Create KST window bounds
    final startKst = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day - backDays,
      0, 0, 0, // Start of day
    );

    final endKst = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + forwardDays,
      23, 59, 59, 999, // End of day
    );

    // Convert to UTC for database queries
    final startUtc = KST.utcFromKst(startKst);
    final endUtc = KST.utcFromKst(endKst);

    return MaterializationWindow(
      startKst: startKst,
      endKst: endKst,
      startUtc: startUtc,
      endUtc: endUtc,
    );
  }

  /// Get all affected date keys in this window
  Set<String> getAffectedDateKeys() {
    final keys = <String>{};
    var current = startKst;

    while (!current.isAfter(endKst)) {
      keys.add(KST.dateKeyFromTz(current));
      current = current.add(const Duration(days: 1));
    }

    return keys;
  }

  @override
  String toString() {
    return 'MaterializationWindow{KST: ${KST.dateKeyFromTz(startKst)} to ${KST.dateKeyFromTz(endKst)}}';
  }
}