import 'package:sqflite/sqflite.dart';

/// Migration to add duration_min field and default tzid for recurrence support
class AddDurationFieldMigration {
  static Future<void> run(Database db) async {
    // Add duration_min field with default 60 minutes
    await db.execute('ALTER TABLE events ADD COLUMN duration_min INTEGER NOT NULL DEFAULT 60');

    // Set tzid default to 'Asia/Seoul' for existing events that have recurrence
    await db.execute('UPDATE events SET tzid = \'Asia/Seoul\' WHERE tzid IS NULL AND rrule IS NOT NULL');

    // Backfill duration_min for existing events based on end_dt - start_dt
    // This query calculates minutes between start and end times for events that have end_dt
    await db.execute('''
      UPDATE events
      SET duration_min = CAST(
        (julianday(end_dt) - julianday(start_dt)) * 24 * 60 AS INTEGER
      )
      WHERE end_dt IS NOT NULL
        AND duration_min = 60
        AND julianday(end_dt) > julianday(start_dt)
    ''');

    print('[Migration] Added duration_min field and backfilled existing events');
  }
}