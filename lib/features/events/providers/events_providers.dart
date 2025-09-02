import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/events_dao.dart';
import '../data/event_overrides_dao.dart';
import '../data/events_repository.dart';

// DAO Providers
final eventsDaoProvider = Provider<EventsDao>((ref) => EventsDao());

final eventOverridesDaoProvider = Provider<EventOverridesDao>(
  (ref) => EventOverridesDao(),
);

// API Provider (to be bound in main.dart)
final eventsApiProvider = Provider<EventsApi>(
  (ref) => throw UnimplementedError('Bind real API in main'),
);

// Repository Provider
final eventsRepositoryProvider = Provider<EventsRepository>((ref) =>
    EventsRepository(
      dao: ref.read(eventsDaoProvider),
      overridesDao: ref.read(eventOverridesDaoProvider),
      api: ref.read(eventsApiProvider),
    ));

// 날짜 범위별 이벤트 (Family)
final eventsByRangeProvider = FutureProvider.family.autoDispose(
  (ref, ({String startIso, String endIso, List<String>? platforms}) args) async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.syncAndGet(
      args.startIso,
      args.endIso,
      platforms: args.platforms,
    );
  },
);

// 로컬 전용 이벤트 조회 (오프라인)
final localEventsByRangeProvider = FutureProvider.family.autoDispose(
  (ref, ({String startIso, String endIso, List<String>? platforms}) args) async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.getLocal(
      args.startIso,
      args.endIso,
      platforms: args.platforms,
    );
  },
);

// 특정 이벤트 조회
final eventByIdProvider = FutureProvider.family.autoDispose(
  (ref, String id) async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.getById(id);
  },
);

final eventByIcalUidProvider = FutureProvider.family.autoDispose(
  (ref, String icalUid) async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.getByIcalUid(icalUid);
  },
);

// 반복 이벤트 오버라이드 조회
final eventOverridesProvider = FutureProvider.family.autoDispose(
  (ref, ({String icalUid, String? startIso, String? endIso}) args) async {
    final repo = ref.read(eventsRepositoryProvider);
    return repo.getOverrides(
      args.icalUid,
      startIso: args.startIso,
      endIso: args.endIso,
    );
  },
);

// 통계 정보
final eventStatsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final eventCount = await repo.getEventCount();
  final overrideCount = await repo.getOverrideCount();
  
  return {
    'eventCount': eventCount,
    'overrideCount': overrideCount,
  };
});