import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static const _dbName = 'mokkoji.db';
  static const _dbVersion = 2;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, v) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  start_dt TEXT NOT NULL,
  end_dt TEXT,
  all_day INTEGER NOT NULL,
  location TEXT,
  source_platform TEXT NOT NULL,
  platform_color TEXT,
  recurrence_rule TEXT,
  status TEXT,
  attendees_json TEXT,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  ical_uid TEXT,
  dtstamp TEXT,
  sequence INTEGER,
  rrule TEXT,
  rdate_json TEXT,
  exdate_json TEXT,
  tzid TEXT,
  transparency TEXT,
  url TEXT,
  categories_json TEXT,
  organizer_email TEXT,
  geo_lat REAL,
  geo_lng REAL
);
''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_events_date ON events(start_dt)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_events_platform ON events(source_platform)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_events_updated ON events(updated_at)');
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_events_uid ON events(ical_uid)');
        
        await db.execute('''
CREATE TABLE IF NOT EXISTS event_overrides (
  id TEXT PRIMARY KEY,
  ical_uid TEXT NOT NULL,
  recurrence_id TEXT NOT NULL,
  start_dt TEXT,
  end_dt TEXT,
  all_day INTEGER,
  title TEXT,
  description TEXT,
  location TEXT,
  status TEXT,
  attendees_json TEXT,
  last_modified TEXT NOT NULL
);
''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_overrides_parent ON event_overrides(ical_uid)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_overrides_recurid ON event_overrides(recurrence_id)');
        
        await db.execute('CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // iCalendar 확장 컬럼 추가 (기존 데이터 유지)
          await db.execute('ALTER TABLE events ADD COLUMN ical_uid TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN dtstamp TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN sequence INTEGER');
          await db.execute('ALTER TABLE events ADD COLUMN rrule TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN rdate_json TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN exdate_json TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN tzid TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN transparency TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN url TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN categories_json TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN organizer_email TEXT');
          await db.execute('ALTER TABLE events ADD COLUMN geo_lat REAL');
          await db.execute('ALTER TABLE events ADD COLUMN geo_lng REAL');

          await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_events_uid ON events(ical_uid)');

          // 반복 인스턴스 오버라이드 테이블
          await db.execute('''
CREATE TABLE IF NOT EXISTS event_overrides (
  id TEXT PRIMARY KEY,
  ical_uid TEXT NOT NULL,
  recurrence_id TEXT NOT NULL,
  start_dt TEXT,
  end_dt TEXT,
  all_day INTEGER,
  title TEXT,
  description TEXT,
  location TEXT,
  status TEXT,
  attendees_json TEXT,
  last_modified TEXT NOT NULL
);
''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_overrides_parent ON event_overrides(ical_uid)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_overrides_recurid ON event_overrides(recurrence_id)');
        }
      },
    );
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}