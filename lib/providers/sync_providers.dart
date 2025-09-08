"""Riverpod providers for sync service integration

설계 의도:
- SyncService를 Riverpod으로 DI하여 전역 상태 관리
- 동기화 상태 스트림을 StreamProvider로 반응형 UI 구현
- 라이프사이클 관리로 백그라운드/포그라운드 자동 전환

"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../services/sync_service.dart';
import '../data/local/app_database.dart';
import '../providers/database_provider.dart';

/// 동기화 서비스 제공자
final syncServiceProvider = Provider<CalendarSyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final httpClient = http.Client();
  
  final service = CalendarSyncService(database, httpClient);
  
  // 앱 시작 시 서비스 시작
  service.start();
  
  // Provider 해제 시 정리
  ref.onDispose(() {
    service.dispose();
    httpClient.close();
  });
  
  return service;
});

/// 동기화 상태 스트림 제공자
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});

/// 현재 동기화 상태 제공자 (동기적)
final currentSyncStatusProvider = Provider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.currentStatus;
});

/// 앱 라이프사이클 관리 제공자
final appLifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return AppLifecycleManager(syncService);
});

class AppLifecycleManager with WidgetsBindingObserver {
  final CalendarSyncService _syncService;
  
  AppLifecycleManager(this._syncService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _syncService.setBackgroundMode(false);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _syncService.setBackgroundMode(true);
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// 수동 동기화 액션 제공자
final manualSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final service = ref.watch(syncServiceProvider);
  await service.syncNow();
});

/// 서버 풀 전용 제공자
final pullSyncProvider = FutureProvider.autoDispose.family<void, bool>((ref, forceFullSync) async {
  final service = ref.watch(syncServiceProvider);
  await service.pullFromServer(forceFullSync: forceFullSync);
});

/// 서버 푸시 전용 제공자  
final pushSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final service = ref.watch(syncServiceProvider);
  await service.pushToServer();
});

/// 동기화 통계 제공자
final syncStatsProvider = Provider<SyncStats>((ref) {
  final status = ref.watch(currentSyncStatusProvider);
  final database = ref.watch(databaseProvider);
  
  return SyncStats(
    currentStatus: status,
    database: database,
  );
});

class SyncStats {
  final SyncStatus currentStatus;
  final AppDatabase database;
  
  SyncStats({required this.currentStatus, required this.database});
  
  /// 대기 중인 이벤트 수 조회
  Future<int> getPendingEventsCount() async {
    final events = await database.getPendingEvents();
    return events.length;
  }
  
  /// 총 이벤트 수 조회
  Future<int> getTotalEventsCount() async {
    final events = await (database.select(database.events)
      ..where((e) => e.deleted.equals(false))).get();
    return events.length;
  }
  
  /// 마지막 동기화 후 경과 시간
  Duration? getTimeSinceLastSync() {
    if (currentStatus.lastSyncAt == null) return null;
    return DateTime.now().difference(currentStatus.lastSyncAt!);
  }
  
  /// 동기화 필요 여부
  bool get needsSync {
    final timeSinceSync = getTimeSinceLastSync();
    if (timeSinceSync == null) return true;
    
    // 15분 이상 지났거나 대기 중인 이벤트가 있으면 동기화 필요
    return timeSinceSync > const Duration(minutes: 15) || 
           currentStatus.pendingEventCount > 0;
  }
}

/// 동기화 설정 제공자
final syncSettingsProvider = StateNotifierProvider<SyncSettingsNotifier, SyncSettings>((ref) {
  return SyncSettingsNotifier();
});

class SyncSettings {
  final bool autoSyncEnabled;
  final Duration foregroundSyncInterval;
  final Duration backgroundSyncInterval;
  final bool wifiOnlySync;
  
  const SyncSettings({
    this.autoSyncEnabled = true,
    this.foregroundSyncInterval = const Duration(minutes: 10),
    this.backgroundSyncInterval = const Duration(minutes: 60),
    this.wifiOnlySync = false,
  });
  
  SyncSettings copyWith({
    bool? autoSyncEnabled,
    Duration? foregroundSyncInterval,
    Duration? backgroundSyncInterval,
    bool? wifiOnlySync,
  }) {
    return SyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      foregroundSyncInterval: foregroundSyncInterval ?? this.foregroundSyncInterval,
      backgroundSyncInterval: backgroundSyncInterval ?? this.backgroundSyncInterval,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
    );
  }
}

class SyncSettingsNotifier extends StateNotifier<SyncSettings> {
  SyncSettingsNotifier() : super(const SyncSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // TODO: SharedPreferences에서 설정 로드
    // final prefs = await SharedPreferences.getInstance();
    // state = SyncSettings(
    //   autoSyncEnabled: prefs.getBool('auto_sync_enabled') ?? true,
    //   wifiOnlySync: prefs.getBool('wifi_only_sync') ?? false,
    // );
  }
  
  Future<void> updateAutoSyncEnabled(bool enabled) async {
    state = state.copyWith(autoSyncEnabled: enabled);
    // TODO: SharedPreferences에 저장
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('auto_sync_enabled', enabled);
  }
  
  Future<void> updateWifiOnlySync(bool wifiOnly) async {
    state = state.copyWith(wifiOnlySync: wifiOnly);
    // TODO: SharedPreferences에 저장
  }
}

// Acceptance Criteria:
// - SyncService가 Riverpod Provider로 전역 상태 관리
// - StreamProvider로 동기화 상태 실시간 UI 반영
// - AppLifecycleManager로 백그라운드/포그라운드 자동 전환
// - 수동 동기화, pull/push 전용 액션 제공자 분리
// - 동기화 통계와 설정을 별도 provider로 관리
"""