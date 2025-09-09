import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../app_database.dart';
import '../../features/events/data/event_entity.dart';
import '../../core/time/app_time.dart';
import 'event_change_bus.dart';

/// Handles occurrence indexing and materialization for performance
/// Currently focuses on on-the-fly expansion for immediate UI consistency
class OccurrenceIndexer {
  static final OccurrenceIndexer _instance = OccurrenceIndexer._();
  static OccurrenceIndexer get instance => _instance;
  
  OccurrenceIndexer._() {
    _listenToChanges();
  }
  
  StreamSubscription? _changeSubscription;
  
  void _listenToChanges() {
    _changeSubscription = EventChangeBus.instance.stream.listen((change) {
      _handleEventChange(change);
    });
  }
  
  void _handleEventChange(EventChanged change) {
    if (kDebugMode) {
      debugPrint('🔄 OccurrenceIndexer handling ${change.type} for event ${change.eventId}');
    }
    
    // For now, we rely on on-the-fly expansion in the repository
    // Future: Add materialized occurrence table updates here
    switch (change.type) {
      case EventChangeType.created:
      case EventChangeType.updated:
        _invalidateOccurrencesFor(change.eventId);
        break;
      case EventChangeType.deleted:
        _removeOccurrencesFor(change.eventId);
        break;
    }
  }
  
  void _invalidateOccurrencesFor(String eventId) {
    // Future: Invalidate or recompute materialized occurrences
    if (kDebugMode) {
      debugPrint('📝 Invalidating occurrences for event $eventId');
    }
  }
  
  void _removeOccurrencesFor(String eventId) {
    // Future: Remove materialized occurrences for deleted event
    if (kDebugMode) {
      debugPrint('🗑️ Removing occurrences for event $eventId');
    }
  }
  
  /// Expand RRULE occurrences for an event within a date range
  /// TIMEZONE CONTRACT: Input windowStartKst/windowEndKst are tz.TZDateTime KST boundaries
  List<EventOccurrence> expandOccurrences(
    EventEntity event,
    tz.TZDateTime windowStartKst,
    tz.TZDateTime windowEndKst,
  ) {
    // Parse DB times (should be UTC) and convert to KST for comparison
    final startUtc = DateTime.parse(event.startDt);
    final endUtc = event.endDt != null 
        ? DateTime.parse(event.endDt!)
        : startUtc.add(const Duration(hours: 1));
    
    // ENFORCE: DB times must be UTC, convert to KST for window checking
    assert(startUtc.isUtc, 'Event startDt must be stored as UTC in DB');
    assert(endUtc.isUtc, 'Event endDt must be stored as UTC in DB');
    
    final startKst = AppTime.toKst(startUtc);
    final endKst = AppTime.toKst(endUtc);
    
    // Check if event overlaps with window
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
  
  void dispose() {
    _changeSubscription?.cancel();
  }
}

/// Event occurrence data for timeline display
class EventOccurrence {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String sourcePlatform;
  final String? location;
  final bool allDay;
  final String? description;
  final String? platformColor;
  
  const EventOccurrence({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.sourcePlatform,
    this.location,
    this.allDay = false,
    this.description,
    this.platformColor,
  });
  
  /// KST 기준 시작 시각 (DB UTC → KST 변환)
  tz.TZDateTime get startKst => AppTime.toKst(startTime);
  
  /// KST 기준 종료 시각 (DB UTC → KST 변환) 
  tz.TZDateTime get endKst => AppTime.toKst(endTime);
  
  /// 최소 지속시간 적용 (0분 이벤트 보정)
  EventOccurrence withMinDuration(Duration minDuration) {
    final currentDuration = endTime.difference(startTime);
    if (currentDuration >= minDuration) {
      return this;
    }
    
    return EventOccurrence(
      id: id,
      startTime: startTime,
      endTime: startTime.add(minDuration),
      title: title,
      sourcePlatform: sourcePlatform,
      location: location,
      allDay: allDay,
      description: description,
      platformColor: platformColor,
    );
  }
  
  /// 분 단위 지속시간 (최소 1분)
  int get durationMinutes {
    final duration = endTime.difference(startTime).inMinutes;
    return duration < 1 ? 1 : duration;
  }
  
  /// KST 기준 자정부터의 시작 분
  int get startMinutesFromMidnightKst {
    final kst = startKst;
    return kst.hour * 60 + kst.minute;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventOccurrence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime;
  
  @override
  int get hashCode => Object.hash(id, startTime, endTime);
}