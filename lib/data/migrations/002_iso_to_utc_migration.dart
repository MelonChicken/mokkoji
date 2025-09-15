import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/time/kst.dart';

/// Safe, idempotent migration to fix legacy ISO timestamps to proper UTC format
/// 
/// Problem: Some events may have been stored with non-UTC ISO strings like:
/// - "2025-09-10T02:00:00.000" (no timezone, interpreted as local)
/// - "2025-09-10T11:00:00.000+09:00" (KST offset)
/// 
/// Solution: Convert all timestamps to proper UTC format with Z suffix
/// This migration is designed to be run from onUpgrade() and is fully idempotent
class IsoToUtcMigration {
  /// Run the migration safely with comprehensive error handling
  static Future<void> run(Database db) async {
    await db.transaction((txn) async {
      try {
        if (kDebugMode) {
          debugPrint('[MIG002] Starting ISO-to-UTC migration...');
        }
        
        // 1. Check if events table exists
        final tableExists = await _tableExists(txn, 'events');
        if (!tableExists) {
          if (kDebugMode) {
            debugPrint('[MIG002] Events table not found, skipping migration');
          }
          return;
        }
        
        // 2. Check required columns exist
        final hasStartDt = await _columnExists(txn, 'events', 'start_dt');
        final hasEndDt = await _columnExists(txn, 'events', 'end_dt');
        
        if (!hasStartDt && !hasEndDt) {
          if (kDebugMode) {
            debugPrint('[MIG002] No datetime columns found, skipping migration');
          }
          return;
        }
        
        // 3. Get events that may need conversion
        final events = await txn.query(
          'events',
          columns: ['id', 'start_dt', 'end_dt'],
          where: 'deleted_at IS NULL',
        );
        
        if (events.isEmpty) {
          if (kDebugMode) {
            debugPrint('[MIG002] No events found, migration complete');
          }
          return;
        }
        
        int fixedCount = 0;
        int skipCount = 0;
        
        // 4. Process each event safely
        for (final event in events) {
          final id = event['id'] as String;
          final startDt = event['start_dt'] as String?;
          final endDt = event['end_dt'] as String?;
          
          String? fixedStartDt;
          String? fixedEndDt;
          
          // Fix start_dt if needed
          if (startDt != null && startDt.isNotEmpty) {
            try {
              final utc = KST.parseUtcIsoLenient(startDt);
              final fixedIso = utc.toIso8601String();
              if (fixedIso != startDt) {
                fixedStartDt = fixedIso;
                if (kDebugMode) {
                  debugPrint('[MIG002] Fixed start_dt: $startDt → $fixedIso');
                }
              }
            } catch (e) {
              skipCount++;
              if (kDebugMode) {
                debugPrint('[MIG002] Skip bad start_dt id=$id: $e');
              }
            }
          }
          
          // Fix end_dt if needed
          if (endDt != null && endDt.isNotEmpty) {
            try {
              final utc = KST.parseUtcIsoLenient(endDt);
              final fixedIso = utc.toIso8601String();
              if (fixedIso != endDt) {
                fixedEndDt = fixedIso;
                if (kDebugMode) {
                  debugPrint('[MIG002] Fixed end_dt: $endDt → $fixedIso');
                }
              }
            } catch (e) {
              skipCount++;
              if (kDebugMode) {
                debugPrint('[MIG002] Skip bad end_dt id=$id: $e');
              }
            }
          }
          
          // Update if any fixes were needed
          if (fixedStartDt != null || fixedEndDt != null) {
            try {
              await txn.update(
                'events',
                {
                  if (fixedStartDt != null) 'start_dt': fixedStartDt,
                  if (fixedEndDt != null) 'end_dt': fixedEndDt,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [id],
              );
              fixedCount++;
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[MIG002] Failed to update event $id: $e');
              }
            }
          }
        }
        
        if (kDebugMode) {
          debugPrint('[MIG002] Migration complete: fixed=$fixedCount, skipped=$skipCount, total=${events.length}');
        }
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[MIG002] Migration failed: $e');
        }
        // Don't rethrow - allow app to continue with partial migration
      }
    });
  }
  
  /// Check if a table exists in the database
  static Future<bool> _tableExists(Transaction txn, String tableName) async {
    try {
      final result = await txn.rawQuery('''
        SELECT COUNT(*) as count 
        FROM sqlite_master 
        WHERE type='table' AND name=?
      ''', [tableName]);
      
      return (result.first['count'] as int) > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MIG002] Error checking table existence: $e');
      }
      return false;
    }
  }
  
  /// Check if a column exists in a table
  static Future<bool> _columnExists(Transaction txn, String tableName, String columnName) async {
    try {
      final result = await txn.rawQuery('PRAGMA table_info($tableName)');
      return result.any((row) => (row['name'] as String?) == columnName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MIG002] Error checking column existence: $e');
      }
      return false;
    }
  }
}