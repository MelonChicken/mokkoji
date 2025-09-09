/// Normalized date key for stable stream parameters
/// Ensures consistent hashing and equality for provider families
class DateKey {
  final int y, m, d;
  
  const DateKey(this.y, this.m, this.d);
  
  /// Create DateKey from KST DateTime
  factory DateKey.fromKst(DateTime kstDateTime) => DateKey(
    kstDateTime.year,
    kstDateTime.month,
    kstDateTime.day,
  );
  
  /// Create DateKey for today (KST)
  factory DateKey.today() {
    final now = DateTime.now(); // Will be converted to KST in AppTime
    return DateKey.fromKst(now);
  }
  
  /// Convert to KST DateTime (start of day)
  DateTime toKstDateTime() => DateTime(y, m, d);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateKey &&
          runtimeType == other.runtimeType &&
          y == other.y &&
          m == other.m &&
          d == other.d;
  
  @override
  int get hashCode => Object.hash(y, m, d);
  
  @override
  String toString() => '$y-${m.toString().padLeft(2, "0")}-${d.toString().padLeft(2, "0")}';
  
  /// Add days to this date
  DateKey add(int days) {
    final dt = DateTime(y, m, d).add(Duration(days: days));
    return DateKey(dt.year, dt.month, dt.day);
  }
  
  /// Subtract days from this date  
  DateKey subtract(int days) => add(-days);
}