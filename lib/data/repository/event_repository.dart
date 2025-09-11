import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/time/app_time.dart';
import '../dao/event_dao.dart';

/// Repository for event data with KST/UTC conversion and real-time streams
/// Handles the complexity of timezone boundaries and provides clean APIs for UI
class EventRepository {
  final EventDao _dao;

  EventRepository(this._dao);

  /// Get events for a specific local date (KST) as a stream
  /// This automatically handles the UTC conversion and timezone boundaries
  Stream<List<EventModel>> watchEventsForLocalDate(DateTime localDate) {
    final (startUtcMs, endUtcMs) = _utcRangeOfLocalDay(localDate);
    
    return _dao.watchBetweenUtc(startUtcMs, endUtcMs).map((rows) {
      return rows.map(EventModel.fromRow).toList();
    });
  }

  /// Get events for a week range (7 days) as a stream
  Stream<List<EventModel>> watchEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final (startUtcMs, _) = _utcRangeOfLocalDay(weekStart);
    final (_, endUtcMs) = _utcRangeOfLocalDay(weekEnd);
    
    return _dao.watchBetweenUtc(startUtcMs, endUtcMs).map((rows) {
      return rows.map(EventModel.fromRow).toList();
    });
  }

  /// Get events for a month range as a stream
  Stream<List<EventModel>> watchEventsForMonth(DateTime monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    final (startUtcMs, _) = _utcRangeOfLocalDay(monthStart);
    final (_, endUtcMs) = _utcRangeOfLocalDay(monthEnd);
    
    return _dao.watchBetweenUtc(startUtcMs, endUtcMs).map((rows) {
      return rows.map(EventModel.fromRow).toList();
    });
  }

  /// Get events for today (KST) as a stream
  Stream<List<EventModel>> watchTodayEvents() {
    final today = AppTime.nowKst();
    final localToday = DateTime(today.year, today.month, today.day);
    return watchEventsForLocalDate(localToday);
  }

  /// Get events for a custom date range as a stream
  Stream<List<EventModel>> watchEventsBetween(DateTime startLocal, DateTime endLocal) {
    final (startUtcMs, _) = _utcRangeOfLocalDay(startLocal);
    final (_, endUtcMs) = _utcRangeOfLocalDay(endLocal);
    
    return _dao.watchBetweenUtc(startUtcMs, endUtcMs).map((rows) {
      return rows.map(EventModel.fromRow).toList();
    });
  }

  /// One-time fetch for events (without stream subscription)
  Future<List<EventModel>> getEventsForLocalDate(DateTime localDate) async {
    final (startUtcMs, endUtcMs) = _utcRangeOfLocalDay(localDate);
    final rows = await _dao.findBetweenUtc(startUtcMs, endUtcMs);
    return rows.map(EventModel.fromRow).toList();
  }

  /// Get recently created events for debugging
  Future<List<EventModel>> getRecentEvents(int minutes) async {
    final rows = await _dao.recentCreated(minutes);
    return rows.map(EventModel.fromRow).toList();
  }

  /// Bulk upsert events (used by collection service)
  Future<UpsertStats> upsertEvents(List<EventModel> events) {
    return _dao.upsertAll(events);
  }

  /// Convert local date to UTC millisecond range
  /// This is the core timezone conversion logic
  (int, int) _utcRangeOfLocalDay(DateTime localDate) {
    // Create local midnight (start of day)
    final localStart = DateTime(localDate.year, localDate.month, localDate.day);
    // Create local end of day (midnight of next day)  
    final localEnd = localStart.add(const Duration(days: 1));
    
    // Convert to UTC for database queries
    final utcStart = localStart.toUtc().millisecondsSinceEpoch;
    final utcEnd = localEnd.toUtc().millisecondsSinceEpoch;
    
    if (kDebugMode) {
      debugPrint('[EventRepo] Local date: $localDate');
      debugPrint('[EventRepo] Local range: $localStart to $localEnd');
      debugPrint('[EventRepo] UTC range: ${DateTime.fromMillisecondsSinceEpoch(utcStart, isUtc: true)} to ${DateTime.fromMillisecondsSinceEpoch(utcEnd, isUtc: true)}');
    }
    
    return (utcStart, utcEnd);
  }
}

/// Extension methods for easier date manipulation
extension DateTimeExtensions on DateTime {
  /// Get the start of day (midnight) in local timezone
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get the end of day (midnight of next day) in local timezone
  DateTime get endOfDay => DateTime(year, month, day + 1);
  
  /// Check if this date is the same day as another date (ignoring time)
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
  
  /// Get the start of the week (Monday) containing this date
  DateTime get startOfWeek {
    final daysFromMonday = (weekday - DateTime.monday) % 7;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }
  
  /// Get the start of the month containing this date
  DateTime get startOfMonth => DateTime(year, month, 1);
}

/// Event summary for UI display
class EventSummary {
  final int totalEvents;
  final int todayEvents;
  final int upcomingEvents;
  final DateTime lastUpdated;

  const EventSummary({
    required this.totalEvents,
    required this.todayEvents,
    required this.upcomingEvents,
    required this.lastUpdated,
  });
}

/// Repository extensions for summary data
extension EventRepositorySummary on EventRepository {
  /// Get event summary for dashboard display
  Future<EventSummary> getEventSummary() async {
    final now = DateTime.now();
    final today = now.startOfDay;
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    
    final todayEvents = await getEventsForLocalDate(today);
    final upcomingEvents = await getEventsForLocalDate(nextWeek);
    final recentEvents = await getRecentEvents(60); // Last hour
    
    return EventSummary(
      totalEvents: recentEvents.length,
      todayEvents: todayEvents.length,
      upcomingEvents: upcomingEvents.length,
      lastUpdated: DateTime.now(),
    );
  }
}