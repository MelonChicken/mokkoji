import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'events_dao.dart';
import 'event_overrides_dao.dart';
import 'event_entity.dart';
import 'event_override_entity.dart';

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

  // 동기화: 서버 → 로컬(upsert), 실패해도 로컬 데이터로 동작
  Future<List<EventEntity>> syncAndGet(
    String startIso,
    String endIso, {
    List<String>? platforms,
  }) async {
    try {
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
      }
      
      // 오버라이드 처리
      final rawOverrides = (response['overrides'] as List<dynamic>?) ?? [];
      final overrides = rawOverrides
          .cast<Map<String, dynamic>>()
          .map(_overrideEntityFromDto)
          .toList();
      
      if (overrides.isNotEmpty) {
        await overridesDao.upsertAll(overrides);
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('sync failed: $e');
    }
    
    return dao.range(startIso, endIso, platforms: platforms);
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
}