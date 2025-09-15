import 'package:sqflite/sqflite.dart';

/// Migration to add event_instances table for materialized repeat occurrences
class AddEventInstancesMigration {
  static Future<void> run(Database db) async {
    // Create the event_instances table for materialized repeat occurrences
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        master_event_id TEXT NOT NULL,
        start_utc TEXT NOT NULL,            -- ISO 8601 Z
        end_utc TEXT NOT NULL,              -- ISO 8601 Z
        is_detached INTEGER NOT NULL DEFAULT 0,-- per-instance edit detached from master
        updated_at TEXT NOT NULL,
        FOREIGN KEY (master_event_id) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for efficient querying and uniqueness
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS uq_inst_master_times
      ON event_instances(master_event_id, start_utc, end_utc)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inst_time_range
      ON event_instances(start_utc, end_utc)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inst_master
      ON event_instances(master_event_id)
    ''');

    print('[Migration] Added event_instances table with indexes for repeat materialization');
  }
}