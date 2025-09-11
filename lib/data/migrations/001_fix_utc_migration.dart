import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/time/app_time.dart';

/// Migration to fix timezone consistency issues
/// Purpose: Convert all naive datetime strings to proper UTC storage
/// 
/// Algorithm:
/// 1. Scan all events for datetime fields (start_dt, end_dt, updated_at, deleted_at)
/// 2. Check if each datetime string ends with 'Z' (already UTC)
/// 3. If not, assume it was stored naively as KST and convert to UTC
/// 4. Update the record with proper UTC ISO8601 string
/// 5. Set migration flag to prevent re-running
class FixUtcMigration {
  static const String migrationKey = 'migration_001_fix_utc';
  static const int targetVersion = 3;

  /// Run the migration if needed
  static Future<void> run(Database db) async {
    await AppTime.init(); // Ensure timezone data is loaded
    
    // Check if migration already completed
    final result = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: [migrationKey],
    );
    
    if (result.isNotEmpty && result.first['value'] == 'completed') {
      if (kDebugMode) {
        debugPrint('⏭️ UTC migration already completed, skipping');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('🔄 Starting UTC migration...');
    }
    
    await db.transaction((txn) async {
      // Migrate events table
      await _migrateEventsTable(txn);
      
      // Migrate event_overrides table
      await _migrateEventOverridesTable(txn);
      
      // Mark migration as completed
      await txn.insert(
        'meta',
        {'key': migrationKey, 'value': 'completed'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    
    if (kDebugMode) {
      debugPrint('✅ UTC migration completed successfully');
    }
  }
  
  static Future<void> _migrateEventsTable(Transaction txn) async {
    final events = await txn.query('events');
    int fixedCount = 0;
    
    for (final event in events) {
      bool needsUpdate = false;
      final updates = <String, dynamic>{};
      
      // Check and fix start_dt
      final startDt = event['start_dt'] as String?;
      if (startDt != null) {
        final fixedStart = _fixDateTimeString(startDt);
        if (fixedStart != startDt) {
          updates['start_dt'] = fixedStart;
          needsUpdate = true;
        }
      }
      
      // Check and fix end_dt
      final endDt = event['end_dt'] as String?;
      if (endDt != null) {
        final fixedEnd = _fixDateTimeString(endDt);
        if (fixedEnd != endDt) {
          updates['end_dt'] = fixedEnd;
          needsUpdate = true;
        }
      }
      
      // Check and fix updated_at
      final updatedAt = event['updated_at'] as String?;
      if (updatedAt != null) {
        final fixedUpdated = _fixDateTimeString(updatedAt);
        if (fixedUpdated != updatedAt) {
          updates['updated_at'] = fixedUpdated;
          needsUpdate = true;
        }
      }
      
      // Check and fix deleted_at
      final deletedAt = event['deleted_at'] as String?;
      if (deletedAt != null) {
        final fixedDeleted = _fixDateTimeString(deletedAt);
        if (fixedDeleted != deletedAt) {
          updates['deleted_at'] = fixedDeleted;
          needsUpdate = true;
        }
      }
      
      // Update record if needed
      if (needsUpdate) {
        await txn.update(
          'events',
          updates,
          where: 'id = ?',
          whereArgs: [event['id']],
        );
        fixedCount++;
        
        if (kDebugMode) {
          debugPrint('🔧 Fixed event ${event['id']}: ${event['title']}');
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint('📊 Fixed $fixedCount/${events.length} events');
    }
  }
  
  static Future<void> _migrateEventOverridesTable(Transaction txn) async {
    // Check if table exists
    final tableInfo = await txn.query(
      'sqlite_master',
      where: "type = 'table' AND name = 'event_overrides'",
    );
    
    if (tableInfo.isEmpty) return;
    
    final overrides = await txn.query('event_overrides');
    int fixedCount = 0;
    
    for (final override in overrides) {
      bool needsUpdate = false;
      final updates = <String, dynamic>{};
      
      final fields = ['start_dt', 'end_dt', 'last_modified', 'recurrence_id'];
      for (final field in fields) {
        final value = override[field] as String?;
        if (value != null) {
          final fixed = _fixDateTimeString(value);
          if (fixed != value) {
            updates[field] = fixed;
            needsUpdate = true;
          }
        }
      }
      
      if (needsUpdate) {
        await txn.update(
          'event_overrides',
          updates,
          where: 'id = ?',
          whereArgs: [override['id']],
        );
        fixedCount++;
      }
    }
    
    if (kDebugMode) {
      debugPrint('📊 Fixed $fixedCount/${overrides.length} overrides');
    }
  }
  
  /// Fix a single datetime string
  static String _fixDateTimeString(String original) {
    try {
      // Already UTC
      if (original.endsWith('Z')) {
        return original;
      }
      
      // Has timezone offset
      final offsetPattern = RegExp(r'[+-]\d{2}:\d{2}$');
      if (offsetPattern.hasMatch(original)) {
        final parsed = DateTime.parse(original);
        return parsed.toUtc().toIso8601String();
      }
      
      // Naive datetime - assume it was KST
      final naive = DateTime.parse(original);
      final kstTime = tz.TZDateTime(
        AppTime.kst,
        naive.year,
        naive.month,
        naive.day,
        naive.hour,
        naive.minute,
        naive.second,
        naive.millisecond,
      );
      final utcTime = kstTime.toUtc();
      
      if (kDebugMode) {
        debugPrint('🔀 $original (KST) -> ${utcTime.toIso8601String()} (UTC)');
      }
      
      return utcTime.toIso8601String();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to parse datetime: $original - $e');
      }
      return original;
    }
  }
}