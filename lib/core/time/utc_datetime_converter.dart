import 'package:drift/drift.dart';

/// UTC DateTimeConverter for Drift
/// 
/// This converter ensures that all DateTime values stored in the database
/// are automatically converted to/from UTC, preventing timezone issues
/// where local DateTime objects get stored in the database.
/// 
/// Usage in table definitions:
/// ```dart
/// class Events extends Table {
///   IntColumn get startUtcMs => integer().map(const UtcDateTimeConverter())();
///   IntColumn get endUtcMs => integer().map(const UtcDateTimeConverter())();
/// }
/// ```
/// 
/// Migration strategy:
/// 1. Add new columns with UTC converter
/// 2. Copy existing data using: .toUtc().millisecondsSinceEpoch
/// 3. Update code to use new columns
/// 4. Drop old columns
class UtcDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeConverter();

  @override
  int? mapToSql(DateTime? value) {
    if (value == null) return null;
    
    // Ensure the DateTime is converted to UTC before storing
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return utcDateTime.millisecondsSinceEpoch;
  }

  @override
  DateTime? mapToDart(int? fromDb) {
    if (fromDb == null) return null;
    
    // Always restore as UTC from database
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }
}

/// Optional nullable version for endTime columns that might be null
class NullableUtcDateTimeConverter extends TypeConverter<DateTime?, int> {
  const NullableUtcDateTimeConverter();

  @override
  int? mapToSql(DateTime? value) {
    if (value == null) return null;
    
    // Ensure the DateTime is converted to UTC before storing
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return utcDateTime.millisecondsSinceEpoch;
  }

  @override
  DateTime? mapToDart(int? fromDb) {
    if (fromDb == null) return null;
    
    // Always restore as UTC from database
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }
}