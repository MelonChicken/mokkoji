// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiEventRef _$AiEventRefFromJson(Map<String, dynamic> json) => AiEventRef(
      id: json['id'] as String,
      title: json['title'] as String,
      startUtc: DateTime.parse(json['start_utc'] as String),
      endUtc: json['end_utc'] == null
          ? null
          : DateTime.parse(json['end_utc'] as String),
      allDay: json['all_day'] as bool? ?? false,
      description: json['description'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$AiEventRefToJson(AiEventRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'start_utc': instance.startUtc.toIso8601String(),
      'end_utc': instance.endUtc?.toIso8601String(),
      'all_day': instance.allDay,
      'description': instance.description,
      'location': instance.location,
    };

AiFindEventRequest _$AiFindEventRequestFromJson(Map<String, dynamic> json) =>
    AiFindEventRequest(
      query: json['query'] as String,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$AiFindEventRequestToJson(AiFindEventRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'limit': instance.limit,
    };

AiFindEventResponse _$AiFindEventResponseFromJson(Map<String, dynamic> json) =>
    AiFindEventResponse(
      success: json['success'] as bool,
      events: (json['events'] as List<dynamic>)
          .map((e) => AiEventRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$AiFindEventResponseToJson(
        AiFindEventResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'events': instance.events,
      'count': instance.count,
    };

AiRescheduleRequest _$AiRescheduleRequestFromJson(Map<String, dynamic> json) =>
    AiRescheduleRequest(
      eventId: json['event_id'] as String,
      newStartUtc: DateTime.parse(json['new_start_utc'] as String),
      newEndUtc: json['new_end_utc'] == null
          ? null
          : DateTime.parse(json['new_end_utc'] as String),
    );

Map<String, dynamic> _$AiRescheduleRequestToJson(
        AiRescheduleRequest instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'new_start_utc': instance.newStartUtc.toIso8601String(),
      'new_end_utc': instance.newEndUtc?.toIso8601String(),
    };

AiRescheduleResponse _$AiRescheduleResponseFromJson(
        Map<String, dynamic> json) =>
    AiRescheduleResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      event: AiEventRef.fromJson(json['event'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AiRescheduleResponseToJson(
        AiRescheduleResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'event': instance.event,
    };

AiUpdateFieldsRequest _$AiUpdateFieldsRequestFromJson(
        Map<String, dynamic> json) =>
    AiUpdateFieldsRequest(
      eventId: json['event_id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$AiUpdateFieldsRequestToJson(
        AiUpdateFieldsRequest instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
    };

AiUpdateFieldsResponse _$AiUpdateFieldsResponseFromJson(
        Map<String, dynamic> json) =>
    AiUpdateFieldsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      event: AiEventRef.fromJson(json['event'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AiUpdateFieldsResponseToJson(
        AiUpdateFieldsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'event': instance.event,
    };

AiCancelRequest _$AiCancelRequestFromJson(Map<String, dynamic> json) =>
    AiCancelRequest(
      eventId: json['event_id'] as String,
      cancelScope:
          $enumDecodeNullable(_$CancelScopeEnumMap, json['cancel_scope']) ??
              CancelScope.single,
    );

Map<String, dynamic> _$AiCancelRequestToJson(AiCancelRequest instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'cancel_scope': _$CancelScopeEnumMap[instance.cancelScope]!,
    };

const _$CancelScopeEnumMap = {
  CancelScope.single: 'single',
  CancelScope.future: 'future',
  CancelScope.all: 'all',
};

AiCancelResponse _$AiCancelResponseFromJson(Map<String, dynamic> json) =>
    AiCancelResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      eventId: json['event_id'] as String,
    );

Map<String, dynamic> _$AiCancelResponseToJson(AiCancelResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'event_id': instance.eventId,
    };

AiCheckConflictsRequest _$AiCheckConflictsRequestFromJson(
        Map<String, dynamic> json) =>
    AiCheckConflictsRequest(
      startUtc: DateTime.parse(json['start_utc'] as String),
      endUtc: DateTime.parse(json['end_utc'] as String),
      excludeEventId: json['exclude_event_id'] as String?,
    );

Map<String, dynamic> _$AiCheckConflictsRequestToJson(
        AiCheckConflictsRequest instance) =>
    <String, dynamic>{
      'start_utc': instance.startUtc.toIso8601String(),
      'end_utc': instance.endUtc.toIso8601String(),
      'exclude_event_id': instance.excludeEventId,
    };

AiCheckConflictsResponse _$AiCheckConflictsResponseFromJson(
        Map<String, dynamic> json) =>
    AiCheckConflictsResponse(
      hasConflicts: json['has_conflicts'] as bool,
      conflictCount: (json['conflict_count'] as num).toInt(),
      conflictingEvents: (json['conflicting_events'] as List<dynamic>)
          .map((e) => AiEventRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AiCheckConflictsResponseToJson(
        AiCheckConflictsResponse instance) =>
    <String, dynamic>{
      'has_conflicts': instance.hasConflicts,
      'conflict_count': instance.conflictCount,
      'conflicting_events': instance.conflictingEvents,
    };

AiTranscribeResponse _$AiTranscribeResponseFromJson(
        Map<String, dynamic> json) =>
    AiTranscribeResponse(
      success: json['success'] as bool,
      transcription: json['transcription'] as String,
      filename: json['filename'] as String,
    );

Map<String, dynamic> _$AiTranscribeResponseToJson(
        AiTranscribeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'transcription': instance.transcription,
      'filename': instance.filename,
    };

AiProcessVoiceRequest _$AiProcessVoiceRequestFromJson(
        Map<String, dynamic> json) =>
    AiProcessVoiceRequest(
      userMessage: json['user_message'] as String,
    );

Map<String, dynamic> _$AiProcessVoiceRequestToJson(
        AiProcessVoiceRequest instance) =>
    <String, dynamic>{
      'user_message': instance.userMessage,
    };

AiProcessVoiceResponse _$AiProcessVoiceResponseFromJson(
        Map<String, dynamic> json) =>
    AiProcessVoiceResponse(
      success: json['success'] as bool,
      functionCalled: json['function_called'] as String?,
      functionArgs: json['function_args'] as Map<String, dynamic>?,
      result: json['result'] as Map<String, dynamic>?,
      aiResponse: json['ai_response'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AiProcessVoiceResponseToJson(
        AiProcessVoiceResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'function_called': instance.functionCalled,
      'function_args': instance.functionArgs,
      'result': instance.result,
      'ai_response': instance.aiResponse,
      'message': instance.message,
    };

AiHealthResponse _$AiHealthResponseFromJson(Map<String, dynamic> json) =>
    AiHealthResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      features: (json['features'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ),
    );

Map<String, dynamic> _$AiHealthResponseToJson(AiHealthResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'features': instance.features,
    };
