/// Database singleton holder for consistent access across the app
/// Ensures single database instance for all operations
import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

class AppDatabaseHolder {
  static AppDatabase? _db;
  
  /// Get the single database instance with verification logging
  static AppDatabase instance() {
    _db ??= AppDatabase.instance;
    if (kDebugMode) {
      debugPrint('DB#${identityHashCode(_db)} ready');
    }
    return _db!;
  }
  
  /// Clear instance (for testing)
  static void clear() {
    _db = null;
  }
}