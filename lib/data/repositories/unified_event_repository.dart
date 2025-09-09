import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../db/app_database.dart';
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../db/db_signal.dart';
import '../../core/time/app_time.dart';
import '../../core/time/date_key.dart';
import '../models/today_summary_data.dart';

/// Unified event repository providing single stream sources for all UI
/// All date operations use KST for consistency
class UnifiedEventRepository {
  final EventsDao _dao;
  
  UnifiedEventRepository(AppDatabase database) 
      : _dao = EventsDao() {
    if (kDebugMode) {
      debugPrint('Repo using DB#${identityHashCode(database)}');
    }
  }

  /// Load occurrences for a day synchronously (one-time)
  Future<List<EventOccurrence>> _loadOnceForDayKey(DateKey key) async {
    final startK = key.toKstDateTime();
    final endK = startK.add(const Duration(days: 1));
    
    try {
      // Direct database query without watch
      final dayBefore = startK.subtract(const Duration(days: 1));
      final dayAfter = endK.add(const Duration(days: 1));
      
      final rawEvents = await _dao.range(
        dayBefore.toIso8601String(),
        dayAfter.toIso8601String(),
      );
      
      final validEvents = rawEvents.where(_includeEvent).toList();
      final occurrences = <EventOccurrence>[];
      
      for (final event in validEvents) {
        final eventOccurrences = _expandOccurrences(event, startK, endK);
        occurrences.addAll(eventOccurrences);
      }
      
      occurrences.sort((a, b) {
        final timeComp = a.startKst.compareTo(b.startKst);
        if (timeComp != 0) return timeComp;
        final durComp = b.durationMinutes.compareTo(a.durationMinutes);
        if (durComp != 0) return durComp;
        return a.title.compareTo(b.title);
      });
      
      return occurrences
          .map((o) => o.withMinDuration(const Duration(minutes: 1)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ _loadOnceForDayKey error $key: $e');
      }
      return <EventOccurrence>[];
    }
  }

  /// Single source of truth: immediate emission + watch stream combination
  /// All home timeline, combined view, and summary use this same stream
  Stream<List<EventOccurrence>> watchOccurrencesForDayKey(DateKey key) {
    final startK = key.toKstDateTime();
    final endK = startK.add(const Duration(days: 1));
    
    if (kDebugMode) {
      debugPrint('▶ watch start $key');
    }
    
    // Create broadcast controller for multiple subscriptions
    final controller = StreamController<List<EventOccurrence>>.broadcast();
    
    // Start async operation
    () async {
      try {
        // 1) Immediate emission to end loading state
        final initial = await _loadOnceForDayKey(key);
        if (kDebugMode) {
          debugPrint('● immediate emit $key count=${initial.length}');
        }
        controller.add(initial);
        
        // 2) Follow with watch stream for live updates
        await for (final _ in DbSignal.instance.eventsStream) {
          try {
            final updated = await _loadOnceForDayKey(key);
            if (kDebugMode) {
              debugPrint('● watch emit $key count=${updated.length}');
            }
            controller.add(updated);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⛔ watch error $key: $e');
            }
            // Don't break the stream, just log the error
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('⛔ stream error $key: $e');
          debugPrint(stackTrace.toString());
        }
        // Send error to UI instead of swallowing it
        controller.addError(e, stackTrace);
      } finally {
        await controller.close();
      }
    }();
    
    return controller.stream;
  }
  
  /// Single source: today summary data derived from same occurrence stream
  Stream<TodaySummaryData> watchTodaySummaryForKey(DateKey key) {
    final now = AppTime.nowKst();
    
    return watchOccurrencesForDayKey(key).map((occurrences) {
      // Find next upcoming event
      EventOccurrence? next;
      for (final occ in occurrences) {
        if (occ.startKst.isAfter(now)) {
          next = occ;
          break;
        }
      }
      
      return TodaySummaryData(
        count: occurrences.length,
        next: next,
        lastSyncAt: now, // TODO: Get from sync state
        offline: false,  // TODO: Get from sync state
      );
    });
  }
  
  /// Backward compatibility: watch occurrences for a KST DateTime
  /// Delegates to DateKey-based method
  Stream<List<EventOccurrence>> watchOccurrencesForDayKst(DateTime dayKst) {
    final key = DateKey.fromKst(dayKst);
    return watchOccurrencesForDayKey(key);
  }
  
  /// Backward compatibility: watch summary for KST DateTime  
  Stream<TodaySummaryData> watchTodaySummaryKst(DateTime dayKst) {
    final key = DateKey.fromKst(dayKst);
    return watchTodaySummaryForKey(key);
  }
  
  /// Expand RRULE occurrences for an event within a date range
  List<EventOccurrence> _expandOccurrences(
    EventEntity event,
    DateTime windowStartKst,
    DateTime windowEndKst,
  ) {
    final startUtc = DateTime.parse(event.startDt);
    final endUtc = event.endDt != null 
        ? DateTime.parse(event.endDt!)
        : startUtc.add(const Duration(hours: 1));
    
    final startKst = AppTime.toKst(startUtc);
    final endKst = AppTime.toKst(endUtc);
    
    // Check if event overlaps with window: (start < windowEnd) && (end > windowStart)
    if (startKst.isBefore(windowEndKst) && endKst.isAfter(windowStartKst)) {
      // Simple case: single occurrence (no RRULE expansion for now)
      return [
        EventOccurrence(
          id: event.id,
          startTime: startUtc,
          endTime: endUtc,
          title: event.title,
          sourcePlatform: event.sourcePlatform,
          location: event.location,
          allDay: event.allDay,
          description: event.description,
          platformColor: event.platformColor,
        )
      ];
    }
    
    return [];
  }

  /// Event filtering logic - centralized for consistency
  bool _includeEvent(EventEntity event) {
    // Skip soft-deleted events
    if (event.deletedAt != null) return false;
    
    // TODO: Add other filtering logic here (platform filters, etc.)
    return true;
  }
  
  /// Occurrence list equality check for stream deduplication
  bool _occurrenceListEquals(List<EventOccurrence> a, List<EventOccurrence> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
  
  /// Debug helper: dump day occurrences for consistency checking
  Future<void> debugDumpDayKey(DateKey key) async {
    if (!kDebugMode) return;
    
    final occurrences = await watchOccurrencesForDayKey(key).first;
    final summary = await watchTodaySummaryForKey(key).first;
    
    debugPrint('🔍 === DEBUG DUMP for $key ===');
    debugPrint('TL-COUNT: ${occurrences.length}');
    debugPrint('SUMMARY-COUNT: ${summary.count}');
    debugPrint('SUMMARY-NEXT: ${summary.next?.title ?? 'null'} at ${summary.next?.startKst.toIso8601String() ?? 'null'}');
    
    for (int i = 0; i < occurrences.length; i++) {
      final occ = occurrences[i];
      debugPrint('TL-ITEM[$i]: ${occ.title} | ${occ.startKst.toIso8601String()} -> ${occ.endKst.toIso8601String()} | ${occ.sourcePlatform}');
    }
    
    debugPrint('🔍 === END DUMP ===');
  }
}

