import 'package:flutter/foundation.dart';
import '../data/notification_settings.dart';
import '../data/notifications_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    NotificationsRepository? repository,
  }) : _repository = repository ?? NotificationsRepository();

  final NotificationsRepository _repository;
  
  NotificationSettings? _settings;
  bool _isLoading = false;
  String? _errorMessage;

  NotificationSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.getSettings();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '설정을 불러올 수 없습니다';
      _settings ??= NotificationSettings.defaultSettings;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDailyBriefing({
    bool? enabled,
    String? time,
  }) async {
    if (_settings == null) return;

    final newSettings = _settings!.copyWith(
      dailyBriefing: _settings!.dailyBriefing.copyWith(
        enabled: enabled,
        time: time,
      ),
    );

    await _updateSettings(newSettings);
  }

  Future<void> updateEventReminder({
    bool? enabled,
    int? offsetMinutes,
  }) async {
    if (_settings == null) return;

    final newSettings = _settings!.copyWith(
      eventReminder: _settings!.eventReminder.copyWith(
        enabled: enabled,
        offsetMinutes: offsetMinutes,
      ),
    );

    await _updateSettings(newSettings);
  }

  Future<void> updateMokkojiInvite({
    bool? enabled,
  }) async {
    if (_settings == null) return;

    final newSettings = _settings!.copyWith(
      mokkojiInvite: _settings!.mokkojiInvite.copyWith(
        enabled: enabled,
      ),
    );

    await _updateSettings(newSettings);
  }

  Future<void> updateAttendeeResponse({
    bool? enabled,
  }) async {
    if (_settings == null) return;

    final newSettings = _settings!.copyWith(
      attendeeResponse: _settings!.attendeeResponse.copyWith(
        enabled: enabled,
      ),
    );

    await _updateSettings(newSettings);
  }

  Future<void> _updateSettings(NotificationSettings newSettings) async {
    final originalSettings = _settings;
    _settings = newSettings;
    notifyListeners();

    try {
      await _repository.updateSettings(newSettings);
      _errorMessage = null;
    } catch (e) {
      _settings = originalSettings;
      _errorMessage = '저장에 실패했어요. 다시 시도해주세요';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}