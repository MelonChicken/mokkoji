import 'dart:convert';

class EventEntity {
  final String id;
  final String title;
  final String? description;
  final String startDt; // DTSTART (ISO8601+TZ)
  final String? endDt; // DTEND or null
  final bool allDay;
  final String? location;

  // 기존 소스 구분
  final String sourcePlatform;
  final String? platformColor;

  // iCalendar 확장
  final String? icalUid; // UID
  final String? dtstamp; // DTSTAMP
  final int? sequence; // SEQUENCE
  final String? rrule; // RRULE
  final String? rdateJson; // RDATE set (JSON 배열)
  final String? exdateJson; // EXDATE set (JSON 배열)
  final String? tzid; // TZID (DTSTART/END 공통)
  final String? transparency; // TRANSP (OPAQUE/TRANSPARENT)
  final String? url; // URL
  final String? categoriesJson; // CATEGORIES (JSON 배열)
  final String? organizerEmail; // ORGANIZER (파싱된 메일)
  final double? geoLat; // GEO lat
  final double? geoLng; // GEO lng

  final String? recurrenceRule; // (기존 필드 유지 시 사용 안함) → rrule로 대체 가이드
  final String? status;
  final List<Map<String, dynamic>>? attendees;
  final String updatedAt;
  final String? deletedAt;

  EventEntity({
    required this.id,
    required this.title,
    this.description,
    required this.startDt,
    this.endDt,
    required this.allDay,
    this.location,
    required this.sourcePlatform,
    this.platformColor,
    this.icalUid,
    this.dtstamp,
    this.sequence,
    this.rrule,
    this.rdateJson,
    this.exdateJson,
    this.tzid,
    this.transparency,
    this.url,
    this.categoriesJson,
    this.organizerEmail,
    this.geoLat,
    this.geoLng,
    this.recurrenceRule, // deprecated 대체경로 유지
    this.status,
    this.attendees,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'start_dt': startDt,
        'end_dt': endDt,
        'all_day': allDay ? 1 : 0,
        'location': location,
        'source_platform': sourcePlatform,
        'platform_color': platformColor,

        'ical_uid': icalUid,
        'dtstamp': dtstamp,
        'sequence': sequence,
        'rrule': rrule,
        'rdate_json': rdateJson,
        'exdate_json': exdateJson,
        'tzid': tzid,
        'transparency': transparency,
        'url': url,
        'categories_json': categoriesJson,
        'organizer_email': organizerEmail,
        'geo_lat': geoLat,
        'geo_lng': geoLng,

        'recurrence_rule': recurrenceRule,
        'status': status,
        'attendees_json': attendees == null ? null : jsonEncode(attendees),
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  static EventEntity fromMap(Map<String, Object?> m) => EventEntity(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        startDt: m['start_dt'] as String,
        endDt: m['end_dt'] as String?,
        allDay: (m['all_day'] as int) == 1,
        location: m['location'] as String?,
        sourcePlatform: m['source_platform'] as String,
        platformColor: m['platform_color'] as String?,

        icalUid: m['ical_uid'] as String?,
        dtstamp: m['dtstamp'] as String?,
        sequence: m['sequence'] as int?,
        rrule: m['rrule'] as String?,
        rdateJson: m['rdate_json'] as String?,
        exdateJson: m['exdate_json'] as String?,
        tzid: m['tzid'] as String?,
        transparency: m['transparency'] as String?,
        url: m['url'] as String?,
        categoriesJson: m['categories_json'] as String?,
        organizerEmail: m['organizer_email'] as String?,
        geoLat: m['geo_lat'] as double?,
        geoLng: m['geo_lng'] as double?,

        recurrenceRule: m['recurrence_rule'] as String?,
        status: m['status'] as String?,
        attendees: (m['attendees_json'] as String?) == null
            ? null
            : (jsonDecode(m['attendees_json'] as String) as List)
                .cast<Map<String, dynamic>>(),
        updatedAt: m['updated_at'] as String,
        deletedAt: m['deleted_at'] as String?,
      );

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? startDt,
    String? endDt,
    bool? allDay,
    String? location,
    String? sourcePlatform,
    String? platformColor,
    String? icalUid,
    String? dtstamp,
    int? sequence,
    String? rrule,
    String? rdateJson,
    String? exdateJson,
    String? tzid,
    String? transparency,
    String? url,
    String? categoriesJson,
    String? organizerEmail,
    double? geoLat,
    double? geoLng,
    String? recurrenceRule,
    String? status,
    List<Map<String, dynamic>>? attendees,
    String? updatedAt,
    String? deletedAt,
  }) =>
      EventEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        startDt: startDt ?? this.startDt,
        endDt: endDt ?? this.endDt,
        allDay: allDay ?? this.allDay,
        location: location ?? this.location,
        sourcePlatform: sourcePlatform ?? this.sourcePlatform,
        platformColor: platformColor ?? this.platformColor,
        icalUid: icalUid ?? this.icalUid,
        dtstamp: dtstamp ?? this.dtstamp,
        sequence: sequence ?? this.sequence,
        rrule: rrule ?? this.rrule,
        rdateJson: rdateJson ?? this.rdateJson,
        exdateJson: exdateJson ?? this.exdateJson,
        tzid: tzid ?? this.tzid,
        transparency: transparency ?? this.transparency,
        url: url ?? this.url,
        categoriesJson: categoriesJson ?? this.categoriesJson,
        organizerEmail: organizerEmail ?? this.organizerEmail,
        geoLat: geoLat ?? this.geoLat,
        geoLng: geoLng ?? this.geoLng,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        status: status ?? this.status,
        attendees: attendees ?? this.attendees,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}