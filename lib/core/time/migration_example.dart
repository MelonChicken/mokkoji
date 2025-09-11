// Migration example for converting existing dateTime columns to UTC converter
// This file is for documentation purposes only

/*
// Step 1: Add new UTC columns to table definition
class Events extends Table {
  // Existing columns (deprecated)
  @Deprecated('Use startUtcMs instead')
  DateTimeColumn get startDt => dateTime().named('start_dt')();
  
  @Deprecated('Use endUtcMs instead')  
  DateTimeColumn get endDt => dateTime().nullable().named('end_dt')();
  
  // New UTC converter columns
  IntColumn get startUtcMs => integer().map(const UtcDateTimeConverter()).named('start_utc_ms')();
  IntColumn get endUtcMs => integer().nullable().map(const NullableUtcDateTimeConverter()).named('end_utc_ms')();
  
  // ... other columns
}

// Step 2: Migration to copy data from old columns to new columns
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add the new UTC columns
        await m.addColumn(events, events.startUtcMs);
        await m.addColumn(events, events.endUtcMs);
        
        // Copy data from old columns to new UTC columns
        // This assumes the old data was stored as UTC strings
        await customStatement('''
          UPDATE events 
          SET 
            start_utc_ms = (
              CASE 
                WHEN start_dt IS NOT NULL 
                THEN (julianday(start_dt) - julianday('1970-01-01')) * 86400000
                ELSE NULL 
              END
            ),
            end_utc_ms = (
              CASE 
                WHEN end_dt IS NOT NULL 
                THEN (julianday(end_dt) - julianday('1970-01-01')) * 86400000
                ELSE NULL 
              END
            )
        ''');
      }
      
      if (from < 3) {
        // Drop old columns after verifying data migration
        await m.dropColumn(events, 'start_dt');
        await m.dropColumn(events, 'end_dt');
      }
    },
  );
}

// Step 3: Update DAO methods to use new columns
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(AppDatabase db) : super(db);

  Future<void> insertEvent(EventEntity entity) async {
    await into(events).insert(
      EventsCompanion(
        // Use UTC converter columns
        startUtcMs: Value(entity.startTime), // DateTime will be auto-converted to UTC
        endUtcMs: Value(entity.endTime),     // DateTime will be auto-converted to UTC
        // ... other fields
      ),
    );
  }
}
*/