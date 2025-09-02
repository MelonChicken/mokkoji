import 'dart:async';

/// DB 변경 신호를 브로드캐스트하는 이벤트 버스
/// SQLite change stream이 없으므로 수동 신호로 reactive UI 구현
class DbSignal {
  DbSignal._();
  static final instance = DbSignal._();
  
  final _eventsController = StreamController<void>.broadcast();
  final _overridesController = StreamController<void>.broadcast();
  final _allController = StreamController<void>.broadcast();

  /// 이벤트 테이블 변경 신호
  void pingEvents() {
    _eventsController.add(null);
    _allController.add(null);
  }

  /// 오버라이드 테이블 변경 신호  
  void pingOverrides() {
    _overridesController.add(null);
    _allController.add(null);
  }

  /// 모든 변경 신호 (이벤트 + 오버라이드)
  void pingAll() {
    _eventsController.add(null);
    _overridesController.add(null);
    _allController.add(null);
  }

  /// 이벤트 변경 구독
  Stream<void> get eventsStream => _eventsController.stream;
  
  /// 오버라이드 변경 구독
  Stream<void> get overridesStream => _overridesController.stream;
  
  /// 모든 변경 구독
  Stream<void> get allStream => _allController.stream;

  /// 리소스 정리 (테스트용)
  void dispose() {
    _eventsController.close();
    _overridesController.close();
    _allController.close();
  }
}