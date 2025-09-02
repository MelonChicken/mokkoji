import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/events_repository.dart';
import 'events_providers.dart';

typedef RangeArgs = ({String startIso, String endIso, List<String>? platforms});

/// 디바운스된 범위 동기화 provider
/// 달력 범위 변경 시 과도한 API 호출을 방지
class DebouncedSyncNotifier extends FamilyAsyncNotifier<void, RangeArgs> {
  Timer? _debounceTimer;
  
  @override
  Future<void> build(RangeArgs args) async {
    // 최초 빌드 시에는 즉시 동기화하지 않음
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
  }

  /// 디바운스된 동기화 실행
  void scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSync();
    });
  }

  /// 즉시 동기화 실행 (디바운스 무시)
  void syncNow() {
    _debounceTimer?.cancel();
    _performSync();
  }

  Future<void> _performSync() async {
    final args = arg;
    state = const AsyncLoading();
    
    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.syncAndGet(
        args.startIso,
        args.endIso,
        platforms: args.platforms,
      );
      
      if (mounted) {
        state = const AsyncData(null);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}

final debouncedSyncProvider = AsyncNotifierProvider.family<DebouncedSyncNotifier, void, RangeArgs>(
  DebouncedSyncNotifier.new,
);

/// 범위 변경 시 자동으로 디바운스된 동기화를 트리거하는 provider
final autoRangeSyncProvider = Provider.family.autoDispose<void, RangeArgs>(
  (ref, args) {
    final notifier = ref.read(debouncedSyncProvider(args).notifier);
    
    // 범위가 변경될 때마다 디바운스된 동기화 예약
    Future.microtask(() {
      notifier.scheduleSync();
    });

    ref.onDispose(() {
      // dispose 시 예약된 동기화 취소
      ref.read(debouncedSyncProvider(args).notifier)._debounceTimer?.cancel();
    });
  },
);

/// 네트워크 상태 기반 동기화 provider
final networkAwareSyncProvider = Provider.family.autoDispose<void, RangeArgs>(
  (ref, args) {
    // TODO: 네트워크 상태 감지 로직 추가
    // connectivity_plus 패키지 사용 시:
    // final connectivity = ref.watch(connectivityProvider);
    // if (connectivity == ConnectivityResult.none) return;
    
    ref.read(autoRangeSyncProvider(args));
  },
);

/// 스마트 동기화 전략 provider
/// - 포그라운드 복귀: 즉시 동기화
/// - 범위 변경: 디바운스된 동기화  
/// - 네트워크 재연결: 즉시 동기화
class SmartSyncNotifier extends FamilyAsyncNotifier<void, RangeArgs> {
  @override
  Future<void> build(RangeArgs args) async {
    // 초기화는 별도로 수행하지 않음
  }

  /// 포그라운드 복귀 시 즉시 동기화
  Future<void> onForegroundResume() async {
    return _syncNow();
  }

  /// 범위 변경 시 디바운스된 동기화
  void onRangeChanged() {
    final debouncedNotifier = ref.read(debouncedSyncProvider(arg).notifier);
    debouncedNotifier.scheduleSync();
  }

  /// 네트워크 재연결 시 즉시 동기화
  Future<void> onNetworkReconnected() async {
    return _syncNow();
  }

  Future<void> _syncNow() async {
    final args = arg;
    state = const AsyncLoading();
    
    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.syncAndGet(
        args.startIso,
        args.endIso,
        platforms: args.platforms,
      );
      
      if (mounted) {
        state = const AsyncData(null);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}

final smartSyncProvider = AsyncNotifierProvider.family<SmartSyncNotifier, void, RangeArgs>(
  SmartSyncNotifier.new,
);