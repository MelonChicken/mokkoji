// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_errors.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiErrorResponse _$AiErrorResponseFromJson(Map<String, dynamic> json) =>
    AiErrorResponse(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
      traceId: json['trace_id'] as String?,
    );

Map<String, dynamic> _$AiErrorResponseToJson(AiErrorResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
      'trace_id': instance.traceId,
    };
