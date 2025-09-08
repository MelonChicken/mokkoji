"""Event conflict resolution and timezone handling

설계 의도:
- 충돌 감지: external_updated_at과 로컬 수정 시간 비교
- 해결 정책: Last-Write-Wins 기본, 사용자 선택 옵션 제공
- 타임존 처리: 모든 저장은 UTC, 표시 시 로컬 타임존 변환

"""
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/local/app_database.dart';
import '../core/logger.dart';

enum ConflictResolution {
  keepLocal,    // 로컬 변경사항 유지
  useServer,    // 서버 버전 사용
  userChoice,   // 사용자가 선택
}

class EventConflict {
  final Event localEvent;
  final Event serverEvent;
  final ConflictType type;

  const EventConflict({
    required this.localEvent,
    required this.serverEvent,
    required this.type,
  });
}

enum ConflictType {
  contentMismatch,    // 내용이 다름
  deletedLocally,     // 로컬에서 삭제됨
  deletedRemotely,    // 서버에서 삭제됨
  versionMismatch,    // 버전 충돌
}

class ConflictResolver {
  final AppDatabase _database;
  final StreamController<EventConflict> _conflictController = 
      StreamController<EventConflict>.broadcast();

  ConflictResolver(this._database);

  /// 충돌 스트림 (UI에서 구독)
  Stream<EventConflict> get conflictStream => _conflictController.stream;

  /// 서버에서 받은 이벤트와 로컬 이벤트 간 충돌 검사
  Future<bool> hasConflict(Event serverEvent, Event? localEvent) async {
    if (localEvent == null) return false;

    // 1. 삭제 상태 충돌
    if (localEvent.deleted && !serverEvent.deleted) {
      return true; // 로컬 삭제, 서버 수정
    }
    if (!localEvent.deleted && serverEvent.deleted) {
      return true; // 로컬 수정, 서버 삭제
    }

    // 2. 수정 시간 비교
    final localModifiedAt = DateTime.fromMillisecondsSinceEpoch(
      localEvent.lastModifiedLocalMs
    );
    final serverUpdatedAt = serverEvent.externalUpdatedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(serverEvent.externalUpdatedAtMs!)
        : serverEvent.updatedAt;

    // 로컬이 더 최신이고 pending 상태면 충돌 가능성
    if (localEvent.syncStatus == 'pending' && 
        localModifiedAt.isAfter(serverUpdatedAt)) {
      
      // 3. 내용 비교 (주요 필드들)
      return _hasContentChanges(localEvent, serverEvent);
    }

    return false;
  }

  bool _hasContentChanges(Event local, Event server) {
    return local.title != server.title ||
           local.description != server.description ||
           local.startUtcMs != server.startUtcMs ||
           local.endUtcMs != server.endUtcMs ||
           local.location != server.location ||
           local.allDay != server.allDay ||
           local.recurrenceRule != server.recurrenceRule;
  }

  /// 충돌 해결 처리
  Future<Event> resolveConflict(
    Event serverEvent,
    Event localEvent,
    ConflictResolution resolution,
  ) async {
    final conflictType = _determineConflictType(localEvent, serverEvent);
    
    AppLogger.info('Resolving event conflict', {
      'event_id': localEvent.id,
      'conflict_type': conflictType.name,
      'resolution': resolution.name,
    });

    switch (resolution) {
      case ConflictResolution.keepLocal:
        return await _applyLocalChanges(localEvent);
      
      case ConflictResolution.useServer:
        return await _applyServerChanges(serverEvent, localEvent);
      
      case ConflictResolution.userChoice:
        // UI에서 사용자 선택을 위해 충돌 이벤트 발생
        final conflict = EventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          type: conflictType,
        );
        _conflictController.add(conflict);
        
        // 일단 서버 버전 적용 (사용자 선택 후 다시 처리)
        return await _applyServerChanges(serverEvent, localEvent);
    }
  }

  ConflictType _determineConflictType(Event local, Event server) {
    if (local.deleted && !server.deleted) {
      return ConflictType.deletedLocally;
    }
    if (!local.deleted && server.deleted) {
      return ConflictType.deletedRemotely;
    }
    if (local.externalVersion != server.externalVersion) {
      return ConflictType.versionMismatch;
    }
    return ConflictType.contentMismatch;
  }

  Future<Event> _applyLocalChanges(Event localEvent) async {
    // 로컬 변경사항을 유지하고 동기화 대기 상태로 마킹
    await _database.updateEventOptimistic(
      localEvent.id,
      EventsCompanion(
        syncStatus: const Value('pending'),
        lastModifiedLocalMs: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    
    return localEvent;
  }

  Future<Event> _applyServerChanges(Event serverEvent, Event localEvent) async {
    // 서버 버전으로 로컬 이벤트 업데이트
    final updatedEvent = localEvent.copyWith(
      title: serverEvent.title,
      description: Value(serverEvent.description),
      startUtcMs: serverEvent.startUtcMs,
      endUtcMs: Value(serverEvent.endUtcMs),
      allDay: serverEvent.allDay,
      location: Value(serverEvent.location),
      recurrenceRule: Value(serverEvent.recurrenceRule),
      externalUpdatedAtMs: Value(serverEvent.externalUpdatedAtMs),
      externalVersion: Value(serverEvent.externalVersion),
      syncStatus: 'synced',
      updatedAt: DateTime.now(),
    );

    await _database.update(_database.events).replace(updatedEvent);
    return updatedEvent;
  }

  /// 배치 충돌 해결 (여러 이벤트 동시 처리)
  Future<List<Event>> resolveBatchConflicts(
    List<Event> serverEvents,
    ConflictResolution defaultResolution,
  ) async {
    final resolvedEvents = <Event>[];
    
    for (final serverEvent in serverEvents) {
      final localEvent = await (_database.select(_database.events)
        ..where((e) => e.id.equals(serverEvent.id))
      ).getSingleOrNull();

      if (localEvent != null && await hasConflict(serverEvent, localEvent)) {
        final resolved = await resolveConflict(
          serverEvent, 
          localEvent, 
          defaultResolution
        );
        resolvedEvents.add(resolved);
      } else {
        // 충돌 없음, 서버 버전 적용
        resolvedEvents.add(serverEvent);
      }
    }

    return resolvedEvents;
  }

  void dispose() {
    _conflictController.close();
  }
}

/// 타임존 유틸리티 클래스
class TimezoneHelper {
  static const String defaultTimezone = 'Asia/Seoul';
  
  /// UTC 시간을 로컬 타임존으로 변환
  static DateTime utcToLocal(DateTime utcTime, [String? timezone]) {
    final tz.Location location = tz.getLocation(timezone ?? defaultTimezone);
    return tz.TZDateTime.from(utcTime, location);
  }

  /// 로컬 시간을 UTC로 변환  
  static DateTime localToUtc(DateTime localTime, [String? timezone]) {
    final tz.Location location = tz.getLocation(timezone ?? defaultTimezone);
    final tzDateTime = tz.TZDateTime.from(localTime, location);
    return tzDateTime.toUtc();
  }

  /// 이벤트 시간을 표시용으로 변환
  static DateTime getDisplayTime(Event event, [String? timezone]) {
    final utcTime = DateTime.fromMillisecondsSinceEpoch(event.startUtcMs);
    
    if (event.allDay) {
      // 종일 이벤트는 날짜만 표시 (타임존 변환 불필요)
      return DateTime(utcTime.year, utcTime.month, utcTime.day);
    }
    
    return utcToLocal(utcTime, timezone);
  }

  /// RRULE의 시간을 타임존 고려하여 전개
  static List<DateTime> expandRecurrenceRule(
    String rrule,
    DateTime startTime,
    DateTime windowStart,
    DateTime windowEnd,
    [String? timezone]
  ) {
    // 간단한 RRULE 처리 (실제로는 더 복잡한 라이브러리 필요)
    final instances = <DateTime>[];
    
    if (rrule.contains('FREQ=WEEKLY')) {
      DateTime current = startTime;
      final location = tz.getLocation(timezone ?? defaultTimezone);
      
      while (current.isBefore(windowEnd)) {
        if (current.isAfter(windowStart)) {
          // 타임존을 고려한 반복 생성
          final localTime = tz.TZDateTime.from(current, location);
          instances.add(localTime);
        }
        current = current.add(const Duration(days: 7));
      }
    }
    
    return instances;
  }

  /// DST 전환 감지 및 처리
  static bool isDstTransition(DateTime dateTime, [String? timezone]) {
    final location = tz.getLocation(timezone ?? defaultTimezone);
    final tzDateTime = tz.TZDateTime.from(dateTime, location);
    
    // 이전/다음 시간과 UTC 오프셋 비교
    final prevHour = tzDateTime.subtract(const Duration(hours: 1));
    final nextHour = tzDateTime.add(const Duration(hours: 1));
    
    return prevHour.timeZoneOffset != nextHour.timeZoneOffset;
  }

  /// 캘린더별 타임존 설정
  static String getCalendarTimezone(Calendar calendar) {
    return calendar.timezone ?? defaultTimezone;
  }

  /// 사용자 로케일에 따른 시간 포맷팅
  static String formatEventTime(
    Event event, 
    BuildContext context,
    [String? timezone]
  ) {
    final displayTime = getDisplayTime(event, timezone);
    final locale = Localizations.localeOf(context);
    
    if (event.allDay) {
      return _formatDate(displayTime, locale.languageCode);
    } else {
      return _formatDateTime(displayTime, locale.languageCode);
    }
  }

  static String _formatDate(DateTime date, String locale) {
    switch (locale) {
      case 'ko':
        return '${date.month}월 ${date.day}일';
      default:
        return '${date.month}/${date.day}';
    }
  }

  static String _formatDateTime(DateTime dateTime, String locale) {
    switch (locale) {
      case 'ko':
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour < 12 ? '오전' : '오후';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$period $displayHour:$minute';
      default:
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour < 12 ? 'AM' : 'PM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:$minute $period';
    }
  }
}

/// 충돌 해결 다이얼로그 위젯
class ConflictResolutionDialog extends StatelessWidget {
  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolution,
  });

  final EventConflict conflict;
  final Function(ConflictResolution) onResolution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          const Text('이벤트 충돌'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 이벤트에 충돌이 발생했습니다:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // 이벤트 정보
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conflict.localEvent.title,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _getConflictDescription(conflict.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            '어떻게 해결하시겠습니까?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResolution(ConflictResolution.useServer);
          },
          child: const Text('최신 버전 사용'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onResolution(ConflictResolution.keepLocal);
          },
          child: const Text('내 변경사항 유지'),
        ),
      ],
    );
  }

  String _getConflictDescription(ConflictType type) {
    switch (type) {
      case ConflictType.contentMismatch:
        return '로컬과 서버에서 다른 내용으로 수정됨';
      case ConflictType.deletedLocally:
        return '로컬에서는 삭제됐지만 서버에서는 수정됨';
      case ConflictType.deletedRemotely:
        return '서버에서는 삭제됐지만 로컬에서는 수정됨';
      case ConflictType.versionMismatch:
        return '버전 충돌 발생';
    }
  }
}

// Acceptance Criteria:
// - external_updated_at 비교로 충돌 감지
// - Last-Write-Wins 기본 정책, 사용자 선택 옵션
// - UTC 저장, 로컬 타임존으로 표시 변환
// - DST 전환과 RRULE 타임존 처리
// - 배치 충돌 해결로 성능 최적화