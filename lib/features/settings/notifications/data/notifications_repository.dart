import 'notification_settings.dart';
import 'notifications_api.dart';

class NotificationsRepository {
  NotificationsRepository({
    NotificationsApi? api,
  }) : _api = api ?? NotificationsApi();

  final NotificationsApi _api;
  NotificationSettings? _cachedSettings;

  Future<NotificationSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    try {
      final settings = await _api.getSettings();
      _cachedSettings = settings;
      return settings;
    } catch (e) {
      _cachedSettings = NotificationSettings.defaultSettings;
      return _cachedSettings!;
    }
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    _cachedSettings = settings;

    try {
      await _api.updateSettings(settings);
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() {
    _cachedSettings = null;
  }
}