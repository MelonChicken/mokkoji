import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/events/data/events_repository.dart';

/// 앱 생명주기 기반 자동 동기화 관리자
class AppLifecycleSync with WidgetsBindingObserver {
  final ProviderContainer container;
  final String Function() getCurrentRangeStart;
  final String Function() getCurrentRangeEnd;
  
  Timer? _backgroundSyncTimer;
  DateTime? _lastSyncTime;
  bool _isInBackground = false;

  AppLifecycleSync({
    required this.container,
    required this.getCurrentRangeStart,
    required this.getCurrentRangeEnd,
  });

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundSyncTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        // iOS 전용 상태 - paused와 유사하게 처리
        _onAppPaused();
        break;
    }
  }

  void _onAppResumed() {
    _isInBackground = false;
    _backgroundSyncTimer?.cancel();

    // 포그라운드 복귀 시 동기화
    final shouldSync = _lastSyncTime == null || 
        DateTime.now().difference(_lastSyncTime!).inMinutes >= 5;

    if (shouldSync) {
      _performSync('foreground_resume');
    }
  }

  void _onAppPaused() {
    _isInBackground = true;
    _startBackgroundSync();
  }

  void _onAppDetached() {
    _backgroundSyncTimer?.cancel();
  }

  void _startBackgroundSync() {
    // 백그라운드에서 주기적 동기화 (15분 간격)
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        if (_isInBackground) {
          _performSync('background');
        }
      },
    );
  }

  Future<void> _performSync(String reason) async {
    try {
      final repo = container.read(eventsRepositoryProvider);
      final startIso = getCurrentRangeStart();
      final endIso = getCurrentRangeEnd();
      
      await repo.syncAndGet(startIso, endIso);
      _lastSyncTime = DateTime.now();
      
      debugPrint('AppLifecycleSync: Synced [$reason] at ${_lastSyncTime}');
    } catch (e) {
      debugPrint('AppLifecycleSync: Sync failed [$reason]: $e');
    }
  }

  /// 수동 동기화 트리거
  Future<void> forcSync({String reason = 'manual'}) async {
    return _performSync(reason);
  }

  /// 현재 동기화 상태 정보
  Map<String, dynamic> get status => {
    'lastSyncTime': _lastSyncTime?.toIso8601String(),
    'isInBackground': _isInBackground,
    'hasBackgroundTimer': _backgroundSyncTimer?.isActive == true,
  };
}

/// 전역 앱 생명주기 sync 인스턴스를 위한 provider
final appLifecycleSyncProvider = Provider<AppLifecycleSync>((ref) {
  throw UnimplementedError('AppLifecycleSync must be provided in main.dart');
});

/// 현재 보이는 달력 범위를 추적하는 provider (UI에서 설정)
final visibleRangeProvider = StateProvider<({String startIso, String endIso})?>((ref) => null);

/// 자동 동기화 상태 provider
final autoSyncStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final sync = ref.watch(appLifecycleSyncProvider);
  return sync.status;
});