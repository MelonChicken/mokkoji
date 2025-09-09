import 'package:flutter_test/flutter_test.dart';
import 'package:mokkoji/data/repositories/event_repository.dart';
import 'package:mokkoji/features/events/data/events_dao.dart';
import 'package:mokkoji/features/events/data/event_entity.dart';
import 'package:mokkoji/core/time/app_time.dart';

class MockEventsDao implements EventsDao {
  final List<EventEntity> _events = [];
  
  @override
  Future<void> upsertAll(List<EventEntity> items) async {
    _events.addAll(items);
  }
  
  @override
  Future<void> upsert(EventEntity item) async {
    final index = _events.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      _events[index] = item;
    } else {
      _events.add(item);
    }
  }
  
  @override
  Future<List<EventEntity>> range(String startIso, String endIso, {List<String>? platforms}) async {
    final start = DateTime.parse(startIso);
    final end = DateTime.parse(endIso);
    
    return _events.where((event) {
      if (event.deletedAt != null) return false;
      
      final eventStart = DateTime.parse(event.startDt);
      final eventEnd = event.endDt != null 
          ? DateTime.parse(event.endDt!) 
          : eventStart.add(const Duration(hours: 1));
      
      // 교집합 검사: (start < eventEnd) && (end > eventStart)
      return start.isBefore(eventEnd) && end.isAfter(eventStart);
    }).toList();
  }
  
  // 다른 메서드들은 테스트에서 사용하지 않음
  @override
  Future<EventEntity?> getById(String id) => throw UnimplementedError();
  @override
  Future<void> softDelete(String id, String deletedAt) => throw UnimplementedError();
  @override
  Future<void> hardDelete(String id) => throw UnimplementedError();
  @override
  Future<int> countAll() => throw UnimplementedError();
}

void main() {
  group('Today Stream Consistency Tests', () {
    late EventRepository repository;
    late MockEventsDao mockDao;

    setUp(() {
      mockDao = MockEventsDao();
      repository = EventRepository(mockDao);
    });

    testWidgets('Summary and Timeline should show same events', (tester) async {
      // 테스트 데이터 준비 - KST 2024-01-15 기준
      final testDate = DateTime(2024, 1, 15); // KST 날짜
      final now = DateTime.now();
      
      // 경계값 테스트 이벤트들
      await mockDao.upsertAll([
        // 1) 00:00 시작 이벤트 (KST -> UTC 변환해서 저장)
        EventEntity(
          id: 'midnight-start',
          title: '자정 시작 이벤트',
          startDt: DateTime(2024, 1, 15, 0, 0).subtract(const Duration(hours: 9)).toIso8601String(), // UTC
          endDt: DateTime(2024, 1, 15, 1, 0).subtract(const Duration(hours: 9)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'test',
          updatedAt: now.toIso8601String(),
        ),
        
        // 2) 23:59 시작 이벤트
        EventEntity(
          id: 'late-night',
          title: '늦은 밤 이벤트',
          startDt: DateTime(2024, 1, 15, 23, 59).subtract(const Duration(hours: 9)).toIso8601String(),
          endDt: DateTime(2024, 1, 16, 0, 59).subtract(const Duration(hours: 9)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'test',
          updatedAt: now.toIso8601String(),
        ),
        
        // 3) KST 21:01 이벤트 (UTC 12:01)
        EventEntity(
          id: 'evening-event',
          title: 'KST 저녁 이벤트',
          startDt: DateTime(2024, 1, 15, 21, 1).subtract(const Duration(hours: 9)).toIso8601String(),
          endDt: DateTime(2024, 1, 15, 22, 1).subtract(const Duration(hours: 9)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'test',
          updatedAt: now.toIso8601String(),
        ),
        
        // 4) 하루 종일 이벤트
        EventEntity(
          id: 'all-day',
          title: '하루 종일 이벤트',
          startDt: DateTime(2024, 1, 15).subtract(const Duration(hours: 9)).toIso8601String(),
          endDt: null,
          allDay: true,
          sourcePlatform: 'test',
          updatedAt: now.toIso8601String(),
        ),
        
        // 5) 경계 외부 이벤트 (포함되지 않아야 함)
        EventEntity(
          id: 'outside-range',
          title: '범위 외부 이벤트',
          startDt: DateTime(2024, 1, 16, 1, 0).subtract(const Duration(hours: 9)).toIso8601String(),
          endDt: DateTime(2024, 1, 16, 2, 0).subtract(const Duration(hours: 9)).toIso8601String(),
          allDay: false,
          sourcePlatform: 'test',
          updatedAt: now.toIso8601String(),
        ),
      ]);

      // 스트림에서 데이터 가져오기
      final occurrencesStream = repository.watchOccurrencesForDayKst(testDate);
      final summaryStream = repository.watchTodaySummary();

      // 첫 번째 값 대기
      final occurrences = await occurrencesStream.first;
      final summary = await summaryStream.first;

      // 검증
      expect(occurrences.length, equals(4)); // 범위 내 4개 이벤트
      expect(summary.count, equals(4)); // 요약에서도 동일한 개수
      
      // 특정 이벤트들이 포함되었는지 확인
      expect(occurrences.any((o) => o.id == 'midnight-start'), isTrue);
      expect(occurrences.any((o) => o.id == 'late-night'), isTrue);
      expect(occurrences.any((o) => o.id == 'evening-event'), isTrue);
      expect(occurrences.any((o) => o.id == 'all-day'), isTrue);
      expect(occurrences.any((o) => o.id == 'outside-range'), isFalse);
      
      // KST 시각 검증
      final eveningEvent = occurrences.firstWhere((o) => o.id == 'evening-event');
      expect(eveningEvent.startKst.hour, equals(21));
      expect(eveningEvent.startKst.minute, equals(1));
      
      // 최소 지속시간 검증 (0분 이벤트 방지)
      for (final occ in occurrences) {
        expect(occ.durationMinutes, greaterThanOrEqualTo(1));
      }
    });

    test('Boundary overlap logic works correctly', () {
      // 교집합 로직 테스트: (start < dayEnd) && (end > dayStart)
      final dayStart = DateTime(2024, 1, 15, 0, 0); // KST
      final dayEnd = DateTime(2024, 1, 16, 0, 0);   // KST (exclusive)
      
      // 테스트 케이스들
      final testCases = [
        // (eventStart, eventEnd, shouldInclude)
        (DateTime(2024, 1, 14, 23, 30), DateTime(2024, 1, 15, 0, 30), true),  // 전날부터 시작
        (DateTime(2024, 1, 15, 0, 0), DateTime(2024, 1, 15, 1, 0), true),     // 자정 시작
        (DateTime(2024, 1, 15, 12, 0), DateTime(2024, 1, 15, 13, 0), true),   // 중간
        (DateTime(2024, 1, 15, 23, 30), DateTime(2024, 1, 16, 0, 30), true),  // 다음날까지
        (DateTime(2024, 1, 16, 0, 0), DateTime(2024, 1, 16, 1, 0), false),    // 다음날 자정 (제외)
        (DateTime(2024, 1, 14, 22, 0), DateTime(2024, 1, 14, 23, 0), false),  // 완전히 전날
      ];
      
      for (final (start, end, shouldInclude) in testCases) {
        final overlaps = start.isBefore(dayEnd) && end.isAfter(dayStart);
        expect(overlaps, equals(shouldInclude), 
          reason: 'Event $start-$end should ${shouldInclude ? 'be included' : 'be excluded'}');
      }
    });
    
    test('KST conversion is consistent', () {
      // UTC와 KST 간 변환이 일관되는지 검증
      final utcTime = DateTime.utc(2024, 1, 15, 12, 0); // UTC 12:00
      final kstTime = AppTime.toKst(utcTime);            // KST 21:00
      
      expect(kstTime.hour, equals(21));
      expect(kstTime.minute, equals(0));
      
      // 반대 변환도 확인
      final backToUtc = kstTime.subtract(const Duration(hours: 9));
      expect(backToUtc.hour, equals(12));
    });
  });
}