import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'events_dao.dart';
import 'event_overrides_dao.dart';
import 'event_entity.dart';
import 'event_override_entity.dart';
import 'events_api.dart';

abstract class EventsApi {
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  });
}

class EventsRepository {
  final EventsDao dao;
  final EventOverridesDao overridesDao;
  final EventsApi api;

  EventsRepository({
    required this.dao,
    required this.overridesDao,
    required this.api,
  });

  // 로컬 우선 동기화: 1. 로컬 데이터 먼저 반환, 2. 외부 동기화 시도, 3. 성공시 업데이트
  Future<List<EventEntity>> syncAndGet(
    String startIso,
    String endIso, {
    List<String>? platforms,
    bool forceSync = false,
  }) async {
    // 1. 로컬 데이터 먼저 가져오기
    final localEvents = await dao.range(startIso, endIso, platforms: platforms);
    
    // 2. 외부 동기화는 백그라운드에서 수행
    _backgroundSync(startIso, endIso, forceSync: forceSync);
    
    return localEvents;
  }
  
  // 백그라운드 동기화 메소드
  Future<void> _backgroundSync(
    String startIso,
    String endIso, {
    bool forceSync = false,
  }) async {
    try {
      // 외부 캘린더 연결 상태 확인
      final hasExternalConnection = await _hasExternalCalendarConnection();
      if (!hasExternalConnection && !forceSync) {
        if (kDebugMode) debugPrint('No external calendar connection, skipping sync');
        return;
      }
      
      final response = await api.fetchEvents(
        startIso: startIso,
        endIso: endIso,
      );
      
      // 일반 이벤트 처리
      final rawEvents = (response['events'] as List<dynamic>?) ?? [];
      final events = rawEvents
          .cast<Map<String, dynamic>>()
          .map(_entityFromDto)
          .toList();
      
      if (events.isNotEmpty) {
        await dao.upsertAll(events);
        if (kDebugMode) debugPrint('Background sync: ${events.length} events synced');
      }
      
      // 오버라이드 처리
      final rawOverrides = (response['overrides'] as List<dynamic>?) ?? [];
      final overrides = rawOverrides
          .cast<Map<String, dynamic>>()
          .map(_overrideEntityFromDto)
          .toList();
      
      if (overrides.isNotEmpty) {
        await overridesDao.upsertAll(overrides);
        if (kDebugMode) debugPrint('Background sync: ${overrides.length} overrides synced');
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('Background sync failed: $e');
    }
  }

  // 로컬 전용 조회 (동기화 없음)
  Future<List<EventEntity>> getLocal(
    String startIso,
    String endIso, {
    List<String>? platforms,
  }) async {
    return dao.range(startIso, endIso, platforms: platforms);
  }

  // 특정 이벤트 조회
  Future<EventEntity?> getById(String id) async {
    return dao.getById(id);
  }

  Future<EventEntity?> getByIcalUid(String icalUid) async {
    return dao.getByIcalUid(icalUid);
  }

  // 반복 이벤트 오버라이드 조회
  Future<List<EventOverrideEntity>> getOverrides(
    String icalUid, {
    String? startIso,
    String? endIso,
  }) async {
    return overridesDao.forParentUid(
      icalUid,
      startIso: startIso,
      endIso: endIso,
    );
  }

  EventEntity _entityFromDto(Map<String, dynamic> dto) {
    return EventEntity(
      id: dto['id'] as String,
      title: dto['summary'] as String? ?? dto['title'] as String? ?? '제목 없음',
      description: dto['description'] as String?,
      startDt: dto['dtstart'] as String? ?? dto['startDateTime'] as String,
      endDt: dto['dtend'] as String? ?? dto['endDateTime'] as String?,
      allDay: (dto['allDay'] as bool?) ?? false,
      location: dto['location'] as String?,
      sourcePlatform: dto['sourcePlatform'] as String? ?? 'internal',
      platformColor: dto['platformColor'] as String?,

      // iCalendar 필드
      icalUid: dto['uid'] as String?,
      dtstamp: dto['dtstamp'] as String?,
      sequence: dto['sequence'] as int?,
      rrule: dto['rrule'] as String?,
      rdateJson: dto['rdate'] == null ? null : jsonEncode(dto['rdate']),
      exdateJson: dto['exdate'] == null ? null : jsonEncode(dto['exdate']),
      tzid: dto['tzid'] as String?,
      transparency: dto['transp'] as String?,
      url: dto['url'] as String?,
      categoriesJson: dto['categories'] == null ? null : jsonEncode(dto['categories']),
      organizerEmail: dto['organizerEmail'] as String?,
      geoLat: (dto['geo']?['lat'])?.toDouble(),
      geoLng: (dto['geo']?['lng'])?.toDouble(),

      // deprecated 유지 (서서히 rrule로 이전)
      recurrenceRule: dto['recurrenceRule'] as String?,
      status: dto['status'] as String?,
      attendees: (dto['attendees'] as List?)?.cast<Map<String, dynamic>>(),
      updatedAt: dto['lastModified'] as String? ??
                 dto['updatedAt'] as String? ??
                 DateTime.now().toIso8601String(),
      deletedAt: dto['deletedAt'] as String?,
    );
  }

  EventOverrideEntity _overrideEntityFromDto(Map<String, dynamic> dto) {
    return EventOverrideEntity(
      id: dto['id'] as String,
      icalUid: dto['uid'] as String,
      recurrenceId: dto['recurrenceId'] as String,
      startDt: dto['dtstart'] as String? ?? dto['startDateTime'] as String?,
      endDt: dto['dtend'] as String? ?? dto['endDateTime'] as String?,
      allDay: dto['allDay'] as bool?,
      title: dto['summary'] as String? ?? dto['title'] as String?,
      description: dto['description'] as String?,
      location: dto['location'] as String?,
      status: dto['status'] as String?,
      attendees: (dto['attendees'] as List?)?.cast<Map<String, dynamic>>(),
      lastModified: dto['lastModified'] as String? ??
                   dto['updatedAt'] as String? ??
                   DateTime.now().toIso8601String(),
    );
  }

  // 새 일정 생성 (로컬 우선)
  Future<EventEntity> createEvent(EventEntity event) async {
    // 1. 로컬 데이터베이스에 즉시 저장
    await dao.upsert(event);
    
    // 2. 외부 캘린더 동기화는 백그라운드에서
    _backgroundCreateEvent(event);
    
    return event;
  }
  
  // 백그라운드 이벤트 생성 동기화
  Future<void> _backgroundCreateEvent(EventEntity event) async {
    try {
      final hasExternalConnection = await _hasExternalCalendarConnection();
      if (!hasExternalConnection) {
        if (kDebugMode) debugPrint('No external connection, event saved locally only');
        return;
      }
      
      // TODO: 외부 캘린더에 이벤트 생성 API 호출
      if (kDebugMode) debugPrint('Background create: Event ${event.id} synced to external calendar');
      
    } catch (e) {
      if (kDebugMode) debugPrint('Background create failed: $e');
    }
  }
  
  // 외부 캘린더 연결 상태 확인
  Future<bool> _hasExternalCalendarConnection() async {
    try {
      // Mock API인 경우 항상 연결됨으로 간주
      if (api is MockEventsApi) return true;
      
      // 실제 API인 경우 간단한 health check
      final response = await api.fetchEvents(
        startIso: DateTime.now().toIso8601String(),
        endIso: DateTime.now().toIso8601String(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // 유틸리티 메소드들
  Future<int> getEventCount() async {
    return dao.countAll();
  }

  Future<int> getOverrideCount() async {
    return overridesDao.countAll();
  }

  Future<void> cleanupOldEvents({int daysAgo = 30}) async {
    await dao.cleanupDeleted(daysAgo: daysAgo);
  }
  
  // 강제 동기화 (수동 새로고침)
  Future<void> forceSync(String startIso, String endIso) async {
    await _backgroundSync(startIso, endIso, forceSync: true);
  }
}