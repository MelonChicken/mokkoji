class NotificationSettings {
  const NotificationSettings({
    required this.dailyBriefing,
    required this.eventReminder,
    required this.mokkojiInvite,
    required this.attendeeResponse,
  });

  final DailyBriefingSettings dailyBriefing;
  final EventReminderSettings eventReminder;
  final MokkojiInviteSettings mokkojiInvite;
  final AttendeeResponseSettings attendeeResponse;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      dailyBriefing: DailyBriefingSettings.fromJson(json['dailyBriefing'] ?? {}),
      eventReminder: EventReminderSettings.fromJson(json['eventReminder'] ?? {}),
      mokkojiInvite: MokkojiInviteSettings.fromJson(json['mokkojiInvite'] ?? {}),
      attendeeResponse: AttendeeResponseSettings.fromJson(json['attendeeResponse'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyBriefing': dailyBriefing.toJson(),
      'eventReminder': eventReminder.toJson(),
      'mokkojiInvite': mokkojiInvite.toJson(),
      'attendeeResponse': attendeeResponse.toJson(),
    };
  }

  NotificationSettings copyWith({
    DailyBriefingSettings? dailyBriefing,
    EventReminderSettings? eventReminder,
    MokkojiInviteSettings? mokkojiInvite,
    AttendeeResponseSettings? attendeeResponse,
  }) {
    return NotificationSettings(
      dailyBriefing: dailyBriefing ?? this.dailyBriefing,
      eventReminder: eventReminder ?? this.eventReminder,
      mokkojiInvite: mokkojiInvite ?? this.mokkojiInvite,
      attendeeResponse: attendeeResponse ?? this.attendeeResponse,
    );
  }

  static const defaultSettings = NotificationSettings(
    dailyBriefing: DailyBriefingSettings(enabled: true, time: '08:00'),
    eventReminder: EventReminderSettings(enabled: true, offsetMinutes: 15),
    mokkojiInvite: MokkojiInviteSettings(enabled: true),
    attendeeResponse: AttendeeResponseSettings(enabled: true),
  );
}

class DailyBriefingSettings {
  const DailyBriefingSettings({
    required this.enabled,
    required this.time,
  });

  final bool enabled;
  final String time; // 24h format '08:00'

  factory DailyBriefingSettings.fromJson(Map<String, dynamic> json) {
    return DailyBriefingSettings(
      enabled: json['enabled'] ?? true,
      time: json['time'] ?? '08:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'time': time,
    };
  }

  DailyBriefingSettings copyWith({
    bool? enabled,
    String? time,
  }) {
    return DailyBriefingSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

class EventReminderSettings {
  const EventReminderSettings({
    required this.enabled,
    required this.offsetMinutes,
  });

  final bool enabled;
  final int offsetMinutes; // 5, 10, 15, 30, 60, 1440

  factory EventReminderSettings.fromJson(Map<String, dynamic> json) {
    return EventReminderSettings(
      enabled: json['enabled'] ?? true,
      offsetMinutes: json['offsetMinutes'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'offsetMinutes': offsetMinutes,
    };
  }

  EventReminderSettings copyWith({
    bool? enabled,
    int? offsetMinutes,
  }) {
    return EventReminderSettings(
      enabled: enabled ?? this.enabled,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
    );
  }
}

class MokkojiInviteSettings {
  const MokkojiInviteSettings({
    required this.enabled,
  });

  final bool enabled;

  factory MokkojiInviteSettings.fromJson(Map<String, dynamic> json) {
    return MokkojiInviteSettings(
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
    };
  }

  MokkojiInviteSettings copyWith({
    bool? enabled,
  }) {
    return MokkojiInviteSettings(
      enabled: enabled ?? this.enabled,
    );
  }
}

class AttendeeResponseSettings {
  const AttendeeResponseSettings({
    required this.enabled,
  });

  final bool enabled;

  factory AttendeeResponseSettings.fromJson(Map<String, dynamic> json) {
    return AttendeeResponseSettings(
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
    };
  }

  AttendeeResponseSettings copyWith({
    bool? enabled,
  }) {
    return AttendeeResponseSettings(
      enabled: enabled ?? this.enabled,
    );
  }
}