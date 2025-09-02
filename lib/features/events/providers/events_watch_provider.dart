import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/events_repository.dart';
import '../data/event_entity.dart';
import '../../../db/db_signal.dart';
import 'events_providers.dart';

typedef RangeArgs = ({String startIso, String endIso, List<String>? platforms});

/// 실시간 이벤트 구독 provider - DB 변경 시 자동 업데이트
final eventsWatchProvider = StreamProvider.family.autoDispose<List<EventEntity>, RangeArgs>(
  (ref, args) {
    final repo = ref.watch(eventsRepositoryProvider);
    final controller = StreamController<List<EventEntity>>();

    // 최초 로드: 동기화 시도 + 로컬 반환
    repo.syncAndGet(
      args.startIso,
      args.endIso,
      platforms: args.platforms,
    ).then(controller.add).catchError(controller.addError);

    // DB 변경 신호 구독 → 로컬에서 즉시 재조회 (빠르고 오프라인에서도 동작)
    final subscription = DbSignal.instance.eventsStream.listen((_) async {
      try {
        final data = await repo.dao.range(
          args.startIso,
          args.endIso,
          platforms: args.platforms,
        );
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });

    // 정리
    ref.onDispose(() {
      subscription.cancel();
      controller.close();
    });

    return controller.stream;
  },
);

/// 로컬 전용 실시간 구독 (동기화 없음)
final localEventsWatchProvider = StreamProvider.family.autoDispose<List<EventEntity>, RangeArgs>(
  (ref, args) {
    final repo = ref.watch(eventsRepositoryProvider);
    final controller = StreamController<List<EventEntity>>();

    // 최초 로컬 로드
    repo.getLocal(
      args.startIso,
      args.endIso,
      platforms: args.platforms,
    ).then(controller.add).catchError(controller.addError);

    // DB 변경 신호 구독 → 로컬에서 즉시 재조회
    final subscription = DbSignal.instance.eventsStream.listen((_) async {
      try {
        final data = await repo.dao.range(
          args.startIso,
          args.endIso,
          platforms: args.platforms,
        );
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });

    // 정리
    ref.onDispose(() {
      subscription.cancel();
      controller.close();
    });

    return controller.stream;
  },
);

/// 디바운스된 동기화 provider (범위 변경 시 과도한 API 호출 방지)
final debouncedSyncProvider = Provider.family.autoDispose<void, RangeArgs>(
  (ref, args) {
    Timer? debounceTimer;

    void performSync() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        ref.read(eventsRepositoryProvider).syncAndGet(
          args.startIso,
          args.endIso,
          platforms: args.platforms,
        );
      });
    }

    // 즉시 실행하지 않고 디바운스 적용
    performSync();

    ref.onDispose(() {
      debounceTimer?.cancel();
    });
  },
);