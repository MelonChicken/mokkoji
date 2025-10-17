// ignore_for_file: invalid_annotation_target

/// AI-powered voice event modification types
///
/// 음성으로 일정 수정 기능을 위한 Flutter 데이터 모델
/// FastAPI `/v1/ai/*` 엔드포인트와 1:1 매핑
///
/// Endpoints:
/// - POST /v1/ai/find_event
/// - POST /v1/ai/reschedule
/// - POST /v1/ai/update_fields
/// - POST /v1/ai/cancel
/// - GET  /v1/ai/check_conflicts
/// - POST /v1/ai/transcribe
/// - POST /v1/ai/process_voice

import 'package:json_annotation/json_annotation.dart';

part 'ai_types.g.dart';

// ============================================================================
// Enums
// ============================================================================

/// AI intent types (function names)
enum AiIntent {
  @JsonValue('find_event')
  findEvent,
  @JsonValue('reschedule')
  reschedule,
  @JsonValue('update_fields')
  updateFields,
  @JsonValue('cancel')
  cancel,
  @JsonValue('check_conflicts')
  checkConflicts,
  @JsonValue('transcribe')
  transcribe,
  @JsonValue('process_voice')
  processVoice,
}

/// Event cancellation scope
enum CancelScope {
  @JsonValue('single')
  single,
  @JsonValue('future')
  future,
  @JsonValue('all')
  all,
}

// ============================================================================
// Shared Types
// ============================================================================

/// Event reference (simplified event data)
@JsonSerializable()
class AiEventRef {
  final String id;
  final String title;
  @JsonKey(name: 'start_utc')
  final DateTime startUtc;
  @JsonKey(name: 'end_utc')
  final DateTime? endUtc;
  @JsonKey(name: 'all_day')
  final bool allDay;
  final String? description;
  final String? location;

  const AiEventRef({
    required this.id,
    required this.title,
    required this.startUtc,
    this.endUtc,
    this.allDay = false,
    this.description,
    this.location,
  });

  factory AiEventRef.fromJson(Map<String, dynamic> json) =>
      _$AiEventRefFromJson(json);

  Map<String, dynamic> toJson() => _$AiEventRefToJson(this);
}

// ============================================================================
// 1. Find Event (POST /v1/ai/find_event)
// ============================================================================

/// Request: 이벤트 검색
@JsonSerializable()
class AiFindEventRequest {
  /// 검색 쿼리 (제목, 설명, 위치 등)
  final String query;

  /// 검색 시작일 (YYYY-MM-DD)
  @JsonKey(name: 'start_date')
  final String? startDate;

  /// 검색 종료일 (YYYY-MM-DD)
  @JsonKey(name: 'end_date')
  final String? endDate;

  /// 최대 결과 수 (1-50)
  final int limit;

  const AiFindEventRequest({
    required this.query,
    this.startDate,
    this.endDate,
    this.limit = 10,
  });

  factory AiFindEventRequest.fromJson(Map<String, dynamic> json) =>
      _$AiFindEventRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiFindEventRequestToJson(this);
}

/// Response: 이벤트 검색 결과
@JsonSerializable()
class AiFindEventResponse {
  final bool success;
  final List<AiEventRef> events;
  final int count;

  const AiFindEventResponse({
    required this.success,
    required this.events,
    required this.count,
  });

  factory AiFindEventResponse.fromJson(Map<String, dynamic> json) =>
      _$AiFindEventResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiFindEventResponseToJson(this);
}

// ============================================================================
// 2. Reschedule (POST /v1/ai/reschedule)
// ============================================================================

/// Request: 일정 시간 변경
@JsonSerializable()
class AiRescheduleRequest {
  @JsonKey(name: 'event_id')
  final String eventId;

  /// 새 시작 시간 (ISO 8601 UTC)
  @JsonKey(name: 'new_start_utc')
  final DateTime newStartUtc;

  /// 새 종료 시간 (ISO 8601 UTC, optional - 기존 duration 유지)
  @JsonKey(name: 'new_end_utc')
  final DateTime? newEndUtc;

  const AiRescheduleRequest({
    required this.eventId,
    required this.newStartUtc,
    this.newEndUtc,
  });

  factory AiRescheduleRequest.fromJson(Map<String, dynamic> json) =>
      _$AiRescheduleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiRescheduleRequestToJson(this);
}

/// Response: 일정 시간 변경 결과
@JsonSerializable()
class AiRescheduleResponse {
  final bool success;
  final String message;
  final AiEventRef event;

  const AiRescheduleResponse({
    required this.success,
    required this.message,
    required this.event,
  });

  factory AiRescheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$AiRescheduleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiRescheduleResponseToJson(this);
}

// ============================================================================
// 3. Update Fields (POST /v1/ai/update_fields)
// ============================================================================

/// Request: 이벤트 필드 수정
@JsonSerializable()
class AiUpdateFieldsRequest {
  @JsonKey(name: 'event_id')
  final String eventId;

  /// 새 제목 (null = 변경 없음)
  final String? title;

  /// 새 설명 (null = 변경 없음)
  final String? description;

  /// 새 위치 (null = 변경 없음)
  final String? location;

  const AiUpdateFieldsRequest({
    required this.eventId,
    this.title,
    this.description,
    this.location,
  });

  factory AiUpdateFieldsRequest.fromJson(Map<String, dynamic> json) =>
      _$AiUpdateFieldsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiUpdateFieldsRequestToJson(this);
}

/// Response: 이벤트 필드 수정 결과
@JsonSerializable()
class AiUpdateFieldsResponse {
  final bool success;
  final String message;
  final AiEventRef event;

  const AiUpdateFieldsResponse({
    required this.success,
    required this.message,
    required this.event,
  });

  factory AiUpdateFieldsResponse.fromJson(Map<String, dynamic> json) =>
      _$AiUpdateFieldsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiUpdateFieldsResponseToJson(this);
}

// ============================================================================
// 4. Cancel Event (POST /v1/ai/cancel)
// ============================================================================

/// Request: 이벤트 취소
@JsonSerializable()
class AiCancelRequest {
  @JsonKey(name: 'event_id')
  final String eventId;

  /// 취소 범위
  @JsonKey(name: 'cancel_scope')
  final CancelScope cancelScope;

  const AiCancelRequest({
    required this.eventId,
    this.cancelScope = CancelScope.single,
  });

  factory AiCancelRequest.fromJson(Map<String, dynamic> json) =>
      _$AiCancelRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiCancelRequestToJson(this);
}

/// Response: 이벤트 취소 결과
@JsonSerializable()
class AiCancelResponse {
  final bool success;
  final String message;
  @JsonKey(name: 'event_id')
  final String eventId;

  const AiCancelResponse({
    required this.success,
    required this.message,
    required this.eventId,
  });

  factory AiCancelResponse.fromJson(Map<String, dynamic> json) =>
      _$AiCancelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiCancelResponseToJson(this);
}

// ============================================================================
// 5. Check Conflicts (GET /v1/ai/check_conflicts)
// ============================================================================

/// Request: 일정 충돌 확인 (query parameters)
@JsonSerializable()
class AiCheckConflictsRequest {
  @JsonKey(name: 'start_utc')
  final DateTime startUtc;

  @JsonKey(name: 'end_utc')
  final DateTime endUtc;

  /// 충돌 검사에서 제외할 이벤트 ID
  @JsonKey(name: 'exclude_event_id')
  final String? excludeEventId;

  const AiCheckConflictsRequest({
    required this.startUtc,
    required this.endUtc,
    this.excludeEventId,
  });

  factory AiCheckConflictsRequest.fromJson(Map<String, dynamic> json) =>
      _$AiCheckConflictsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiCheckConflictsRequestToJson(this);

  /// Convert to query parameters for GET request
  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'start_utc': startUtc.toUtc().toIso8601String(),
      'end_utc': endUtc.toUtc().toIso8601String(),
    };
    if (excludeEventId != null) {
      params['exclude_event_id'] = excludeEventId!;
    }
    return params;
  }
}

/// Response: 일정 충돌 확인 결과
@JsonSerializable()
class AiCheckConflictsResponse {
  @JsonKey(name: 'has_conflicts')
  final bool hasConflicts;

  @JsonKey(name: 'conflict_count')
  final int conflictCount;

  @JsonKey(name: 'conflicting_events')
  final List<AiEventRef> conflictingEvents;

  const AiCheckConflictsResponse({
    required this.hasConflicts,
    required this.conflictCount,
    required this.conflictingEvents,
  });

  factory AiCheckConflictsResponse.fromJson(Map<String, dynamic> json) =>
      _$AiCheckConflictsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiCheckConflictsResponseToJson(this);
}

// ============================================================================
// 6. Transcribe Audio (POST /v1/ai/transcribe)
// ============================================================================

/// Response: 음성 파일 텍스트 변환 결과
/// Note: Request는 multipart/form-data로 audio file 전송
@JsonSerializable()
class AiTranscribeResponse {
  final bool success;
  final String transcription;
  final String filename;

  const AiTranscribeResponse({
    required this.success,
    required this.transcription,
    required this.filename,
  });

  factory AiTranscribeResponse.fromJson(Map<String, dynamic> json) =>
      _$AiTranscribeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiTranscribeResponseToJson(this);
}

// ============================================================================
// 7. Process Voice Command (POST /v1/ai/process_voice)
// ============================================================================

/// Request: 음성 명령 처리
@JsonSerializable()
class AiProcessVoiceRequest {
  @JsonKey(name: 'user_message')
  final String userMessage;

  const AiProcessVoiceRequest({
    required this.userMessage,
  });

  factory AiProcessVoiceRequest.fromJson(Map<String, dynamic> json) =>
      _$AiProcessVoiceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AiProcessVoiceRequestToJson(this);
}

/// Response: 음성 명령 처리 결과
@JsonSerializable()
class AiProcessVoiceResponse {
  final bool success;

  /// 호출된 함수 이름 (null = 인식된 액션 없음)
  @JsonKey(name: 'function_called')
  final String? functionCalled;

  /// 함수 인자
  @JsonKey(name: 'function_args')
  final Map<String, dynamic>? functionArgs;

  /// 함수 실행 결과
  final Map<String, dynamic>? result;

  /// AI 응답 메시지
  @JsonKey(name: 'ai_response')
  final String? aiResponse;

  final String? message;

  const AiProcessVoiceResponse({
    required this.success,
    this.functionCalled,
    this.functionArgs,
    this.result,
    this.aiResponse,
    this.message,
  });

  factory AiProcessVoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$AiProcessVoiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiProcessVoiceResponseToJson(this);
}

// ============================================================================
// 8. Health Check (GET /v1/ai/health)
// ============================================================================

/// Response: AI 서비스 상태 확인
@JsonSerializable()
class AiHealthResponse {
  final String status;
  final String? message;
  final Map<String, bool>? features;

  const AiHealthResponse({
    required this.status,
    this.message,
    this.features,
  });

  factory AiHealthResponse.fromJson(Map<String, dynamic> json) =>
      _$AiHealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiHealthResponseToJson(this);

  bool get isHealthy => status == 'healthy';
}
