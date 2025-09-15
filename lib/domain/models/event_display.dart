import '../../features/events/data/event_entity.dart';
import '../../data/dao/instances_dao.dart';

/// Unified display model for both master events and materialized instances
/// Allows timeline/agenda screens to show all occurrences seamlessly
class EventDisplay {
  final String id;                    // Unique ID (master.id or instance.id as string)
  final String parentId;              // Master event ID (same as id for masters)
  final String title;
  final String? description;
  final String startDt;               // Start time (UTC ISO)
  final String? endDt;                // End time (UTC ISO)
  final bool allDay;
  final String? location;
  final String sourcePlatform;
  final String? platformColor;
  final int durationMin;

  // Instance-specific fields
  final bool isInstance;              // true for instances, false for master
  final int? instanceSeq;             // Sequence number for instances
  final String? dayKeyKst;            // KST day key for instances
  final bool isDetached;              // true if instance was edited individually

  // Master-specific fields
  final String? rrule;                // Repeat rule (only for masters)
  final String? tzid;                 // Timezone ID (only for masters)

  // Common metadata
  final String updatedAt;
  final String? deletedAt;

  const EventDisplay({
    required this.id,
    required this.parentId,
    required this.title,
    this.description,
    required this.startDt,
    this.endDt,
    required this.allDay,
    this.location,
    required this.sourcePlatform,
    this.platformColor,
    required this.durationMin,
    required this.isInstance,
    this.instanceSeq,
    this.dayKeyKst,
    this.isDetached = false,
    this.rrule,
    this.tzid,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Create EventDisplay from master EventEntity
  factory EventDisplay.fromMaster(EventEntity master) {
    return EventDisplay(
      id: master.id,
      parentId: master.id,
      title: master.title,
      description: master.description,
      startDt: master.startDt,
      endDt: master.endDt,
      allDay: master.allDay,
      location: master.location,
      sourcePlatform: master.sourcePlatform,
      platformColor: master.platformColor,
      durationMin: master.durationMin,
      isInstance: false,
      rrule: master.rrule,
      tzid: master.tzid,
      updatedAt: master.updatedAt,
      deletedAt: master.deletedAt,
    );
  }

  /// Create EventDisplay from materialized InstanceRow + master EventEntity
  factory EventDisplay.fromInstance(InstanceRow instance, EventEntity master) {
    return EventDisplay(
      id: instance.id?.toString() ?? '${instance.parentId}_${instance.instanceSeq}',
      parentId: instance.parentId,
      title: master.title,
      description: master.description,
      startDt: instance.startUtc,
      endDt: instance.endUtc,
      allDay: master.allDay,
      location: master.location,
      sourcePlatform: master.sourcePlatform,
      platformColor: master.platformColor,
      durationMin: master.durationMin,
      isInstance: true,
      instanceSeq: instance.instanceSeq,
      dayKeyKst: instance.dayKeyKst,
      isDetached: instance.detached == 1,
      updatedAt: instance.updatedAt,
      deletedAt: instance.deletedAt,
    );
  }

  /// Calculate end time if not provided
  DateTime get endTime {
    if (endDt != null) {
      return DateTime.parse(endDt!);
    }
    return DateTime.parse(startDt).add(Duration(minutes: durationMin));
  }

  /// Get start time as DateTime
  DateTime get startTime => DateTime.parse(startDt);

  /// Check if this is a repeating event (master only)
  bool get isRepeating => !isInstance && rrule != null && rrule!.isNotEmpty;

  /// Get display type for debugging
  String get displayType {
    if (isInstance) {
      return isDetached ? 'detached_instance' : 'instance';
    }
    return isRepeating ? 'repeating_master' : 'single_master';
  }

  @override
  String toString() {
    return 'EventDisplay{id: $id, parent: $parentId, type: $displayType, '
           'title: $title, start: $startDt${instanceSeq != null ? ', seq: $instanceSeq' : ''}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDisplay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentId == other.parentId &&
          startDt == other.startDt;

  @override
  int get hashCode => id.hashCode ^ parentId.hashCode ^ startDt.hashCode;
}