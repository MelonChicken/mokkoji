import 'dart:async';
import 'dart:convert';
import 'notification_settings.dart';

class NotificationsApi {
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<NotificationSettings> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return NotificationSettings.defaultSettings;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception('네트워크 오류가 발생했습니다');
    }
  }

  Future<NotificationSettings> _mockRequest() async {
    return const NotificationSettings(
      dailyBriefing: DailyBriefingSettings(enabled: true, time: '08:00'),
      eventReminder: EventReminderSettings(enabled: true, offsetMinutes: 15),
      mokkojiInvite: MokkojiInviteSettings(enabled: true),
      attendeeResponse: AttendeeResponseSettings(enabled: false),
    );
  }
}