import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'events_repository.dart';

/// HTTP 기반 이벤트 API 구현체
class HttpEventsApi implements EventsApi {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  HttpEventsApi({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/events').replace(queryParameters: {
        'start': startIso,
        'end': endIso,
      });

      final response = await _client
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw HttpException(
          'Failed to fetch events: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EventsApi.fetchEvents failed: $e');
      }
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Mock 이벤트 API (개발/테스트용)
class MockEventsApi implements EventsApi {
  final List<Map<String, dynamic>> _mockEvents;
  final Duration mockDelay;
  final bool shouldFail;

  MockEventsApi({
    List<Map<String, dynamic>>? mockEvents,
    this.mockDelay = const Duration(milliseconds: 500),
    this.shouldFail = false,
  }) : _mockEvents = mockEvents ?? _defaultMockEvents;

  @override
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  }) async {
    await Future.delayed(mockDelay);

    if (shouldFail) {
      throw Exception('Mock API failure');
    }

    // 날짜 범위에 맞는 이벤트 필터링
    final filteredEvents = _mockEvents.where((event) {
      final eventStart = event['dtstart'] as String? ?? event['startDateTime'] as String?;
      if (eventStart == null) return false;
      
      return eventStart.compareTo(startIso) >= 0 && 
             eventStart.compareTo(endIso) <= 0;
    }).toList();

    return {
      'events': filteredEvents,
      'overrides': <Map<String, dynamic>>[], // 빈 오버라이드 리스트
    };
  }

  static final List<Map<String, dynamic>> _defaultMockEvents = [
    {
      'id': 'mock-event-1',
      'summary': '개발팀 회의',
      'description': '주간 개발 진행 상황 공유',
      'dtstart': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'dtend': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
      'allDay': false,
      'location': '회의실 A',
      'sourcePlatform': 'google',
      'platformColor': '#4285f4',
      'uid': 'mock-uid-1',
      'dtstamp': DateTime.now().toIso8601String(),
      'sequence': 0,
    },
    {
      'id': 'mock-event-2',
      'summary': '점심 약속',
      'description': null,
      'dtstart': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'dtend': DateTime.now().add(const Duration(days: 2, hours: 1)).toIso8601String(),
      'allDay': false,
      'location': '강남역',
      'sourcePlatform': 'internal',
      'platformColor': '#34a853',
      'uid': 'mock-uid-2',
      'dtstamp': DateTime.now().toIso8601String(),
      'sequence': 0,
    },
    {
      'id': 'mock-event-3',
      'summary': '생일',
      'description': '친구 생일파티',
      'dtstart': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'dtend': null,
      'allDay': true,
      'location': null,
      'sourcePlatform': 'outlook',
      'platformColor': '#0078d4',
      'uid': 'mock-uid-3',
      'dtstamp': DateTime.now().toIso8601String(),
      'sequence': 0,
    },
  ];
}

/// HTTP 예외 클래스
class HttpException implements Exception {
  final String message;
  final int statusCode;

  const HttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException($statusCode): $message';
}

/// 로컬 전용 API (오프라인 모드)
class LocalOnlyEventsApi implements EventsApi {
  @override
  Future<Map<String, dynamic>> fetchEvents({
    required String startIso,
    required String endIso,
  }) async {
    // 로컬 전용 모드에서는 항상 빈 결과 반환
    return {
      'events': <Map<String, dynamic>>[],
      'overrides': <Map<String, dynamic>>[],
    };
  }
}