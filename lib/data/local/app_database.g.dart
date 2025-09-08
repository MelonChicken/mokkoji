// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CalendarTable extends Calendar
    with TableInfo<$CalendarTable, CalendarData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourcePlatformMeta =
      const VerificationMeta('sourcePlatform');
  @override
  late final GeneratedColumn<String> sourcePlatform = GeneratedColumn<String>(
      'source_platform', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _externalCalendarIdMeta =
      const VerificationMeta('externalCalendarId');
  @override
  late final GeneratedColumn<String> externalCalendarId =
      GeneratedColumn<String>('external_calendar_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
      'tz', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Asia/Seoul'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        displayName,
        sourcePlatform,
        externalCalendarId,
        tz,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('source_platform')) {
      context.handle(
          _sourcePlatformMeta,
          sourcePlatform.isAcceptableOrUnknown(
              data['source_platform']!, _sourcePlatformMeta));
    }
    if (data.containsKey('external_calendar_id')) {
      context.handle(
          _externalCalendarIdMeta,
          externalCalendarId.isAcceptableOrUnknown(
              data['external_calendar_id']!, _externalCalendarIdMeta));
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      sourcePlatform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_platform']),
      externalCalendarId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}external_calendar_id']),
      tz: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tz'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalendarTable createAlias(String alias) {
    return $CalendarTable(attachedDatabase, alias);
  }
}

class CalendarData extends DataClass implements Insertable<CalendarData> {
  final String id;
  final String displayName;
  final String? sourcePlatform;
  final String? externalCalendarId;
  final String tz;
  final int createdAt;
  final int updatedAt;
  const CalendarData(
      {required this.id,
      required this.displayName,
      this.sourcePlatform,
      this.externalCalendarId,
      required this.tz,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || sourcePlatform != null) {
      map['source_platform'] = Variable<String>(sourcePlatform);
    }
    if (!nullToAbsent || externalCalendarId != null) {
      map['external_calendar_id'] = Variable<String>(externalCalendarId);
    }
    map['tz'] = Variable<String>(tz);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CalendarCompanion toCompanion(bool nullToAbsent) {
    return CalendarCompanion(
      id: Value(id),
      displayName: Value(displayName),
      sourcePlatform: sourcePlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePlatform),
      externalCalendarId: externalCalendarId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalCalendarId),
      tz: Value(tz),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarData(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sourcePlatform: serializer.fromJson<String?>(json['sourcePlatform']),
      externalCalendarId:
          serializer.fromJson<String?>(json['externalCalendarId']),
      tz: serializer.fromJson<String>(json['tz']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'sourcePlatform': serializer.toJson<String?>(sourcePlatform),
      'externalCalendarId': serializer.toJson<String?>(externalCalendarId),
      'tz': serializer.toJson<String>(tz),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CalendarData copyWith(
          {String? id,
          String? displayName,
          Value<String?> sourcePlatform = const Value.absent(),
          Value<String?> externalCalendarId = const Value.absent(),
          String? tz,
          int? createdAt,
          int? updatedAt}) =>
      CalendarData(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        sourcePlatform:
            sourcePlatform.present ? sourcePlatform.value : this.sourcePlatform,
        externalCalendarId: externalCalendarId.present
            ? externalCalendarId.value
            : this.externalCalendarId,
        tz: tz ?? this.tz,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalendarData copyWithCompanion(CalendarCompanion data) {
    return CalendarData(
      id: data.id.present ? data.id.value : this.id,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      sourcePlatform: data.sourcePlatform.present
          ? data.sourcePlatform.value
          : this.sourcePlatform,
      externalCalendarId: data.externalCalendarId.present
          ? data.externalCalendarId.value
          : this.externalCalendarId,
      tz: data.tz.present ? data.tz.value : this.tz,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarData(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('externalCalendarId: $externalCalendarId, ')
          ..write('tz: $tz, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, sourcePlatform,
      externalCalendarId, tz, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarData &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.sourcePlatform == this.sourcePlatform &&
          other.externalCalendarId == this.externalCalendarId &&
          other.tz == this.tz &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarCompanion extends UpdateCompanion<CalendarData> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String?> sourcePlatform;
  final Value<String?> externalCalendarId;
  final Value<String> tz;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CalendarCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sourcePlatform = const Value.absent(),
    this.externalCalendarId = const Value.absent(),
    this.tz = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarCompanion.insert({
    required String id,
    required String displayName,
    this.sourcePlatform = const Value.absent(),
    this.externalCalendarId = const Value.absent(),
    this.tz = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        displayName = Value(displayName);
  static Insertable<CalendarData> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? sourcePlatform,
    Expression<String>? externalCalendarId,
    Expression<String>? tz,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (sourcePlatform != null) 'source_platform': sourcePlatform,
      if (externalCalendarId != null)
        'external_calendar_id': externalCalendarId,
      if (tz != null) 'tz': tz,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarCompanion copyWith(
      {Value<String>? id,
      Value<String>? displayName,
      Value<String?>? sourcePlatform,
      Value<String?>? externalCalendarId,
      Value<String>? tz,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return CalendarCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      externalCalendarId: externalCalendarId ?? this.externalCalendarId,
      tz: tz ?? this.tz,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sourcePlatform.present) {
      map['source_platform'] = Variable<String>(sourcePlatform.value);
    }
    if (externalCalendarId.present) {
      map['external_calendar_id'] = Variable<String>(externalCalendarId.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('sourcePlatform: $sourcePlatform, ')
          ..write('externalCalendarId: $externalCalendarId, ')
          ..write('tz: $tz, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventTable extends Event with TableInfo<$EventTable, EventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _calendarIdMeta =
      const VerificationMeta('calendarId');
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
      'calendar_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES calendar (id)'));
  static const VerificationMeta _externalEventIdMeta =
      const VerificationMeta('externalEventId');
  @override
  late final GeneratedColumn<String> externalEventId = GeneratedColumn<String>(
      'external_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startUtcMeta =
      const VerificationMeta('startUtc');
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
      'start_utc', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
      'end_utc', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recurrenceRuleMeta =
      const VerificationMeta('recurrenceRule');
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
      'recurrence_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _externalUpdatedAtMeta =
      const VerificationMeta('externalUpdatedAt');
  @override
  late final GeneratedColumn<int> externalUpdatedAt = GeneratedColumn<int>(
      'external_updated_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _externalVersionMeta =
      const VerificationMeta('externalVersion');
  @override
  late final GeneratedColumn<String> externalVersion = GeneratedColumn<String>(
      'external_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastModifiedLocalMeta =
      const VerificationMeta('lastModifiedLocal');
  @override
  late final GeneratedColumn<int> lastModifiedLocal = GeneratedColumn<int>(
      'last_modified_local', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('synced'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        calendarId,
        externalEventId,
        title,
        description,
        startUtc,
        endUtc,
        allDay,
        location,
        recurrenceRule,
        externalUpdatedAt,
        externalVersion,
        deleted,
        lastModifiedLocal,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event';
  @override
  VerificationContext validateIntegrity(Insertable<EventData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
          _calendarIdMeta,
          calendarId.isAcceptableOrUnknown(
              data['calendar_id']!, _calendarIdMeta));
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('external_event_id')) {
      context.handle(
          _externalEventIdMeta,
          externalEventId.isAcceptableOrUnknown(
              data['external_event_id']!, _externalEventIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_utc')) {
      context.handle(_startUtcMeta,
          startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta));
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(_endUtcMeta,
          endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta));
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
          _recurrenceRuleMeta,
          recurrenceRule.isAcceptableOrUnknown(
              data['recurrence_rule']!, _recurrenceRuleMeta));
    }
    if (data.containsKey('external_updated_at')) {
      context.handle(
          _externalUpdatedAtMeta,
          externalUpdatedAt.isAcceptableOrUnknown(
              data['external_updated_at']!, _externalUpdatedAtMeta));
    }
    if (data.containsKey('external_version')) {
      context.handle(
          _externalVersionMeta,
          externalVersion.isAcceptableOrUnknown(
              data['external_version']!, _externalVersionMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('last_modified_local')) {
      context.handle(
          _lastModifiedLocalMeta,
          lastModifiedLocal.isAcceptableOrUnknown(
              data['last_modified_local']!, _lastModifiedLocalMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      calendarId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}calendar_id'])!,
      externalEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}external_event_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_utc'])!,
      endUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_utc'])!,
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      recurrenceRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_rule']),
      externalUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}external_updated_at']),
      externalVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}external_version']),
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      lastModifiedLocal: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_modified_local'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $EventTable createAlias(String alias) {
    return $EventTable(attachedDatabase, alias);
  }
}

class EventData extends DataClass implements Insertable<EventData> {
  final String id;
  final String calendarId;
  final String? externalEventId;
  final String title;
  final String? description;
  final int startUtc;
  final int endUtc;
  final bool allDay;
  final String? location;
  final String? recurrenceRule;
  final int? externalUpdatedAt;
  final String? externalVersion;
  final bool deleted;
  final int lastModifiedLocal;
  final String syncStatus;
  const EventData(
      {required this.id,
      required this.calendarId,
      this.externalEventId,
      required this.title,
      this.description,
      required this.startUtc,
      required this.endUtc,
      required this.allDay,
      this.location,
      this.recurrenceRule,
      this.externalUpdatedAt,
      this.externalVersion,
      required this.deleted,
      required this.lastModifiedLocal,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['calendar_id'] = Variable<String>(calendarId);
    if (!nullToAbsent || externalEventId != null) {
      map['external_event_id'] = Variable<String>(externalEventId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_utc'] = Variable<int>(startUtc);
    map['end_utc'] = Variable<int>(endUtc);
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || externalUpdatedAt != null) {
      map['external_updated_at'] = Variable<int>(externalUpdatedAt);
    }
    if (!nullToAbsent || externalVersion != null) {
      map['external_version'] = Variable<String>(externalVersion);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['last_modified_local'] = Variable<int>(lastModifiedLocal);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  EventCompanion toCompanion(bool nullToAbsent) {
    return EventCompanion(
      id: Value(id),
      calendarId: Value(calendarId),
      externalEventId: externalEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalEventId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      allDay: Value(allDay),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      externalUpdatedAt: externalUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUpdatedAt),
      externalVersion: externalVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(externalVersion),
      deleted: Value(deleted),
      lastModifiedLocal: Value(lastModifiedLocal),
      syncStatus: Value(syncStatus),
    );
  }

  factory EventData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventData(
      id: serializer.fromJson<String>(json['id']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      externalEventId: serializer.fromJson<String?>(json['externalEventId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startUtc: serializer.fromJson<int>(json['startUtc']),
      endUtc: serializer.fromJson<int>(json['endUtc']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      location: serializer.fromJson<String?>(json['location']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      externalUpdatedAt: serializer.fromJson<int?>(json['externalUpdatedAt']),
      externalVersion: serializer.fromJson<String?>(json['externalVersion']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      lastModifiedLocal: serializer.fromJson<int>(json['lastModifiedLocal']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'calendarId': serializer.toJson<String>(calendarId),
      'externalEventId': serializer.toJson<String?>(externalEventId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startUtc': serializer.toJson<int>(startUtc),
      'endUtc': serializer.toJson<int>(endUtc),
      'allDay': serializer.toJson<bool>(allDay),
      'location': serializer.toJson<String?>(location),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'externalUpdatedAt': serializer.toJson<int?>(externalUpdatedAt),
      'externalVersion': serializer.toJson<String?>(externalVersion),
      'deleted': serializer.toJson<bool>(deleted),
      'lastModifiedLocal': serializer.toJson<int>(lastModifiedLocal),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  EventData copyWith(
          {String? id,
          String? calendarId,
          Value<String?> externalEventId = const Value.absent(),
          String? title,
          Value<String?> description = const Value.absent(),
          int? startUtc,
          int? endUtc,
          bool? allDay,
          Value<String?> location = const Value.absent(),
          Value<String?> recurrenceRule = const Value.absent(),
          Value<int?> externalUpdatedAt = const Value.absent(),
          Value<String?> externalVersion = const Value.absent(),
          bool? deleted,
          int? lastModifiedLocal,
          String? syncStatus}) =>
      EventData(
        id: id ?? this.id,
        calendarId: calendarId ?? this.calendarId,
        externalEventId: externalEventId.present
            ? externalEventId.value
            : this.externalEventId,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startUtc: startUtc ?? this.startUtc,
        endUtc: endUtc ?? this.endUtc,
        allDay: allDay ?? this.allDay,
        location: location.present ? location.value : this.location,
        recurrenceRule:
            recurrenceRule.present ? recurrenceRule.value : this.recurrenceRule,
        externalUpdatedAt: externalUpdatedAt.present
            ? externalUpdatedAt.value
            : this.externalUpdatedAt,
        externalVersion: externalVersion.present
            ? externalVersion.value
            : this.externalVersion,
        deleted: deleted ?? this.deleted,
        lastModifiedLocal: lastModifiedLocal ?? this.lastModifiedLocal,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  EventData copyWithCompanion(EventCompanion data) {
    return EventData(
      id: data.id.present ? data.id.value : this.id,
      calendarId:
          data.calendarId.present ? data.calendarId.value : this.calendarId,
      externalEventId: data.externalEventId.present
          ? data.externalEventId.value
          : this.externalEventId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      location: data.location.present ? data.location.value : this.location,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      externalUpdatedAt: data.externalUpdatedAt.present
          ? data.externalUpdatedAt.value
          : this.externalUpdatedAt,
      externalVersion: data.externalVersion.present
          ? data.externalVersion.value
          : this.externalVersion,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      lastModifiedLocal: data.lastModifiedLocal.present
          ? data.lastModifiedLocal.value
          : this.lastModifiedLocal,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventData(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('externalEventId: $externalEventId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('allDay: $allDay, ')
          ..write('location: $location, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('externalUpdatedAt: $externalUpdatedAt, ')
          ..write('externalVersion: $externalVersion, ')
          ..write('deleted: $deleted, ')
          ..write('lastModifiedLocal: $lastModifiedLocal, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      calendarId,
      externalEventId,
      title,
      description,
      startUtc,
      endUtc,
      allDay,
      location,
      recurrenceRule,
      externalUpdatedAt,
      externalVersion,
      deleted,
      lastModifiedLocal,
      syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventData &&
          other.id == this.id &&
          other.calendarId == this.calendarId &&
          other.externalEventId == this.externalEventId &&
          other.title == this.title &&
          other.description == this.description &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.allDay == this.allDay &&
          other.location == this.location &&
          other.recurrenceRule == this.recurrenceRule &&
          other.externalUpdatedAt == this.externalUpdatedAt &&
          other.externalVersion == this.externalVersion &&
          other.deleted == this.deleted &&
          other.lastModifiedLocal == this.lastModifiedLocal &&
          other.syncStatus == this.syncStatus);
}

class EventCompanion extends UpdateCompanion<EventData> {
  final Value<String> id;
  final Value<String> calendarId;
  final Value<String?> externalEventId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> startUtc;
  final Value<int> endUtc;
  final Value<bool> allDay;
  final Value<String?> location;
  final Value<String?> recurrenceRule;
  final Value<int?> externalUpdatedAt;
  final Value<String?> externalVersion;
  final Value<bool> deleted;
  final Value<int> lastModifiedLocal;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const EventCompanion({
    this.id = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.externalEventId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.allDay = const Value.absent(),
    this.location = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.externalUpdatedAt = const Value.absent(),
    this.externalVersion = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastModifiedLocal = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventCompanion.insert({
    required String id,
    required String calendarId,
    this.externalEventId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int startUtc,
    required int endUtc,
    this.allDay = const Value.absent(),
    this.location = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.externalUpdatedAt = const Value.absent(),
    this.externalVersion = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastModifiedLocal = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        calendarId = Value(calendarId),
        title = Value(title),
        startUtc = Value(startUtc),
        endUtc = Value(endUtc);
  static Insertable<EventData> custom({
    Expression<String>? id,
    Expression<String>? calendarId,
    Expression<String>? externalEventId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<bool>? allDay,
    Expression<String>? location,
    Expression<String>? recurrenceRule,
    Expression<int>? externalUpdatedAt,
    Expression<String>? externalVersion,
    Expression<bool>? deleted,
    Expression<int>? lastModifiedLocal,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calendarId != null) 'calendar_id': calendarId,
      if (externalEventId != null) 'external_event_id': externalEventId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (allDay != null) 'all_day': allDay,
      if (location != null) 'location': location,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (externalUpdatedAt != null) 'external_updated_at': externalUpdatedAt,
      if (externalVersion != null) 'external_version': externalVersion,
      if (deleted != null) 'deleted': deleted,
      if (lastModifiedLocal != null) 'last_modified_local': lastModifiedLocal,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventCompanion copyWith(
      {Value<String>? id,
      Value<String>? calendarId,
      Value<String?>? externalEventId,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? startUtc,
      Value<int>? endUtc,
      Value<bool>? allDay,
      Value<String?>? location,
      Value<String?>? recurrenceRule,
      Value<int?>? externalUpdatedAt,
      Value<String?>? externalVersion,
      Value<bool>? deleted,
      Value<int>? lastModifiedLocal,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return EventCompanion(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      externalEventId: externalEventId ?? this.externalEventId,
      title: title ?? this.title,
      description: description ?? this.description,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      externalUpdatedAt: externalUpdatedAt ?? this.externalUpdatedAt,
      externalVersion: externalVersion ?? this.externalVersion,
      deleted: deleted ?? this.deleted,
      lastModifiedLocal: lastModifiedLocal ?? this.lastModifiedLocal,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (externalEventId.present) {
      map['external_event_id'] = Variable<String>(externalEventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (externalUpdatedAt.present) {
      map['external_updated_at'] = Variable<int>(externalUpdatedAt.value);
    }
    if (externalVersion.present) {
      map['external_version'] = Variable<String>(externalVersion.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (lastModifiedLocal.present) {
      map['last_modified_local'] = Variable<int>(lastModifiedLocal.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventCompanion(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('externalEventId: $externalEventId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('allDay: $allDay, ')
          ..write('location: $location, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('externalUpdatedAt: $externalUpdatedAt, ')
          ..write('externalVersion: $externalVersion, ')
          ..write('deleted: $deleted, ')
          ..write('lastModifiedLocal: $lastModifiedLocal, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventOverrideTable extends EventOverride
    with TableInfo<$EventOverrideTable, EventOverrideData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventOverrideTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES event (id)'));
  static const VerificationMeta _occurrenceDateMeta =
      const VerificationMeta('occurrenceDate');
  @override
  late final GeneratedColumn<String> occurrenceDate = GeneratedColumn<String>(
      'occurrence_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _overrideTypeMeta =
      const VerificationMeta('overrideType');
  @override
  late final GeneratedColumn<String> overrideType = GeneratedColumn<String>(
      'override_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('modification'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startUtcMeta =
      const VerificationMeta('startUtc');
  @override
  late final GeneratedColumn<int> startUtc = GeneratedColumn<int>(
      'start_utc', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<int> endUtc = GeneratedColumn<int>(
      'end_utc', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventId,
        occurrenceDate,
        overrideType,
        title,
        description,
        startUtc,
        endUtc,
        location,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_override';
  @override
  VerificationContext validateIntegrity(Insertable<EventOverrideData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
          _occurrenceDateMeta,
          occurrenceDate.isAcceptableOrUnknown(
              data['occurrence_date']!, _occurrenceDateMeta));
    } else if (isInserting) {
      context.missing(_occurrenceDateMeta);
    }
    if (data.containsKey('override_type')) {
      context.handle(
          _overrideTypeMeta,
          overrideType.isAcceptableOrUnknown(
              data['override_type']!, _overrideTypeMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_utc')) {
      context.handle(_startUtcMeta,
          startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta));
    }
    if (data.containsKey('end_utc')) {
      context.handle(_endUtcMeta,
          endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventOverrideData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventOverrideData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      occurrenceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}occurrence_date'])!,
      overrideType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}override_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_utc']),
      endUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_utc']),
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EventOverrideTable createAlias(String alias) {
    return $EventOverrideTable(attachedDatabase, alias);
  }
}

class EventOverrideData extends DataClass
    implements Insertable<EventOverrideData> {
  final String id;
  final String eventId;
  final String occurrenceDate;
  final String overrideType;
  final String? title;
  final String? description;
  final int? startUtc;
  final int? endUtc;
  final String? location;
  final int createdAt;
  const EventOverrideData(
      {required this.id,
      required this.eventId,
      required this.occurrenceDate,
      required this.overrideType,
      this.title,
      this.description,
      this.startUtc,
      this.endUtc,
      this.location,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['occurrence_date'] = Variable<String>(occurrenceDate);
    map['override_type'] = Variable<String>(overrideType);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || startUtc != null) {
      map['start_utc'] = Variable<int>(startUtc);
    }
    if (!nullToAbsent || endUtc != null) {
      map['end_utc'] = Variable<int>(endUtc);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  EventOverrideCompanion toCompanion(bool nullToAbsent) {
    return EventOverrideCompanion(
      id: Value(id),
      eventId: Value(eventId),
      occurrenceDate: Value(occurrenceDate),
      overrideType: Value(overrideType),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startUtc: startUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(startUtc),
      endUtc:
          endUtc == null && nullToAbsent ? const Value.absent() : Value(endUtc),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      createdAt: Value(createdAt),
    );
  }

  factory EventOverrideData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventOverrideData(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      occurrenceDate: serializer.fromJson<String>(json['occurrenceDate']),
      overrideType: serializer.fromJson<String>(json['overrideType']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startUtc: serializer.fromJson<int?>(json['startUtc']),
      endUtc: serializer.fromJson<int?>(json['endUtc']),
      location: serializer.fromJson<String?>(json['location']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'occurrenceDate': serializer.toJson<String>(occurrenceDate),
      'overrideType': serializer.toJson<String>(overrideType),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'startUtc': serializer.toJson<int?>(startUtc),
      'endUtc': serializer.toJson<int?>(endUtc),
      'location': serializer.toJson<String?>(location),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  EventOverrideData copyWith(
          {String? id,
          String? eventId,
          String? occurrenceDate,
          String? overrideType,
          Value<String?> title = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<int?> startUtc = const Value.absent(),
          Value<int?> endUtc = const Value.absent(),
          Value<String?> location = const Value.absent(),
          int? createdAt}) =>
      EventOverrideData(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        occurrenceDate: occurrenceDate ?? this.occurrenceDate,
        overrideType: overrideType ?? this.overrideType,
        title: title.present ? title.value : this.title,
        description: description.present ? description.value : this.description,
        startUtc: startUtc.present ? startUtc.value : this.startUtc,
        endUtc: endUtc.present ? endUtc.value : this.endUtc,
        location: location.present ? location.value : this.location,
        createdAt: createdAt ?? this.createdAt,
      );
  EventOverrideData copyWithCompanion(EventOverrideCompanion data) {
    return EventOverrideData(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      occurrenceDate: data.occurrenceDate.present
          ? data.occurrenceDate.value
          : this.occurrenceDate,
      overrideType: data.overrideType.present
          ? data.overrideType.value
          : this.overrideType,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      location: data.location.present ? data.location.value : this.location,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventOverrideData(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('overrideType: $overrideType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventId, occurrenceDate, overrideType,
      title, description, startUtc, endUtc, location, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventOverrideData &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.overrideType == this.overrideType &&
          other.title == this.title &&
          other.description == this.description &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.location == this.location &&
          other.createdAt == this.createdAt);
}

class EventOverrideCompanion extends UpdateCompanion<EventOverrideData> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> occurrenceDate;
  final Value<String> overrideType;
  final Value<String?> title;
  final Value<String?> description;
  final Value<int?> startUtc;
  final Value<int?> endUtc;
  final Value<String?> location;
  final Value<int> createdAt;
  final Value<int> rowid;
  const EventOverrideCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.overrideType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.location = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventOverrideCompanion.insert({
    required String id,
    required String eventId,
    required String occurrenceDate,
    this.overrideType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.location = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventId = Value(eventId),
        occurrenceDate = Value(occurrenceDate);
  static Insertable<EventOverrideData> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? occurrenceDate,
    Expression<String>? overrideType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? startUtc,
    Expression<int>? endUtc,
    Expression<String>? location,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (overrideType != null) 'override_type': overrideType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (location != null) 'location': location,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventOverrideCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventId,
      Value<String>? occurrenceDate,
      Value<String>? overrideType,
      Value<String?>? title,
      Value<String?>? description,
      Value<int?>? startUtc,
      Value<int?>? endUtc,
      Value<String?>? location,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return EventOverrideCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      overrideType: overrideType ?? this.overrideType,
      title: title ?? this.title,
      description: description ?? this.description,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<String>(occurrenceDate.value);
    }
    if (overrideType.present) {
      map['override_type'] = Variable<String>(overrideType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<int>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<int>(endUtc.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventOverrideCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('overrideType: $overrideType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendeeTable extends Attendee
    with TableInfo<$AttendeeTable, AttendeeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendeeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES event (id)'));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _responseStatusMeta =
      const VerificationMeta('responseStatus');
  @override
  late final GeneratedColumn<String> responseStatus = GeneratedColumn<String>(
      'response_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('needsAction'));
  static const VerificationMeta _isOrganizerMeta =
      const VerificationMeta('isOrganizer');
  @override
  late final GeneratedColumn<bool> isOrganizer = GeneratedColumn<bool>(
      'is_organizer', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_organizer" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, eventId, email, displayName, responseStatus, isOrganizer, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendee';
  @override
  VerificationContext validateIntegrity(Insertable<AttendeeData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('response_status')) {
      context.handle(
          _responseStatusMeta,
          responseStatus.isAcceptableOrUnknown(
              data['response_status']!, _responseStatusMeta));
    }
    if (data.containsKey('is_organizer')) {
      context.handle(
          _isOrganizerMeta,
          isOrganizer.isAcceptableOrUnknown(
              data['is_organizer']!, _isOrganizerMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendeeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendeeData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      responseStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}response_status'])!,
      isOrganizer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_organizer'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AttendeeTable createAlias(String alias) {
    return $AttendeeTable(attachedDatabase, alias);
  }
}

class AttendeeData extends DataClass implements Insertable<AttendeeData> {
  final String id;
  final String eventId;
  final String? email;
  final String? displayName;
  final String responseStatus;
  final bool isOrganizer;
  final int createdAt;
  const AttendeeData(
      {required this.id,
      required this.eventId,
      this.email,
      this.displayName,
      required this.responseStatus,
      required this.isOrganizer,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['response_status'] = Variable<String>(responseStatus);
    map['is_organizer'] = Variable<bool>(isOrganizer);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AttendeeCompanion toCompanion(bool nullToAbsent) {
    return AttendeeCompanion(
      id: Value(id),
      eventId: Value(eventId),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      responseStatus: Value(responseStatus),
      isOrganizer: Value(isOrganizer),
      createdAt: Value(createdAt),
    );
  }

  factory AttendeeData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendeeData(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      email: serializer.fromJson<String?>(json['email']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      responseStatus: serializer.fromJson<String>(json['responseStatus']),
      isOrganizer: serializer.fromJson<bool>(json['isOrganizer']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'email': serializer.toJson<String?>(email),
      'displayName': serializer.toJson<String?>(displayName),
      'responseStatus': serializer.toJson<String>(responseStatus),
      'isOrganizer': serializer.toJson<bool>(isOrganizer),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AttendeeData copyWith(
          {String? id,
          String? eventId,
          Value<String?> email = const Value.absent(),
          Value<String?> displayName = const Value.absent(),
          String? responseStatus,
          bool? isOrganizer,
          int? createdAt}) =>
      AttendeeData(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        email: email.present ? email.value : this.email,
        displayName: displayName.present ? displayName.value : this.displayName,
        responseStatus: responseStatus ?? this.responseStatus,
        isOrganizer: isOrganizer ?? this.isOrganizer,
        createdAt: createdAt ?? this.createdAt,
      );
  AttendeeData copyWithCompanion(AttendeeCompanion data) {
    return AttendeeData(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      responseStatus: data.responseStatus.present
          ? data.responseStatus.value
          : this.responseStatus,
      isOrganizer:
          data.isOrganizer.present ? data.isOrganizer.value : this.isOrganizer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendeeData(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('responseStatus: $responseStatus, ')
          ..write('isOrganizer: $isOrganizer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, eventId, email, displayName, responseStatus, isOrganizer, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendeeData &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.responseStatus == this.responseStatus &&
          other.isOrganizer == this.isOrganizer &&
          other.createdAt == this.createdAt);
}

class AttendeeCompanion extends UpdateCompanion<AttendeeData> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String?> email;
  final Value<String?> displayName;
  final Value<String> responseStatus;
  final Value<bool> isOrganizer;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AttendeeCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.responseStatus = const Value.absent(),
    this.isOrganizer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendeeCompanion.insert({
    required String id,
    required String eventId,
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.responseStatus = const Value.absent(),
    this.isOrganizer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventId = Value(eventId);
  static Insertable<AttendeeData> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? responseStatus,
    Expression<bool>? isOrganizer,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (responseStatus != null) 'response_status': responseStatus,
      if (isOrganizer != null) 'is_organizer': isOrganizer,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendeeCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventId,
      Value<String?>? email,
      Value<String?>? displayName,
      Value<String>? responseStatus,
      Value<bool>? isOrganizer,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AttendeeCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      responseStatus: responseStatus ?? this.responseStatus,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (responseStatus.present) {
      map['response_status'] = Variable<String>(responseStatus.value);
    }
    if (isOrganizer.present) {
      map['is_organizer'] = Variable<bool>(isOrganizer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendeeCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('responseStatus: $responseStatus, ')
          ..write('isOrganizer: $isOrganizer, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarTable calendar = $CalendarTable(this);
  late final $EventTable event = $EventTable(this);
  late final $EventOverrideTable eventOverride = $EventOverrideTable(this);
  late final $AttendeeTable attendee = $AttendeeTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [calendar, event, eventOverride, attendee];
}

typedef $$CalendarTableCreateCompanionBuilder = CalendarCompanion Function({
  required String id,
  required String displayName,
  Value<String?> sourcePlatform,
  Value<String?> externalCalendarId,
  Value<String> tz,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});
typedef $$CalendarTableUpdateCompanionBuilder = CalendarCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String?> sourcePlatform,
  Value<String?> externalCalendarId,
  Value<String> tz,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$CalendarTableReferences
    extends BaseReferences<_$AppDatabase, $CalendarTable, CalendarData> {
  $$CalendarTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventTable, List<EventData>> _eventRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.event,
          aliasName: $_aliasNameGenerator(db.calendar.id, db.event.calendarId));

  $$EventTableProcessedTableManager get eventRefs {
    final manager = $$EventTableTableManager($_db, $_db.event)
        .filter((f) => f.calendarId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CalendarTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarTable> {
  $$CalendarTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourcePlatform => $composableBuilder(
      column: $table.sourcePlatform,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalCalendarId => $composableBuilder(
      column: $table.externalCalendarId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> eventRefs(
      Expression<bool> Function($$EventTableFilterComposer f) f) {
    final $$EventTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.calendarId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableFilterComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarTable> {
  $$CalendarTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourcePlatform => $composableBuilder(
      column: $table.sourcePlatform,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalCalendarId => $composableBuilder(
      column: $table.externalCalendarId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tz => $composableBuilder(
      column: $table.tz, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CalendarTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarTable> {
  $$CalendarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get sourcePlatform => $composableBuilder(
      column: $table.sourcePlatform, builder: (column) => column);

  GeneratedColumn<String> get externalCalendarId => $composableBuilder(
      column: $table.externalCalendarId, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> eventRefs<T extends Object>(
      Expression<T> Function($$EventTableAnnotationComposer a) f) {
    final $$EventTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.calendarId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableAnnotationComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CalendarTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalendarTable,
    CalendarData,
    $$CalendarTableFilterComposer,
    $$CalendarTableOrderingComposer,
    $$CalendarTableAnnotationComposer,
    $$CalendarTableCreateCompanionBuilder,
    $$CalendarTableUpdateCompanionBuilder,
    (CalendarData, $$CalendarTableReferences),
    CalendarData,
    PrefetchHooks Function({bool eventRefs})> {
  $$CalendarTableTableManager(_$AppDatabase db, $CalendarTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> sourcePlatform = const Value.absent(),
            Value<String?> externalCalendarId = const Value.absent(),
            Value<String> tz = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarCompanion(
            id: id,
            displayName: displayName,
            sourcePlatform: sourcePlatform,
            externalCalendarId: externalCalendarId,
            tz: tz,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String displayName,
            Value<String?> sourcePlatform = const Value.absent(),
            Value<String?> externalCalendarId = const Value.absent(),
            Value<String> tz = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CalendarCompanion.insert(
            id: id,
            displayName: displayName,
            sourcePlatform: sourcePlatform,
            externalCalendarId: externalCalendarId,
            tz: tz,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CalendarTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({eventRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventRefs) db.event],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventRefs)
                    await $_getPrefetchedData<CalendarData, $CalendarTable,
                            EventData>(
                        currentTable: table,
                        referencedTable:
                            $$CalendarTableReferences._eventRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CalendarTableReferences(db, table, p0).eventRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.calendarId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CalendarTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CalendarTable,
    CalendarData,
    $$CalendarTableFilterComposer,
    $$CalendarTableOrderingComposer,
    $$CalendarTableAnnotationComposer,
    $$CalendarTableCreateCompanionBuilder,
    $$CalendarTableUpdateCompanionBuilder,
    (CalendarData, $$CalendarTableReferences),
    CalendarData,
    PrefetchHooks Function({bool eventRefs})>;
typedef $$EventTableCreateCompanionBuilder = EventCompanion Function({
  required String id,
  required String calendarId,
  Value<String?> externalEventId,
  required String title,
  Value<String?> description,
  required int startUtc,
  required int endUtc,
  Value<bool> allDay,
  Value<String?> location,
  Value<String?> recurrenceRule,
  Value<int?> externalUpdatedAt,
  Value<String?> externalVersion,
  Value<bool> deleted,
  Value<int> lastModifiedLocal,
  Value<String> syncStatus,
  Value<int> rowid,
});
typedef $$EventTableUpdateCompanionBuilder = EventCompanion Function({
  Value<String> id,
  Value<String> calendarId,
  Value<String?> externalEventId,
  Value<String> title,
  Value<String?> description,
  Value<int> startUtc,
  Value<int> endUtc,
  Value<bool> allDay,
  Value<String?> location,
  Value<String?> recurrenceRule,
  Value<int?> externalUpdatedAt,
  Value<String?> externalVersion,
  Value<bool> deleted,
  Value<int> lastModifiedLocal,
  Value<String> syncStatus,
  Value<int> rowid,
});

final class $$EventTableReferences
    extends BaseReferences<_$AppDatabase, $EventTable, EventData> {
  $$EventTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CalendarTable _calendarIdTable(_$AppDatabase db) => db.calendar
      .createAlias($_aliasNameGenerator(db.event.calendarId, db.calendar.id));

  $$CalendarTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<String>('calendar_id')!;

    final manager = $$CalendarTableTableManager($_db, $_db.calendar)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$EventOverrideTable, List<EventOverrideData>>
      _eventOverrideRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.eventOverride,
              aliasName:
                  $_aliasNameGenerator(db.event.id, db.eventOverride.eventId));

  $$EventOverrideTableProcessedTableManager get eventOverrideRefs {
    final manager = $$EventOverrideTableTableManager($_db, $_db.eventOverride)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventOverrideRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendeeTable, List<AttendeeData>>
      _attendeeRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.attendee,
          aliasName: $_aliasNameGenerator(db.event.id, db.attendee.eventId));

  $$AttendeeTableProcessedTableManager get attendeeRefs {
    final manager = $$AttendeeTableTableManager($_db, $_db.attendee)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendeeRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventTableFilterComposer extends Composer<_$AppDatabase, $EventTable> {
  $$EventTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalEventId => $composableBuilder(
      column: $table.externalEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get externalUpdatedAt => $composableBuilder(
      column: $table.externalUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalVersion => $composableBuilder(
      column: $table.externalVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastModifiedLocal => $composableBuilder(
      column: $table.lastModifiedLocal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  $$CalendarTableFilterComposer get calendarId {
    final $$CalendarTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.calendarId,
        referencedTable: $db.calendar,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarTableFilterComposer(
              $db: $db,
              $table: $db.calendar,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> eventOverrideRefs(
      Expression<bool> Function($$EventOverrideTableFilterComposer f) f) {
    final $$EventOverrideTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eventOverride,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventOverrideTableFilterComposer(
              $db: $db,
              $table: $db.eventOverride,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attendeeRefs(
      Expression<bool> Function($$AttendeeTableFilterComposer f) f) {
    final $$AttendeeTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendee,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeTableFilterComposer(
              $db: $db,
              $table: $db.attendee,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventTableOrderingComposer
    extends Composer<_$AppDatabase, $EventTable> {
  $$EventTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalEventId => $composableBuilder(
      column: $table.externalEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get externalUpdatedAt => $composableBuilder(
      column: $table.externalUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalVersion => $composableBuilder(
      column: $table.externalVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastModifiedLocal => $composableBuilder(
      column: $table.lastModifiedLocal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  $$CalendarTableOrderingComposer get calendarId {
    final $$CalendarTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.calendarId,
        referencedTable: $db.calendar,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarTableOrderingComposer(
              $db: $db,
              $table: $db.calendar,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventTable> {
  $$EventTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalEventId => $composableBuilder(
      column: $table.externalEventId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule, builder: (column) => column);

  GeneratedColumn<int> get externalUpdatedAt => $composableBuilder(
      column: $table.externalUpdatedAt, builder: (column) => column);

  GeneratedColumn<String> get externalVersion => $composableBuilder(
      column: $table.externalVersion, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get lastModifiedLocal => $composableBuilder(
      column: $table.lastModifiedLocal, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  $$CalendarTableAnnotationComposer get calendarId {
    final $$CalendarTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.calendarId,
        referencedTable: $db.calendar,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CalendarTableAnnotationComposer(
              $db: $db,
              $table: $db.calendar,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> eventOverrideRefs<T extends Object>(
      Expression<T> Function($$EventOverrideTableAnnotationComposer a) f) {
    final $$EventOverrideTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.eventOverride,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventOverrideTableAnnotationComposer(
              $db: $db,
              $table: $db.eventOverride,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attendeeRefs<T extends Object>(
      Expression<T> Function($$AttendeeTableAnnotationComposer a) f) {
    final $$AttendeeTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendee,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeTableAnnotationComposer(
              $db: $db,
              $table: $db.attendee,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventTable,
    EventData,
    $$EventTableFilterComposer,
    $$EventTableOrderingComposer,
    $$EventTableAnnotationComposer,
    $$EventTableCreateCompanionBuilder,
    $$EventTableUpdateCompanionBuilder,
    (EventData, $$EventTableReferences),
    EventData,
    PrefetchHooks Function(
        {bool calendarId, bool eventOverrideRefs, bool attendeeRefs})> {
  $$EventTableTableManager(_$AppDatabase db, $EventTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> calendarId = const Value.absent(),
            Value<String?> externalEventId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> startUtc = const Value.absent(),
            Value<int> endUtc = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<int?> externalUpdatedAt = const Value.absent(),
            Value<String?> externalVersion = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> lastModifiedLocal = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventCompanion(
            id: id,
            calendarId: calendarId,
            externalEventId: externalEventId,
            title: title,
            description: description,
            startUtc: startUtc,
            endUtc: endUtc,
            allDay: allDay,
            location: location,
            recurrenceRule: recurrenceRule,
            externalUpdatedAt: externalUpdatedAt,
            externalVersion: externalVersion,
            deleted: deleted,
            lastModifiedLocal: lastModifiedLocal,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String calendarId,
            Value<String?> externalEventId = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            required int startUtc,
            required int endUtc,
            Value<bool> allDay = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<int?> externalUpdatedAt = const Value.absent(),
            Value<String?> externalVersion = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<int> lastModifiedLocal = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventCompanion.insert(
            id: id,
            calendarId: calendarId,
            externalEventId: externalEventId,
            title: title,
            description: description,
            startUtc: startUtc,
            endUtc: endUtc,
            allDay: allDay,
            location: location,
            recurrenceRule: recurrenceRule,
            externalUpdatedAt: externalUpdatedAt,
            externalVersion: externalVersion,
            deleted: deleted,
            lastModifiedLocal: lastModifiedLocal,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EventTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {calendarId = false,
              eventOverrideRefs = false,
              attendeeRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (eventOverrideRefs) db.eventOverride,
                if (attendeeRefs) db.attendee
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (calendarId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.calendarId,
                    referencedTable:
                        $$EventTableReferences._calendarIdTable(db),
                    referencedColumn:
                        $$EventTableReferences._calendarIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventOverrideRefs)
                    await $_getPrefetchedData<EventData, $EventTable,
                            EventOverrideData>(
                        currentTable: table,
                        referencedTable:
                            $$EventTableReferences._eventOverrideRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventTableReferences(db, table, p0)
                                .eventOverrideRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.eventId == item.id),
                        typedResults: items),
                  if (attendeeRefs)
                    await $_getPrefetchedData<EventData, $EventTable,
                            AttendeeData>(
                        currentTable: table,
                        referencedTable:
                            $$EventTableReferences._attendeeRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventTableReferences(db, table, p0).attendeeRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.eventId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EventTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventTable,
    EventData,
    $$EventTableFilterComposer,
    $$EventTableOrderingComposer,
    $$EventTableAnnotationComposer,
    $$EventTableCreateCompanionBuilder,
    $$EventTableUpdateCompanionBuilder,
    (EventData, $$EventTableReferences),
    EventData,
    PrefetchHooks Function(
        {bool calendarId, bool eventOverrideRefs, bool attendeeRefs})>;
typedef $$EventOverrideTableCreateCompanionBuilder = EventOverrideCompanion
    Function({
  required String id,
  required String eventId,
  required String occurrenceDate,
  Value<String> overrideType,
  Value<String?> title,
  Value<String?> description,
  Value<int?> startUtc,
  Value<int?> endUtc,
  Value<String?> location,
  Value<int> createdAt,
  Value<int> rowid,
});
typedef $$EventOverrideTableUpdateCompanionBuilder = EventOverrideCompanion
    Function({
  Value<String> id,
  Value<String> eventId,
  Value<String> occurrenceDate,
  Value<String> overrideType,
  Value<String?> title,
  Value<String?> description,
  Value<int?> startUtc,
  Value<int?> endUtc,
  Value<String?> location,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$EventOverrideTableReferences extends BaseReferences<_$AppDatabase,
    $EventOverrideTable, EventOverrideData> {
  $$EventOverrideTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EventTable _eventIdTable(_$AppDatabase db) => db.event
      .createAlias($_aliasNameGenerator(db.eventOverride.eventId, db.event.id));

  $$EventTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventTableTableManager($_db, $_db.event)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EventOverrideTableFilterComposer
    extends Composer<_$AppDatabase, $EventOverrideTable> {
  $$EventOverrideTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get occurrenceDate => $composableBuilder(
      column: $table.occurrenceDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overrideType => $composableBuilder(
      column: $table.overrideType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EventTableFilterComposer get eventId {
    final $$EventTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableFilterComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventOverrideTableOrderingComposer
    extends Composer<_$AppDatabase, $EventOverrideTable> {
  $$EventOverrideTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get occurrenceDate => $composableBuilder(
      column: $table.occurrenceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideType => $composableBuilder(
      column: $table.overrideType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startUtc => $composableBuilder(
      column: $table.startUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endUtc => $composableBuilder(
      column: $table.endUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EventTableOrderingComposer get eventId {
    final $$EventTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableOrderingComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventOverrideTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventOverrideTable> {
  $$EventOverrideTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get occurrenceDate => $composableBuilder(
      column: $table.occurrenceDate, builder: (column) => column);

  GeneratedColumn<String> get overrideType => $composableBuilder(
      column: $table.overrideType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<int> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EventTableAnnotationComposer get eventId {
    final $$EventTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableAnnotationComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EventOverrideTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventOverrideTable,
    EventOverrideData,
    $$EventOverrideTableFilterComposer,
    $$EventOverrideTableOrderingComposer,
    $$EventOverrideTableAnnotationComposer,
    $$EventOverrideTableCreateCompanionBuilder,
    $$EventOverrideTableUpdateCompanionBuilder,
    (EventOverrideData, $$EventOverrideTableReferences),
    EventOverrideData,
    PrefetchHooks Function({bool eventId})> {
  $$EventOverrideTableTableManager(_$AppDatabase db, $EventOverrideTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventOverrideTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventOverrideTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventOverrideTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> occurrenceDate = const Value.absent(),
            Value<String> overrideType = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> startUtc = const Value.absent(),
            Value<int?> endUtc = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventOverrideCompanion(
            id: id,
            eventId: eventId,
            occurrenceDate: occurrenceDate,
            overrideType: overrideType,
            title: title,
            description: description,
            startUtc: startUtc,
            endUtc: endUtc,
            location: location,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventId,
            required String occurrenceDate,
            Value<String> overrideType = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int?> startUtc = const Value.absent(),
            Value<int?> endUtc = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventOverrideCompanion.insert(
            id: id,
            eventId: eventId,
            occurrenceDate: occurrenceDate,
            overrideType: overrideType,
            title: title,
            description: description,
            startUtc: startUtc,
            endUtc: endUtc,
            location: location,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EventOverrideTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$EventOverrideTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$EventOverrideTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$EventOverrideTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventOverrideTable,
    EventOverrideData,
    $$EventOverrideTableFilterComposer,
    $$EventOverrideTableOrderingComposer,
    $$EventOverrideTableAnnotationComposer,
    $$EventOverrideTableCreateCompanionBuilder,
    $$EventOverrideTableUpdateCompanionBuilder,
    (EventOverrideData, $$EventOverrideTableReferences),
    EventOverrideData,
    PrefetchHooks Function({bool eventId})>;
typedef $$AttendeeTableCreateCompanionBuilder = AttendeeCompanion Function({
  required String id,
  required String eventId,
  Value<String?> email,
  Value<String?> displayName,
  Value<String> responseStatus,
  Value<bool> isOrganizer,
  Value<int> createdAt,
  Value<int> rowid,
});
typedef $$AttendeeTableUpdateCompanionBuilder = AttendeeCompanion Function({
  Value<String> id,
  Value<String> eventId,
  Value<String?> email,
  Value<String?> displayName,
  Value<String> responseStatus,
  Value<bool> isOrganizer,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$AttendeeTableReferences
    extends BaseReferences<_$AppDatabase, $AttendeeTable, AttendeeData> {
  $$AttendeeTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventTable _eventIdTable(_$AppDatabase db) => db.event
      .createAlias($_aliasNameGenerator(db.attendee.eventId, db.event.id));

  $$EventTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventTableTableManager($_db, $_db.event)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AttendeeTableFilterComposer
    extends Composer<_$AppDatabase, $AttendeeTable> {
  $$AttendeeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseStatus => $composableBuilder(
      column: $table.responseStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOrganizer => $composableBuilder(
      column: $table.isOrganizer, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EventTableFilterComposer get eventId {
    final $$EventTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableFilterComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendeeTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendeeTable> {
  $$AttendeeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseStatus => $composableBuilder(
      column: $table.responseStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOrganizer => $composableBuilder(
      column: $table.isOrganizer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EventTableOrderingComposer get eventId {
    final $$EventTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableOrderingComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendeeTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendeeTable> {
  $$AttendeeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get responseStatus => $composableBuilder(
      column: $table.responseStatus, builder: (column) => column);

  GeneratedColumn<bool> get isOrganizer => $composableBuilder(
      column: $table.isOrganizer, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EventTableAnnotationComposer get eventId {
    final $$EventTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.event,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventTableAnnotationComposer(
              $db: $db,
              $table: $db.event,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendeeTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendeeTable,
    AttendeeData,
    $$AttendeeTableFilterComposer,
    $$AttendeeTableOrderingComposer,
    $$AttendeeTableAnnotationComposer,
    $$AttendeeTableCreateCompanionBuilder,
    $$AttendeeTableUpdateCompanionBuilder,
    (AttendeeData, $$AttendeeTableReferences),
    AttendeeData,
    PrefetchHooks Function({bool eventId})> {
  $$AttendeeTableTableManager(_$AppDatabase db, $AttendeeTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendeeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendeeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendeeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String> responseStatus = const Value.absent(),
            Value<bool> isOrganizer = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeeCompanion(
            id: id,
            eventId: eventId,
            email: email,
            displayName: displayName,
            responseStatus: responseStatus,
            isOrganizer: isOrganizer,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventId,
            Value<String?> email = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String> responseStatus = const Value.absent(),
            Value<bool> isOrganizer = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeeCompanion.insert(
            id: id,
            eventId: eventId,
            email: email,
            displayName: displayName,
            responseStatus: responseStatus,
            isOrganizer: isOrganizer,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AttendeeTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$AttendeeTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$AttendeeTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AttendeeTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendeeTable,
    AttendeeData,
    $$AttendeeTableFilterComposer,
    $$AttendeeTableOrderingComposer,
    $$AttendeeTableAnnotationComposer,
    $$AttendeeTableCreateCompanionBuilder,
    $$AttendeeTableUpdateCompanionBuilder,
    (AttendeeData, $$AttendeeTableReferences),
    AttendeeData,
    PrefetchHooks Function({bool eventId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarTableTableManager get calendar =>
      $$CalendarTableTableManager(_db, _db.calendar);
  $$EventTableTableManager get event =>
      $$EventTableTableManager(_db, _db.event);
  $$EventOverrideTableTableManager get eventOverride =>
      $$EventOverrideTableTableManager(_db, _db.eventOverride);
  $$AttendeeTableTableManager get attendee =>
      $$AttendeeTableTableManager(_db, _db.attendee);
}
