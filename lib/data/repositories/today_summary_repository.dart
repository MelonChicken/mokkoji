import 'dart:async';
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../db/db_signal.dart';
import '../../core/time/app_time.dart';
import '../models/today_summary_data.dart';

class TodaySummaryRepository {
  final EventsDao _dao;
  late final StreamController<TodaySummaryData> _controller;
  late final Stream<TodaySummaryData> _stream;
  StreamSubscription<void>? _dbSubscription;
  TodaySummaryData? _cachedData;

  TodaySummaryRepository({required EventsDao dao}) : _dao = dao {
    _controller = StreamController<TodaySummaryData>.broadcast();
    _stream = _controller.stream;
    
    _dbSubscription = DbSignal.instance.eventsStream.listen((_) {
      _refreshData();
    });
    
    _refreshData();
  }

  Stream<TodaySummaryData> get stream => _stream;
  
  TodaySummaryData? get currentData => _cachedData;

  Future<void> _refreshData() async {
    try {
      final now = AppTime.nowKst();
      final (startOfToday, endOfToday) = AppTime.todayRangeKst();
      
      final events = await _dao.range(
        startOfToday.toIso8601String(),
        endOfToday.toIso8601String(),
      );
      
      final todayEvents = events.where((event) {
        final eventDate = DateTime.parse(event.startDt);
        return AppTime.isSameDayKst(eventDate, now) && event.deletedAt == null;
      }).toList();
      
      todayEvents.sort((a, b) => a.startDt.compareTo(b.startDt));
      
      EventOccurrence? nextEvent;
      final upcomingEvents = todayEvents.where((event) {
        final eventTime = AppTime.toKst(DateTime.parse(event.startDt));
        return eventTime.isAfter(now);
      }).toList();
      
      if (upcomingEvents.isNotEmpty) {
        nextEvent = EventOccurrence.fromEvent(upcomingEvents.first);
      }
      
      final summaryData = TodaySummaryData(
        count: todayEvents.length,
        next: nextEvent,
        lastSyncAt: now,
        offline: await _checkOfflineStatus(),
      );
      
      _cachedData = summaryData;
      _controller.add(summaryData);
    } catch (e) {
      final fallbackData = TodaySummaryData(
        count: 0,
        next: null,
        lastSyncAt: AppTime.nowKst(),
        offline: true,
      );
      
      _cachedData = fallbackData;
      _controller.add(fallbackData);
    }
  }

  Future<bool> _checkOfflineStatus() async {
    return false;
  }

  Future<List<EventEntity>> getTodayEvents() async {
    final now = AppTime.nowKst();
    final (startOfToday, endOfToday) = AppTime.todayRangeKst();
    
    final events = await _dao.range(
      startOfToday.toIso8601String(),
      endOfToday.toIso8601String(),
    );
    
    return events.where((event) {
      final eventDate = DateTime.parse(event.startDt);
      return AppTime.isSameDayKst(eventDate, now) && event.deletedAt == null;
    }).toList();
  }

  Future<void> forceRefresh() async {
    await _refreshData();
  }

  void dispose() {
    _dbSubscription?.cancel();
    _controller.close();
  }
}