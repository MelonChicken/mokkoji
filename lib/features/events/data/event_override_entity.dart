import 'dart:convert';

class EventOverrideEntity {
  final String id; // local uuid
  final String icalUid; // parent recurring UID
  final String recurrenceId; // RECURRENCE-ID (ISO local)
  final String? startDt;
  final String? endDt;
  final bool? allDay;
  final String? title;
  final String? description;
  final String? location;
  final String? status;
  final List<Map<String, dynamic>>? attendees;
  final String lastModified;

  EventOverrideEntity({
    required this.id,
    required this.icalUid,
    required this.recurrenceId,
    this.startDt,
    this.endDt,
    this.allDay,
    this.title,
    this.description,
    this.location,
    this.status,
    this.attendees,
    required this.lastModified,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'ical_uid': icalUid,
        'recurrence_id': recurrenceId,
        'start_dt': startDt,
        'end_dt': endDt,
        'all_day': allDay == null ? null : (allDay! ? 1 : 0),
        'title': title,
        'description': description,
        'location': location,
        'status': status,
        'attendees_json': attendees == null ? null : jsonEncode(attendees),
        'last_modified': lastModified,
      };

  static EventOverrideEntity fromMap(Map<String, Object?> m) =>
      EventOverrideEntity(
        id: m['id'] as String,
        icalUid: m['ical_uid'] as String,
        recurrenceId: m['recurrence_id'] as String,
        startDt: m['start_dt'] as String?,
        endDt: m['end_dt'] as String?,
        allDay: (m['all_day'] as int?) == null
            ? null
            : ((m['all_day'] as int) == 1),
        title: m['title'] as String?,
        description: m['description'] as String?,
        location: m['location'] as String?,
        status: m['status'] as String?,
        attendees: (m['attendees_json'] as String?) == null
            ? null
            : (jsonDecode(m['attendees_json'] as String) as List)
                .cast<Map<String, dynamic>>(),
        lastModified: m['last_modified'] as String,
      );

  EventOverrideEntity copyWith({
    String? id,
    String? icalUid,
    String? recurrenceId,
    String? startDt,
    String? endDt,
    bool? allDay,
    String? title,
    String? description,
    String? location,
    String? status,
    List<Map<String, dynamic>>? attendees,
    String? lastModified,
  }) =>
      EventOverrideEntity(
        id: id ?? this.id,
        icalUid: icalUid ?? this.icalUid,
        recurrenceId: recurrenceId ?? this.recurrenceId,
        startDt: startDt ?? this.startDt,
        endDt: endDt ?? this.endDt,
        allDay: allDay ?? this.allDay,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        status: status ?? this.status,
        attendees: attendees ?? this.attendees,
        lastModified: lastModified ?? this.lastModified,
      );
}