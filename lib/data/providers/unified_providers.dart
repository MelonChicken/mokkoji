import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/app_database.dart';
import '../repositories/unified_event_repository.dart';
import '../services/event_write_service.dart';
import '../services/event_change_bus.dart';
import '../models/today_summary_data.dart';
import '../../core/time/app_time.dart';
import '../../core/time/date_key.dart';

/// Database singleton provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Event change bus provider
final eventChangeBusProvider = Provider<EventChangeBus>((ref) {
  return EventChangeBus.instance;
});

/// Unified event repository provider - single source of truth
final unifiedEventRepositoryProvider = Provider<UnifiedEventRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return UnifiedEventRepository(database);
});

/// Event write service provider - single write path
final eventWriteServiceProvider = Provider<EventWriteService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final changeBus = ref.watch(eventChangeBusProvider);
  return EventWriteService(database, changeBus);
});

/// Stable today key provider - fixed to prevent rebuild cycles
final todayKeyProvider = Provider<DateKey>((ref) {
  final now = AppTime.nowKst();
  // Only use date components to eliminate time-based variations
  return DateKey(now.year, now.month, now.day);
});

/// Stream provider for occurrences on a specific DateKey
/// This is the single source of truth that all UI screens should use
/// Stabilized with keepAlive to prevent re-subscription storms
final occurrencesForDayProvider = StreamProvider.family.autoDispose<List<EventOccurrence>, DateKey>((ref, key) {
  // ✅ Auto dispose prevention - keeps stream alive during screen lifecycle
  final link = ref.keepAlive();
  
  final repository = ref.watch(unifiedEventRepositoryProvider);
  final stream = repository.watchOccurrencesForDayKey(key);
  
  // Enhanced logging and cleanup
  ref.onDispose(() {
    if (kDebugMode) {
      debugPrint('◀ watch end $key');
    }
  });
  
  ref.onCancel(() {
    Future.delayed(const Duration(minutes: 5), link.close);
  });

  // Handle errors in the stream without breaking it
  return stream.handleError((error, stackTrace) {
    if (kDebugMode) {
      debugPrint('provider error $key: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  });
});

/// Stream provider for summary data
/// Derived from the same occurrence stream for consistency  
final todaySummaryProvider = StreamProvider.family.autoDispose<TodaySummaryData, DateKey>((ref, key) {
  final link = ref.keepAlive();
  
  ref.onCancel(() {
    Future.delayed(const Duration(minutes: 5), link.close);
  });

  final repository = ref.watch(unifiedEventRepositoryProvider);
  return repository.watchTodaySummaryForKey(key);
});

/// Convenience provider for today's occurrences (most common use case)
final todayOccurrencesProvider = StreamProvider<List<EventOccurrence>>((ref) {
  final key = ref.watch(todayKeyProvider);
  return ref.watch(unifiedEventRepositoryProvider).watchOccurrencesForDayKey(key);
});

/// Convenience provider for today's summary
final todaySummaryTodayProvider = StreamProvider<TodaySummaryData>((ref) {
  final key = ref.watch(todayKeyProvider);
  return ref.watch(unifiedEventRepositoryProvider).watchTodaySummaryForKey(key);
});

/// Provider for debug operations
final debugRepositoryProvider = Provider<UnifiedEventRepository>((ref) {
  return ref.watch(unifiedEventRepositoryProvider);
});