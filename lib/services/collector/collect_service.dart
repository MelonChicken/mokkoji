import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/time/app_time.dart';
import '../../data/dao/event_dao.dart';
import '../../data/repository/event_repository.dart';

/// Service for collecting events from external sources with real-time UI updates
/// Handles fetching, processing, and storing events while triggering UI refreshes
class CollectService {
  final EventRepository _repository;
  final List<EventCollector> _collectors;
  
  CollectService(this._repository, this._collectors);

  /// Collect new events from all configured sources
  /// Returns total number of events processed
  Future<CollectionResult> collectNewEvents() async {
    if (kDebugMode) {
      debugPrint('[CollectService] Starting event collection...');
    }

    final allEvents = <EventModel>[];
    final results = <String, UpsertStats>{};
    
    // Fetch from all collectors
    for (final collector in _collectors) {
      try {
        if (kDebugMode) {
          debugPrint('[CollectService] Fetching from ${collector.sourceName}...');
        }
        
        final events = await collector.fetchEvents();
        allEvents.addAll(events);
        
        if (kDebugMode) {
          debugPrint('[CollectService] ${collector.sourceName}: ${events.length} events fetched');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CollectService] Error fetching from ${collector.sourceName}: $e');
        }
      }
    }
    
    // Bulk upsert all events
    if (allEvents.isNotEmpty) {
      final stats = await _repository.upsertEvents(allEvents);
      
      if (kDebugMode) {
        debugPrint('[collect] totalUpsert=${stats.total}');
      }
      
      return CollectionResult(
        totalFetched: allEvents.length,
        stats: stats,
        sources: _collectors.map((c) => c.sourceName).toList(),
      );
    } else {
      if (kDebugMode) {
        debugPrint('[CollectService] No events to process');
      }
      
      return CollectionResult(
        totalFetched: 0,
        stats: const UpsertStats(inserted: 0, updated: 0, skipped: 0),
        sources: [],
      );
    }
  }

  /// Collect events from a specific source
  Future<UpsertStats> collectFromSource(String sourceName) async {
    final collector = _collectors.where((c) => c.sourceName == sourceName).firstOrNull;
    if (collector == null) {
      throw ArgumentError('Unknown collector: $sourceName');
    }
    
    final events = await collector.fetchEvents();
    return await _repository.upsertEvents(events);
  }

  /// Get available collector sources
  List<String> get availableSources => _collectors.map((c) => c.sourceName).toList();
}

/// Abstract base for event collectors
abstract class EventCollector {
  String get sourceName;
  
  Future<List<EventModel>> fetchEvents();
}

/// Mock collector for internal testing
class MockEventCollector extends EventCollector {
  @override
  String get sourceName => 'mock';

  @override
  Future<List<EventModel>> fetchEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now().toUtc();
    
    return [
      EventModel.fromExternal(
        source: 'mock',
        uid: 'mock_1',
        title: '테스트 미팅',
        description: '목업 이벤트 테스트',
        startUtc: now.add(const Duration(hours: 1)),
        endUtc: now.add(const Duration(hours: 2)),
        location: '회의실 A',
        color: '#FF5722',
      ),
      EventModel.fromExternal(
        source: 'mock',
        uid: 'mock_2', 
        title: '점심 약속',
        startUtc: now.add(const Duration(hours: 3)),
        endUtc: now.add(const Duration(hours: 4)),
        location: '카페 모코지',
      ),
      EventModel.fromExternal(
        source: 'mock',
        uid: 'mock_3',
        title: '오늘밤 자정 넘김 테스트',
        startUtc: DateTime.now().toUtc().copyWith(hour: 23, minute: 30),
        endUtc: DateTime.now().toUtc().copyWith(hour: 23, minute: 30).add(const Duration(hours: 2)),
        allDay: false,
      ),
    ];
  }
}

/// Google Calendar collector (placeholder)
class GoogleEventCollector extends EventCollector {
  @override
  String get sourceName => 'google';

  @override
  Future<List<EventModel>> fetchEvents() async {
    // TODO: Implement Google Calendar API integration
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return empty for now
    return [];
  }
}

/// Naver Calendar collector (placeholder)  
class NaverEventCollector extends EventCollector {
  @override
  String get sourceName => 'naver';

  @override
  Future<List<EventModel>> fetchEvents() async {
    // TODO: Implement Naver Calendar API integration
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Return empty for now
    return [];
  }
}

/// Kakao Calendar collector (placeholder)
class KakaoEventCollector extends EventCollector {
  @override
  String get sourceName => 'kakao';

  @override
  Future<List<EventModel>> fetchEvents() async {
    // TODO: Implement Kakao Calendar API integration
    await Future.delayed(const Duration(milliseconds: 700));
    
    // Return empty for now
    return [];
  }
}

/// Result of event collection operation
class CollectionResult {
  final int totalFetched;
  final UpsertStats stats;
  final List<String> sources;
  final DateTime timestamp;

  CollectionResult({
    required this.totalFetched,
    required this.stats,
    required this.sources,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'CollectionResult(fetched: $totalFetched, inserted: ${stats.inserted}, updated: ${stats.updated}, skipped: ${stats.skipped}, sources: ${sources.join(", ")})';
  }
}

/// Factory for creating CollectService with default collectors
class CollectServiceFactory {
  static CollectService create(EventRepository repository) {
    final collectors = <EventCollector>[
      MockEventCollector(),
      GoogleEventCollector(), 
      NaverEventCollector(),
      KakaoEventCollector(),
    ];
    
    return CollectService(repository, collectors);
  }
  
  /// Create service with only mock collector for testing
  static CollectService createForTesting(EventRepository repository) {
    return CollectService(repository, [MockEventCollector()]);
  }
}