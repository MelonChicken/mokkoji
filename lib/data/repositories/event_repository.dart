// Simple event repository using the existing working database system
// Provides basic event creation functionality

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../db/db_signal.dart';
import '../../core/time/app_time.dart';
import '../models/today_summary_data.dart';

class EventRepository {
  final EventsDao _dao;
  
  EventRepository(this._dao);
  
  /// KST 기준 날짜의 시작 시각 (00:00:00)
  DateTime dayStartKst(DateTime kst) => DateTime(kst.year, kst.month, kst.day);
  
  /// KST 기준 날짜의 종료 시각 (다음날 00:00:00, exclusive)
  DateTime dayEndExclusiveKst(DateTime kst) => dayStartKst(kst).add(const Duration(days: 1));

  // Initialize repository
  Future<void> initialize() async {
    if (kDebugMode) debugPrint('EventRepository initializing...');
    
    // 기존 이벤트 개수 확인
    final existingCount = await _dao.countAll();
    if (kDebugMode) debugPrint('Found $existingCount existing events');
    
    // Mock 데이터가 아직 추가되지 않았다면 추가
    if (existingCount < 30) { // Mock 데이터 30개보다 적으면
      await _seedMockData();
    }
    
    if (kDebugMode) debugPrint('EventRepository initialized');
  }

  // Mock 데이터를 데이터베이스에 시드로 추가 (30개의 다양한 이벤트)
  Future<void> _seedMockData() async {
    if (kDebugMode) debugPrint('Seeding 30 mock events to database...');
    
    final now = DateTime.now();
    final mockEvents = [
      // 업무 관련 일정 (10개)
      EventEntity(
        id: 'mock-work-1',
        title: '프로젝트 킥오프 미팅',
        description: '새로운 프로젝트 시작을 위한 전체 팀 미팅',
        startDt: now.add(const Duration(days: 1, hours: 9)).toIso8601String(),
        endDt: now.add(const Duration(days: 1, hours: 10, minutes: 30)).toIso8601String(),
        allDay: false,
        location: '본사 대회의실',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-2',
        title: '클라이언트 프레젠테이션',
        description: '분기별 성과 발표 및 차기 계획 공유',
        startDt: now.add(const Duration(days: 2, hours: 14)).toIso8601String(),
        endDt: now.add(const Duration(days: 2, hours: 16)).toIso8601String(),
        allDay: false,
        location: '강남구 삼성동 코엑스',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-3',
        title: '코드 리뷰',
        description: 'Flutter 앱 코드 품질 검토',
        startDt: now.add(const Duration(days: 3, hours: 10)).toIso8601String(),
        endDt: now.add(const Duration(days: 3, hours: 11, minutes: 30)).toIso8601String(),
        allDay: false,
        location: '온라인 (Zoom)',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-4',
        title: '월간 전체 회의',
        description: '팀별 성과 공유 및 차월 목표 설정',
        startDt: now.add(const Duration(days: 5, hours: 15)).toIso8601String(),
        endDt: now.add(const Duration(days: 5, hours: 17)).toIso8601String(),
        allDay: false,
        location: '본사 오디토리움',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-5',
        title: '신입사원 온보딩',
        description: '새로운 팀원 맞이하기',
        startDt: now.add(const Duration(days: 8, hours: 9)).toIso8601String(),
        endDt: now.add(const Duration(days: 8, hours: 12)).toIso8601String(),
        allDay: false,
        location: '인사팀 교육실',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-6',
        title: 'UX 워크숍',
        description: '사용자 경험 개선을 위한 아이디어 도출',
        startDt: now.add(const Duration(days: 10, hours: 13, minutes: 30)).toIso8601String(),
        endDt: now.add(const Duration(days: 10, hours: 17)).toIso8601String(),
        allDay: false,
        location: '디자인팀 크리에이티브룸',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-7',
        title: '스프린트 회고',
        description: '2주간의 개발 과정 돌아보기',
        startDt: now.add(const Duration(days: 12, hours: 16)).toIso8601String(),
        endDt: now.add(const Duration(days: 12, hours: 17)).toIso8601String(),
        allDay: false,
        location: '개발팀 미팅룸',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-8',
        title: '보안 교육',
        description: '정보보안 및 개인정보보호 교육',
        startDt: now.add(const Duration(days: 15, hours: 14)).toIso8601String(),
        endDt: now.add(const Duration(days: 15, hours: 16)).toIso8601String(),
        allDay: false,
        location: '온라인 교육',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-9',
        title: '분기별 평가',
        description: '개인별 성과 평가 및 피드백',
        startDt: now.add(const Duration(days: 20, hours: 11)).toIso8601String(),
        endDt: now.add(const Duration(days: 20, hours: 12)).toIso8601String(),
        allDay: false,
        location: '상사 사무실',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-work-10',
        title: '기술 세미나',
        description: 'AI/ML 최신 트렌드 공유',
        startDt: now.add(const Duration(days: 22, hours: 10)).toIso8601String(),
        endDt: now.add(const Duration(days: 22, hours: 12)).toIso8601String(),
        allDay: false,
        location: '강남구 테헤란로 컨퍼런스센터',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),

      // 개인 일정 (10개)
      EventEntity(
        id: 'mock-personal-1',
        title: '치과 검진',
        description: '6개월 정기 검진',
        startDt: now.add(const Duration(days: 1, hours: 18)).toIso8601String(),
        endDt: now.add(const Duration(days: 1, hours: 19)).toIso8601String(),
        allDay: false,
        location: '강남 스마일 치과',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-2',
        title: '헬스장 PT',
        description: '개인 트레이닝 세션',
        startDt: now.add(const Duration(days: 3, hours: 19, minutes: 30)).toIso8601String(),
        endDt: now.add(const Duration(days: 3, hours: 20, minutes: 30)).toIso8601String(),
        allDay: false,
        location: '동네 피트니스센터',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-3',
        title: '독서 모임',
        description: '이달의 책: "클린 코드" 토론',
        startDt: now.add(const Duration(days: 6, hours: 14)).toIso8601String(),
        endDt: now.add(const Duration(days: 6, hours: 16)).toIso8601String(),
        allDay: false,
        location: '홍대 북카페',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-4',
        title: '부모님 생신',
        description: '아버지 생신 가족 모임',
        startDt: now.add(const Duration(days: 9)).toIso8601String(),
        endDt: null,
        allDay: true,
        location: '집',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-5',
        title: '영화 관람',
        description: '친구와 함께 보는 최신 영화',
        startDt: now.add(const Duration(days: 11, hours: 20)).toIso8601String(),
        endDt: now.add(const Duration(days: 11, hours: 22, minutes: 30)).toIso8601String(),
        allDay: false,
        location: 'CGV 강남',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-6',
        title: '요가 클래스',
        description: '주말 아침 요가',
        startDt: now.add(const Duration(days: 13, hours: 8)).toIso8601String(),
        endDt: now.add(const Duration(days: 13, hours: 9, minutes: 30)).toIso8601String(),
        allDay: false,
        location: '동네 요가 스튜디오',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-7',
        title: '쇼핑',
        description: '겨울 옷 쇼핑',
        startDt: now.add(const Duration(days: 16, hours: 15)).toIso8601String(),
        endDt: now.add(const Duration(days: 16, hours: 18)).toIso8601String(),
        allDay: false,
        location: '명동 쇼핑가',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-8',
        title: '맛집 탐방',
        description: '인스타에서 본 핫플레이스 방문',
        startDt: now.add(const Duration(days: 18, hours: 12)).toIso8601String(),
        endDt: now.add(const Duration(days: 18, hours: 14)).toIso8601String(),
        allDay: false,
        location: '성수동 카페거리',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-9',
        title: '게임 모임',
        description: '친구들과 보드게임 카페',
        startDt: now.add(const Duration(days: 21, hours: 19)).toIso8601String(),
        endDt: now.add(const Duration(days: 21, hours: 22)).toIso8601String(),
        allDay: false,
        location: '홍대 보드게임카페',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-personal-10',
        title: '집 정리',
        description: '대청소 및 정리정돈',
        startDt: now.add(const Duration(days: 25, hours: 10)).toIso8601String(),
        endDt: now.add(const Duration(days: 25, hours: 16)).toIso8601String(),
        allDay: false,
        location: '집',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),

      // 사회적 일정 (10개)
      EventEntity(
        id: 'mock-social-1',
        title: '대학 동창회',
        description: '졸업 5주년 기념 모임',
        startDt: now.add(const Duration(days: 4, hours: 18, minutes: 30)).toIso8601String(),
        endDt: now.add(const Duration(days: 4, hours: 21)).toIso8601String(),
        allDay: false,
        location: '강남역 모임 장소',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-2',
        title: '결혼식 참석',
        description: '동료 결혼식 축하',
        startDt: now.add(const Duration(days: 7, hours: 12)).toIso8601String(),
        endDt: now.add(const Duration(days: 7, hours: 16)).toIso8601String(),
        allDay: false,
        location: '잠실 웨딩홀',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-3',
        title: '아기 돌잔치',
        description: '친구 아이 돌잔치',
        startDt: now.add(const Duration(days: 14, hours: 13)).toIso8601String(),
        endDt: now.add(const Duration(days: 14, hours: 16)).toIso8601String(),
        allDay: false,
        location: '수원 한정식집',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-4',
        title: '고등학교 동창회',
        description: '20년만의 만남',
        startDt: now.add(const Duration(days: 17, hours: 19)).toIso8601String(),
        endDt: now.add(const Duration(days: 17, hours: 22)).toIso8601String(),
        allDay: false,
        location: '모교 근처 식당',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-5',
        title: '번개 모임',
        description: '직장인 소모임 번개',
        startDt: now.add(const Duration(days: 19, hours: 20)).toIso8601String(),
        endDt: now.add(const Duration(days: 19, hours: 23)).toIso8601String(),
        allDay: false,
        location: '홍대 펍',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-6',
        title: '자원봉사',
        description: '지역 아동센터 봉사활동',
        startDt: now.add(const Duration(days: 23, hours: 9)).toIso8601String(),
        endDt: now.add(const Duration(days: 23, hours: 12)).toIso8601String(),
        allDay: false,
        location: '마포구 아동센터',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-7',
        title: '동호회 모임',
        description: '사진 동호회 정기 모임',
        startDt: now.add(const Duration(days: 26, hours: 14)).toIso8601String(),
        endDt: now.add(const Duration(days: 26, hours: 18)).toIso8601String(),
        allDay: false,
        location: '남산 공원',
        sourcePlatform: 'google',
        platformColor: '#4285f4',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-8',
        title: '송년회',
        description: '회사 부서 송년회',
        startDt: now.add(const Duration(days: 30, hours: 18)).toIso8601String(),
        endDt: now.add(const Duration(days: 30, hours: 21)).toIso8601String(),
        allDay: false,
        location: '강남 고급 한정식',
        sourcePlatform: 'internal',
        platformColor: '#34a853',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-9',
        title: '콘서트 관람',
        description: '좋아하는 가수 콘서트',
        startDt: now.add(const Duration(days: 35, hours: 19)).toIso8601String(),
        endDt: now.add(const Duration(days: 35, hours: 22)).toIso8601String(),
        allDay: false,
        location: '올림픽공원 체조경기장',
        sourcePlatform: 'kakao',
        platformColor: '#FEE500',
        updatedAt: now.toIso8601String(),
      ),
      EventEntity(
        id: 'mock-social-10',
        title: '지역 축제',
        description: '가을 문화 축제 참여',
        startDt: now.add(const Duration(days: 40)).toIso8601String(),
        endDt: null,
        allDay: true,
        location: '한강 공원',
        sourcePlatform: 'naver',
        platformColor: '#03C75A',
        updatedAt: now.toIso8601String(),
      ),
    ];

    for (final event in mockEvents) {
      try {
        await _dao.upsert(event);
        if (kDebugMode) debugPrint('✅ Seeded mock event: ${event.title}');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Failed to seed ${event.title}: $e');
      }
    }
    
    if (kDebugMode) debugPrint('✅ Successfully seeded ${mockEvents.length} mock events');
  }

  // Create new event
  Future<void> createEvent(EventCreateRequest request) async {
    if (kDebugMode) {
      print('🎯 Creating event: ${request.title} at ${request.startTime}');
    }
    
    final event = EventEntity(
      id: request.id,
      title: request.title,
      description: request.description,
      startDt: request.startTime.toIso8601String(),
      endDt: request.endTime?.toIso8601String(),
      allDay: request.allDay,
      location: request.location,
      sourcePlatform: request.sourcePlatform,
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _dao.upsert(event);
    
    if (kDebugMode) {
      print('✅ Event created successfully: ${event.id}');
    }
  }

  /// KST 기준 하루 동안의 이벤트 occurrence 스트림
  /// 교집합 기준: (start < dayEnd) && (end > dayStart)
  Stream<List<EventOccurrence>> watchOccurrencesForDayKst(DateTime kstDate) {
    final startK = dayStartKst(kstDate);
    final endK = dayEndExclusiveKst(kstDate);
    
    return DbSignal.instance.eventsStream.asyncMap((_) async {
      try {
        // 1) DB에서 UTC 데이터 조회 (범위를 넓게 잡아 경계 놀침 방지)
        final dayBefore = startK.subtract(const Duration(days: 1));
        final dayAfter = endK.add(const Duration(days: 1));
        
        final rawEvents = await _dao.range(
          dayBefore.toIso8601String(),
          dayAfter.toIso8601String(),
        );
        
        // 2) 삭제되지 않은 이벤트만 필터
        final validEvents = rawEvents.where((e) => e.deletedAt == null).toList();
        
        // 3) 각 이벤트를 KST로 변환하여 교집합 검사
        final occurrences = <EventOccurrence>[];
        
        for (final event in validEvents) {
          final startUtc = DateTime.parse(event.startDt);
          final endUtc = event.endDt != null 
              ? DateTime.parse(event.endDt!)
              : startUtc.add(const Duration(hours: 1));
          
          final startKst = AppTime.toKst(startUtc);
          final endKst = AppTime.toKst(endUtc);
          
          // 교집합 검사: (start < dayEnd) && (end > dayStart)
          if (startKst.isBefore(endK) && endKst.isAfter(startK)) {
            // RRULE 처리가 있다면 여기서 처리
            // 현재는 단순 이벤트만 처리
            
            occurrences.add(EventOccurrence.fromEvent(event));
          }
        }
        
        // 4) 시작 시각 기준 정렬
        occurrences.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        return occurrences;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Error loading occurrences for $kstDate: $e');
        return <EventOccurrence>[];
      }
    });
  }
  
  /// 오늘 요약 데이터 스트림
  Stream<TodaySummaryData> watchTodaySummary() {
    final todayK = dayStartKst(AppTime.nowKst());
    final occurrencesStream = watchOccurrencesForDayKst(todayK);
    
    return occurrencesStream.map((occurrences) {
      final now = AppTime.nowKst();
      
      // 다음 이벤트 찾기
      EventOccurrence? next;
      for (final occ in occurrences) {
        if (occ.startKst.isAfter(now)) {
          next = occ;
          break;
        }
      }
      
      return TodaySummaryData(
        count: occurrences.length,
        next: next,
        lastSyncAt: now,
        offline: false, // TODO: 실제 오프라인 상태 검사
      );
    });
  }
  
  // Get events for date range
  Future<List<EventEntity>> getEventsForRange(
    String startIso,
    String endIso, {
    List<String>? platforms,
  }) async {
    final events = await _dao.range(startIso, endIso, platforms: platforms);
    
    if (kDebugMode) {
      print('📅 Loaded ${events.length} events for range $startIso to $endIso');
      for (final event in events) {
        print('  - ${event.title} at ${event.startDt}');
      }
    }
    
    return events;
  }

  // Get event by ID
  Future<EventEntity?> getById(String id) async {
    return _dao.getById(id);
  }

  // Delete event (soft delete)
  Future<void> deleteEvent(String id) async {
    if (kDebugMode) {
      print('🗑️ Deleting event: $id');
    }
    
    final deletedAt = DateTime.now().toIso8601String();
    await _dao.softDelete(id, deletedAt);
    
    if (kDebugMode) {
      print('✅ Event soft deleted successfully: $id');
    }
  }

  // Hard delete event (permanently remove)
  Future<void> hardDeleteEvent(String id) async {
    if (kDebugMode) {
      print('🗑️ Hard deleting event: $id');
    }
    
    await _dao.hardDelete(id);
    
    if (kDebugMode) {
      print('✅ Event hard deleted successfully: $id');
    }
  }

  // Update event
  Future<void> updateEvent(EventEntity event) async {
    if (kDebugMode) {
      print('📝 Updating event: ${event.id}');
    }
    
    final updatedEvent = event.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _dao.upsert(updatedEvent);
    
    if (kDebugMode) {
      print('✅ Event updated successfully: ${event.id}');
    }
  }
}

// Data transfer objects for repository operations
class EventCreateRequest {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool allDay;
  final String? location;
  final String sourcePlatform;

  const EventCreateRequest({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.allDay = false,
    this.location,
    this.sourcePlatform = 'internal',
  });
}

// Create singleton instance
final _dao = EventsDao();
final eventRepository = EventRepository(_dao);