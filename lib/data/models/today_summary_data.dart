import '../../../features/events/data/event_entity.dart';

class EventOccurrence {
  final DateTime startTime;
  final String title;
  final String sourcePlatform;
  final String? location;
  
  const EventOccurrence({
    required this.startTime,
    required this.title,
    required this.sourcePlatform,
    this.location,
  });
  
  factory EventOccurrence.fromEvent(EventEntity event) {
    return EventOccurrence(
      startTime: DateTime.parse(event.startDt),
      title: event.title,
      sourcePlatform: event.sourcePlatform,
      location: event.location,
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