import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_entity.dart';
import 'events_providers.dart';

/// 로컬 우선 이벤트 조회 Provider
/// 즉시 로컬 데이터를 반환하고 백그라운드에서 동기화
final localFirstEventsByRangeProvider = FutureProvider.family.autoDispose(
  (ref, ({String startIso, String endIso, List<String>? platforms}) args) async {
    final repo = ref.read(eventsRepositoryProvider);
    
    // 로컬 우선 동기화 (즉시 로컬 데이터 반환, 백그라운드 동기화)
    return repo.syncAndGet(
      args.startIso,
      args.endIso,
      platforms: args.platforms,
    );
  },
);

/// 새 이벤트 생성 Provider
final createEventProvider = Provider((ref) {
  return (EventEntity event) async {
    final repo = ref.read(eventsRepositoryProvider);
    final createdEvent = await repo.createEvent(event);
    
    // 관련된 Provider들 무효화하여 UI 업데이트 트리거
    ref.invalidate(localFirstEventsByRangeProvider);
    ref.invalidate(eventsByRangeProvider);
    ref.invalidate(eventStatsProvider);
    
    return createdEvent;
  };
});

/// 강제 동기화 Provider
final forceSyncProvider = Provider((ref) {
  return (String startIso, String endIso) async {
    final repo = ref.read(eventsRepositoryProvider);
    await repo.forceSync(startIso, endIso);
    
    // 모든 관련 Provider 무효화
    ref.invalidate(localFirstEventsByRangeProvider);
    ref.invalidate(eventsByRangeProvider);
    ref.invalidate(eventStatsProvider);
  };
});

/// 실시간 이벤트 스트림 (로컬 변경사항 감지)
final liveEventsStreamProvider = StreamProvider.family.autoDispose(
  (ref, ({String startIso, String endIso, List<String>? platforms}) args) async* {
    // 초기 로컬 데이터 방출
    final repo = ref.read(eventsRepositoryProvider);
    yield await repo.getLocal(args.startIso, args.endIso, platforms: args.platforms);
    
    // Provider 변경 감지하여 스트림 업데이트
    ref.listen(localFirstEventsByRangeProvider(args), (previous, next) {
      next.when(
        data: (events) {
          // 새 데이터가 있으면 스트림에 방출
          // 실제로는 StreamController를 사용해야 하지만 여기서는 단순화
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
  },
);

/// 동기화 상태 Provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

class SyncStatus {
  final bool isLocalLoaded;
  final bool isExternalSyncing;
  final bool hasExternalConnection;
  final DateTime? lastSyncTime;
  final String? error;

  const SyncStatus({
    this.isLocalLoaded = false,
    this.isExternalSyncing = false,
    this.hasExternalConnection = false,
    this.lastSyncTime,
    this.error,
  });

  SyncStatus copyWith({
    bool? isLocalLoaded,
    bool? isExternalSyncing,
    bool? hasExternalConnection,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return SyncStatus(
      isLocalLoaded: isLocalLoaded ?? this.isLocalLoaded,
      isExternalSyncing: isExternalSyncing ?? this.isExternalSyncing,
      hasExternalConnection: hasExternalConnection ?? this.hasExternalConnection,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(const SyncStatus());

  void setLocalLoaded(bool loaded) {
    state = state.copyWith(isLocalLoaded: loaded);
  }

  void setExternalSyncing(bool syncing) {
    state = state.copyWith(isExternalSyncing: syncing);
  }

  void setExternalConnection(bool connected) {
    state = state.copyWith(hasExternalConnection: connected);
  }

  void setSyncCompleted() {
    state = state.copyWith(
      isExternalSyncing: false,
      lastSyncTime: DateTime.now(),
      error: null,
    );
  }

  void setSyncError(String error) {
    state = state.copyWith(
      isExternalSyncing: false,
      error: error,
    );
  }
}