import 'package:timezone/timezone.dart' as tz;
import '../../features/events/data/event_entity.dart';
import '../../core/time/app_time.dart';

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
  
  factory EventOccurrence.fromEvent(EventEntity event) {
    final start = DateTime.parse(event.startDt);
    final end = event.endDt != null 
        ? DateTime.parse(event.endDt!) 
        : start.add(const Duration(hours: 1)); // Default 1 hour if no end time
    
    return EventOccurrence(
      id: event.id,
      startTime: start,
      endTime: end,
      title: event.title,
      sourcePlatform: event.sourcePlatform,
      location: event.location,
      allDay: event.allDay,
      description: event.description,
      platformColor: event.platformColor,
    );
  }
  
  /// KST 기준 시작 시각
  tz.TZDateTime get startKst => AppTime.toKst(startTime);
  
  /// KST 기준 종료 시각
  tz.TZDateTime get endKst => AppTime.toKst(endTime);
  
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
}

class TodaySummaryData {
  final int count;
  final EventOccurrence? next;
  final DateTime lastSyncAt;
  final bool offline;
  
  const TodaySummaryData({
    required this.count,
    this.next,
    required this.lastSyncAt,
    required this.offline,
  });
  
  TodaySummaryData copyWith({
    int? count,
    EventOccurrence? next,
    DateTime? lastSyncAt,
    bool? offline,
  }) {
    return TodaySummaryData(
      count: count ?? this.count,
      next: next ?? this.next,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      offline: offline ?? this.offline,
    );
  }
}