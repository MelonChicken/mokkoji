"""Calendar synchronization service for Flutter client

설계 의도:  
- 자동 주기 동기화: 포그라운드 5-15분, 백그라운드 60분
- Pull/Push 분리: 서버→로컬, 로컬→서버 별도 처리
- 재시도 정책: 지수 백오프로 일시적 네트워크 오류 처리
- UI 상태 연동: 동기화 진행 상태를 스트림으로 브로드캐스트

"""
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_database.dart';
import '../core/logger.dart';

enum SyncState {
  idle,
  syncing,
  error,
}

class SyncStatus {
  final SyncState state;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final int pendingEventCount;

  const SyncStatus({
    required this.state,
    this.lastSyncAt,
    this.errorMessage,
    this.pendingEventCount = 0,
  });

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncAt,
    String? errorMessage,
    int? pendingEventCount,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingEventCount: pendingEventCount ?? this.pendingEventCount,
    );
  }
}

class CalendarSyncService {
  static const String _baseUrl = 'https://api.mokkoji.com'; // TODO: 환경별 설정
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const Duration _foregroundInterval = Duration(minutes: 10);
  static const Duration _backgroundInterval = Duration(minutes: 60);
  static const int _maxRetries = 3;

  final AppDatabase _database;
  final http.Client _httpClient;
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  
  Timer? _syncTimer;
  bool _isBackground = false;
  SyncStatus _currentStatus = const SyncStatus(state: SyncState.idle);

  CalendarSyncService(this._database, [http.Client? httpClient]) 
    : _httpClient = httpClient ?? http.Client();

  /// 동기화 상태 스트림
  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  /// 서비스 시작 (주기적 동기화 활성화)
  Future<void> start() async {
    await _updatePendingCount();
    _scheduleNextSync();
    
    AppLogger.info('SyncService started');
  }

  /// 서비스 중지
  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    AppLogger.info('SyncService stopped');
  }

  /// 앱 백그라운드/포그라운드 상태 변경
  void setBackgroundMode(bool isBackground) {
    if (_isBackground == isBackground) return;
    
    _isBackground = isBackground;
    _scheduleNextSync();
    
    // 포그라운드 복귀 시 즉시 동기화 (마지막 동기화로부터 5분+ 경과)
    if (!isBackground) {
      _checkAndTriggerSync();
    }
    
    AppLogger.info('SyncService background mode: $isBackground');
  }

  /// 수동 동기화 트리거
  Future<void> syncNow() async {
    if (_currentStatus.state == SyncState.syncing) {
      AppLogger.warn('Sync already in progress, skipping');
      return;
    }

    await _performSync(isManual: true);
  }

  /// 서버에서 로컬로 이벤트 풀
  Future<void> pullFromServer({bool forceFullSync = false}) async {
    await _performPull(forceFullSync: forceFullSync);
  }

  /// 로컬 변경사항을 서버에 푸시
  Future<void> pushToServer() async {
    await _performPush();
  }

  void _updateStatus(SyncStatus newStatus) {
    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  void _scheduleNextSync() {
    _syncTimer?.cancel();
    
    final interval = _isBackground ? _backgroundInterval : _foregroundInterval;
    _syncTimer = Timer(interval, () {
      _performSync(isManual: false);
    });
  }

  Future<void> _checkAndTriggerSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    
    if (lastSyncStr == null) {
      // 첫 동기화
      await _performSync(isManual: false);
      return;
    }

    final lastSync = DateTime.tryParse(lastSyncStr);
    if (lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      if (timeSinceLastSync > const Duration(minutes: 5)) {
        await _performSync(isManual: false);
      }
    }
  }

  Future<void> _performSync({required bool isManual}) async {
    if (_currentStatus.state == SyncState.syncing) return;

    _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));
    
    try {
      // 1. 서버에서 이벤트 가져오기
      await _performPull();
      
      // 2. 로컬 변경사항 푸시  
      await _performPush();
      
      // 3. 성공 상태 업데이트
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, now.toIso8601String());
      
      await _updatePendingCount();
      
      _updateStatus(SyncStatus(
        state: SyncState.idle,
        lastSyncAt: now,
        pendingEventCount: _currentStatus.pendingEventCount,
      ));

      AppLogger.info('Sync completed successfully', {
        'manual': isManual,
        'timestamp': now.toIso8601String(),
      });
      
    } catch (e, stackTrace) {
      AppLogger.error('Sync failed', error: e, stackTrace: stackTrace);
      
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
    }
    
    // 다음 동기화 예약
    if (!isManual) {
      _scheduleNextSync();
    }
  }

  Future<void> _performPull({bool forceFullSync = false}) async {
    // TODO: 사용자 인증 토큰 가져오기
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    // 연결된 캘린더 계정 조회
    final connections = await _getConnectedAccounts();
    if (connections.isEmpty) {
      AppLogger.info('No connected accounts, skipping pull');
      return;
    }

    final pullRequest = {
      'connection_ids': connections,
      'force_full': forceFullSync,
      'window_days_past': 90,
      'window_days_future': 180,
    };

    final response = await _httpRequestWithRetry(
      method: 'POST',
      path: '/api/sync/pull',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: pullRequest,
    );

    if (response.statusCode != 200) {
      throw Exception('Pull sync failed: ${response.statusCode}');
    }

    final result = jsonDecode(response.body);
    AppLogger.info('Pull sync queued', {'results': result['results']?.length ?? 0});
  }

  Future<void> _performPush() async {
    // 동기화 대기 중인 이벤트 조회
    final pendingEvents = await _database.getPendingEvents();
    
    if (pendingEvents.isEmpty) {
      AppLogger.debug('No pending events to push');
      return;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token available');
    }

    // 캘린더별로 그룹화하여 푸시
    final eventsByCalendar = <String, List<Event>>{};
    for (final event in pendingEvents) {
      eventsByCalendar.putIfAbsent(event.calendarId, () => []).add(event);
    }

    for (final entry in eventsByCalendar.entries) {
      final calendarId = entry.key;
      final events = entry.value;
      
      // 캘린더의 connection_id 조회
      final calendar = await (_database.select(_database.calendars)
        ..where((c) => c.id.equals(calendarId))).getSingleOrNull();
      
      if (calendar == null || calendar.sourcePlatform == 'internal') {
        continue; // 내부 캘린더는 푸시하지 않음
      }

      final connectionId = await _getConnectionIdForCalendar(calendar);
      if (connectionId == null) continue;

      try {
        await _pushEventsForConnection(connectionId, events, accessToken);
        
        // 성공한 이벤트들을 synced로 마킹
        for (final event in events) {
          await _database.markEventSynced(event.id);
        }
        
        AppLogger.info('Pushed events for calendar', {
          'calendar_id': calendarId,
          'event_count': events.length,
        });
        
      } catch (e) {
        AppLogger.error('Failed to push events for calendar $calendarId', error: e);
        // 개별 캘린더 실패는 전체 동기화를 중단하지 않음
        continue;
      }
    }
  }

  Future<void> _pushEventsForConnection(
    String connectionId, 
    List<Event> events, 
    String accessToken
  ) async {
    final pushData = events.map((event) => {
      'local_id': event.id,
      'external_event_id': event.externalEventId,
      'external_calendar_id': event.calendarId,
      'title': event.title,
      'description': event.description,
      'start_utc': DateTime.fromMillisecondsSinceEpoch(event.startUtcMs).toIso8601String(),
      'end_utc': event.endUtcMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(event.endUtcMs!).toIso8601String() 
        : null,
      'all_day': event.allDay,
      'location': event.location,
      'recurrence_rule': event.recurrenceRule,
      'attendees': [], // TODO: attendees 조회해서 포함
      'action': _determineEventAction(event),
    }).toList();

    final pushRequest = {
      'connection_id': connectionId,
      'events': pushData,
    };

    final response = await _httpRequestWithRetry(
      method: 'POST',
      path: '/api/sync/push',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: pushRequest,
    );

    if (response.statusCode != 200) {
      throw Exception('Push sync failed: ${response.statusCode}');
    }

    final result = jsonDecode(response.body);
    
    // 서버 응답에서 external_event_id 업데이트
    for (final eventResult in (result['results'] as List)) {
      if (eventResult['success'] == true) {
        final localId = eventResult['local_id'];
        final externalEventId = eventResult['external_event_id'];
        final externalVersion = eventResult['external_version'];
        final externalUpdatedAtStr = eventResult['external_updated_at'];
        
        if (externalEventId != null && externalUpdatedAtStr != null) {
          final externalUpdatedAt = DateTime.parse(externalUpdatedAtStr);
          await _database.markEventSynced(
            localId,
            externalEventId: externalEventId,
            externalVersion: externalVersion,
            externalUpdatedAt: externalUpdatedAt,
          );
        }
      }
    }
  }

  String _determineEventAction(Event event) {
    if (event.deleted) return 'delete';
    if (event.externalEventId == null) return 'create';
    return 'update';
  }

  Future<http.Response> _httpRequestWithRetry({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
    int maxRetries = _maxRetries,
  }) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$_baseUrl$path');
        final requestHeaders = {
          'Content-Type': 'application/json',
          ...?headers,
        };
        
        http.Response response;
        switch (method.toLowerCase()) {
          case 'get':
            response = await _httpClient.get(uri, headers: requestHeaders);
            break;
          case 'post':
            response = await _httpClient.post(
              uri, 
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }
        
        // 재시도 가능한 오류 확인
        if (response.statusCode >= 500 || response.statusCode == 429) {
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
        
        return response;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          // 지수 백오프 + 지터
          final delayMs = (pow(2, attempt) * 1000).toInt();
          final jitterMs = Random().nextInt(1000);
          final totalDelay = Duration(milliseconds: delayMs + jitterMs);
          
          AppLogger.warn('HTTP request failed, retrying', {
            'attempt': attempt + 1,
            'max_retries': maxRetries,
            'delay_ms': totalDelay.inMilliseconds,
            'error': e.toString(),
          });
          
          await Future.delayed(totalDelay);
        }
      }
    }
    
    throw lastException!;
  }

  Future<void> _updatePendingCount() async {
    final pendingEvents = await _database.getPendingEvents();
    _updateStatus(_currentStatus.copyWith(
      pendingEventCount: pendingEvents.length,
    ));
  }

  // 헬퍼 메서드들 (실제 구현에서는 다른 서비스에서 제공)
  Future<String?> _getAccessToken() async {
    // TODO: 인증 서비스에서 토큰 가져오기
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<String>> _getConnectedAccounts() async {
    // TODO: 연결된 외부 계정 ID 목록 조회
    final prefs = await SharedPreferences.getInstance();
    final connectionsJson = prefs.getString('connected_accounts');
    if (connectionsJson != null) {
      return List<String>.from(jsonDecode(connectionsJson));
    }
    return [];
  }

  Future<String?> _getConnectionIdForCalendar(Calendar calendar) async {
    // TODO: 캘린더의 외부 connection ID 매핑 조회
    final metadata = await _database.getSyncMetadata('connection_${calendar.sourcePlatform}');
    return metadata;
  }

  void dispose() {
    stop();
    _statusController.close();
    _httpClient.close();
  }
}

// Acceptance Criteria:
// - 자동 주기 동기화: 포그라운드 10분, 백그라운드 60분 간격
// - Pull/Push 분리로 서버↔로컬 양방향 동기화 지원
// - 지수 백오프로 네트워크 오류에 대한 재시도 처리
// - 스트림 기반으로 UI가 동기화 상태 실시간 추적 가능
// - 낙관적 업데이트와 sync_status로 로컬 변경사항 추적
"""