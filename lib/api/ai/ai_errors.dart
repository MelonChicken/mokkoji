/// AI API error handling
///
/// FastAPI 에러 응답 형식과 매핑되는 통합 에러 시스템
///
/// Error Response Format:
/// ```json
/// {
///   "code": "VALIDATION_ERROR",
///   "message": "Missing required field",
///   "details": {...},
///   "traceId": "..."
/// }
/// ```

import 'package:json_annotation/json_annotation.dart';

part 'ai_errors.g.dart';

// ============================================================================
// Error Codes
// ============================================================================

/// AI API error codes
enum AiErrorCode {
  /// 요청 데이터 검증 실패
  @JsonValue('VALIDATION_ERROR')
  validationError,

  /// 인증 실패 (토큰 만료, 권한 없음)
  @JsonValue('AUTH_ERROR')
  authError,

  /// 리소스를 찾을 수 없음
  @JsonValue('NOT_FOUND')
  notFound,

  /// 데이터 충돌 (버전 불일치 등)
  @JsonValue('CONFLICT')
  conflict,

  /// API 호출 제한 초과
  @JsonValue('RATE_LIMIT')
  rateLimit,

  /// 서버 내부 오류
  @JsonValue('SERVER_ERROR')
  serverError,

  /// OpenAI API 오류
  @JsonValue('OPENAI_ERROR')
  openaiError,

  /// 음성 파일 처리 오류
  @JsonValue('AUDIO_ERROR')
  audioError,

  /// 네트워크 연결 오류
  @JsonValue('NETWORK_ERROR')
  networkError,

  /// 알 수 없는 오류
  @JsonValue('UNKNOWN')
  unknown,
}

// ============================================================================
// Error Response Model
// ============================================================================

/// FastAPI 에러 응답 모델
@JsonSerializable()
class AiErrorResponse {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  @JsonKey(name: 'trace_id')
  final String? traceId;

  const AiErrorResponse({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
  });

  factory AiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$AiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiErrorResponseToJson(this);

  /// Convert to AiException
  AiException toException() {
    return AiException(
      code: parseAiErrorCode(code),
      message: message,
      details: details,
      traceId: traceId,
    );
  }
}

// ============================================================================
// Exception Classes
// ============================================================================

/// Base AI exception
class AiException implements Exception {
  final AiErrorCode code;
  final String message;
  final Map<String, dynamic>? details;
  final String? traceId;
  final StackTrace? stackTrace;

  const AiException({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
    this.stackTrace,
  });

  /// Create from error response JSON
  factory AiException.fromJson(Map<String, dynamic> json) {
    return AiErrorResponse.fromJson(json).toException();
  }

  /// Create from HTTP error
  factory AiException.fromHttpError(int statusCode, String? body) {
    if (body != null) {
      try {
        final json = Map<String, dynamic>.from(
          // ignore: avoid_dynamic_calls
          (const {}).cast<String, dynamic>(),
        );
        return AiException.fromJson(json);
      } catch (_) {
        // Fallback to generic error
      }
    }

    return AiException(
      code: _statusCodeToErrorCode(statusCode),
      message: 'HTTP $statusCode: ${body ?? 'Unknown error'}',
      details: {'status_code': statusCode, 'body': body},
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('[${code.name}] $message');
    if (traceId != null) {
      buffer.write(' (trace: $traceId)');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    return buffer.toString();
  }

  /// User-friendly message
  String get userMessage {
    switch (code) {
      case AiErrorCode.validationError:
        return '입력 데이터를 확인해주세요';
      case AiErrorCode.authError:
        return '인증이 필요합니다. 다시 로그인해주세요';
      case AiErrorCode.notFound:
        return '요청하신 일정을 찾을 수 없습니다';
      case AiErrorCode.conflict:
        return '일정이 이미 변경되었습니다. 새로고침 후 다시 시도해주세요';
      case AiErrorCode.rateLimit:
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요';
      case AiErrorCode.serverError:
        return '서버 오류가 발생했습니다';
      case AiErrorCode.openaiError:
        return 'AI 서비스 오류가 발생했습니다';
      case AiErrorCode.audioError:
        return '음성 파일 처리 중 오류가 발생했습니다';
      case AiErrorCode.networkError:
        return '네트워크 연결을 확인해주세요';
      case AiErrorCode.unknown:
        return '알 수 없는 오류가 발생했습니다';
    }
  }

  /// Whether this error is retryable
  bool get isRetryable {
    switch (code) {
      case AiErrorCode.networkError:
      case AiErrorCode.rateLimit:
      case AiErrorCode.serverError:
        return true;
      case AiErrorCode.validationError:
      case AiErrorCode.authError:
      case AiErrorCode.notFound:
      case AiErrorCode.conflict:
      case AiErrorCode.openaiError:
      case AiErrorCode.audioError:
      case AiErrorCode.unknown:
        return false;
    }
  }
}

/// Validation error (400 Bad Request)
class AiValidationException extends AiException {
  const AiValidationException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.validationError);
}

/// Authentication error (401 Unauthorized)
class AiAuthException extends AiException {
  const AiAuthException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.authError);
}

/// Resource not found (404 Not Found)
class AiNotFoundException extends AiException {
  const AiNotFoundException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.notFound);
}

/// Conflict error (409 Conflict)
class AiConflictException extends AiException {
  const AiConflictException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.conflict);
}

/// Rate limit exceeded (429 Too Many Requests)
class AiRateLimitException extends AiException {
  final int? retryAfterSeconds;

  const AiRateLimitException({
    required super.message,
    super.details,
    super.traceId,
    this.retryAfterSeconds,
  }) : super(code: AiErrorCode.rateLimit);
}

/// Server error (500 Internal Server Error)
class AiServerException extends AiException {
  const AiServerException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.serverError);
}

/// OpenAI API error
class AiOpenAIException extends AiException {
  const AiOpenAIException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.openaiError);
}

/// Audio processing error
class AiAudioException extends AiException {
  const AiAudioException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.audioError);
}

/// Network error
class AiNetworkException extends AiException {
  const AiNetworkException({
    required super.message,
    super.details,
    super.traceId,
  }) : super(code: AiErrorCode.networkError);
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse error code string to enum
AiErrorCode parseAiErrorCode(String? code) {
  if (code == null) return AiErrorCode.unknown;

  switch (code.toUpperCase()) {
    case 'VALIDATION_ERROR':
      return AiErrorCode.validationError;
    case 'AUTH_ERROR':
      return AiErrorCode.authError;
    case 'NOT_FOUND':
      return AiErrorCode.notFound;
    case 'CONFLICT':
      return AiErrorCode.conflict;
    case 'RATE_LIMIT':
      return AiErrorCode.rateLimit;
    case 'SERVER_ERROR':
      return AiErrorCode.serverError;
    case 'OPENAI_ERROR':
      return AiErrorCode.openaiError;
    case 'AUDIO_ERROR':
      return AiErrorCode.audioError;
    case 'NETWORK_ERROR':
      return AiErrorCode.networkError;
    default:
      return AiErrorCode.unknown;
  }
}

/// Map HTTP status code to error code
AiErrorCode _statusCodeToErrorCode(int statusCode) {
  switch (statusCode) {
    case 400:
      return AiErrorCode.validationError;
    case 401:
    case 403:
      return AiErrorCode.authError;
    case 404:
      return AiErrorCode.notFound;
    case 409:
      return AiErrorCode.conflict;
    case 429:
      return AiErrorCode.rateLimit;
    case >= 500:
      return AiErrorCode.serverError;
    default:
      return AiErrorCode.unknown;
  }
}

/// Create exception from error response
AiException fromErrorResponse(Map<String, dynamic> json) {
  return AiException.fromJson(json);
}
