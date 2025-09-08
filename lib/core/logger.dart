"""Application logging utilities

설계 의도:
- 구조화된 로깅으로 디버깅과 모니터링 지원
- 민감정보 마스킹으로 보안 강화
- 로그 레벨별 필터링과 출력 제어

"""
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0),
  info(1),
  warn(2),
  error(3);

  const LogLevel(this.priority);
  final int priority;
}

class AppLogger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  static void setLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.debug, message, context);
  }

  static void info(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, message, context);
  }

  static void warn(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.warn, message, context);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    final errorContext = <String, dynamic>{
      ...?context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };
    _log(LogLevel.error, message, errorContext);
  }

  static void _log(LogLevel level, String message, Map<String, dynamic>? context) {
    if (level.priority < _minLevel.priority) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    
    // 민감정보 마스킹
    final safeContext = context != null ? _maskSensitiveData(context) : null;
    
    final logMessage = safeContext != null 
      ? '[$timestamp] $levelName: $message | ${safeContext}'
      : '[$timestamp] $levelName: $message';

    // Flutter 개발자 로그로 출력
    developer.log(
      logMessage,
      name: 'Mokkoji',
      level: _mapLogLevel(level),
    );

    // 디버그 모드에서는 콘솔에도 출력
    if (kDebugMode) {
      debugPrint(logMessage);
    }
  }

  static Map<String, dynamic> _maskSensitiveData(Map<String, dynamic> data) {
    final masked = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      if (_isSensitiveKey(key)) {
        masked[entry.key] = _maskValue(value);
      } else if (value is Map<String, dynamic>) {
        masked[entry.key] = _maskSensitiveData(value);
      } else {
        masked[entry.key] = value;
      }
    }
    
    return masked;
  }

  static bool _isSensitiveKey(String key) {
    const sensitiveKeys = {
      'token', 'access_token', 'refresh_token', 'password', 'secret',
      'key', 'auth', 'credential', 'authorization', 'bearer'
    };
    return sensitiveKeys.any((sensitive) => key.contains(sensitive));
  }

  static String _maskValue(dynamic value) {
    if (value == null) return 'null';
    final str = value.toString();
    if (str.length <= 8) return '***';
    return '${str.substring(0, 4)}...***';
  }

  static int _mapLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
"""