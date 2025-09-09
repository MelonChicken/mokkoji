import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../db/app_database.dart';
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import 'event_change_bus.dart';
import 'occurrence_indexer.dart';

/// Draft for creating new events
/// TIMEZONE CONTRACT: startTime/endTime must be UTC for DB storage
class EventDraft {
  final String title;
  final String? description;
  final DateTime startTime; // Must be UTC
  final DateTime? endTime; // Must be UTC
  final bool allDay;
  final String? location;
  final String sourcePlatform;
  final String? platformColor;
  
  const EventDraft({
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.allDay = false,
    this.location,
    this.sourcePlatform = 'internal',
    this.platformColor,
  });
}

/// Patch for updating existing events
/// TIMEZONE CONTRACT: startTime/endTime must be UTC for DB storage
class EventPatch {
  final String id;
  final String? title;
  final String? description;
  final DateTime? startTime; // Must be UTC
  final DateTime? endTime; // Must be UTC
  final bool? allDay;
  final String? location;
  final String? sourcePlatform;
  final String? platformColor;
  
  const EventPatch({
    required this.id,
    this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.allDay,
    this.location,
    this.sourcePlatform,
    this.platformColor,
  });
}

/// Single write service for all event CRUD operations
/// Ensures consistency by using transactions and change notifications
class EventWriteService {
  final EventsDao _dao;
  final EventChangeBus _changeBus;
  final OccurrenceIndexer _indexer;
  
  EventWriteService(
    AppDatabase database, 
    EventChangeBus changeBus,
  ) : _dao = EventsDao(),
      _changeBus = changeBus,
      _indexer = OccurrenceIndexer.instance;

  /// Add new event
  /// TIMEZONE CONTRACT: draft.startTime/endTime must be UTC
  Future<void> addEvent(EventDraft draft) async {
    // ✅ 이중 안전장치: 런타임 방어 + 디버그 경고
    final startUtc = draft.startTime.isUtc ? draft.startTime : draft.startTime.toUtc();
    final endUtc = draft.endTime?.isUtc == false ? draft.endTime!.toUtc() : draft.endTime;
    
    if (kDebugMode) {
      if (!draft.startTime.isUtc) {
        debugPrint('[Event Write WARN] non-UTC startTime passed: ${draft.startTime}');
      }
      if (draft.endTime?.isUtc == false) {
        debugPrint('[Event Write WARN] non-UTC endTime passed: ${draft.endTime}');
      }
    }
    
    final now = DateTime.now().toUtc(); // Ensure UTC for metadata
    final eventId = const Uuid().v4();
    
    if (kDebugMode) {
      debugPrint('📝 Adding event: ${draft.title} at ${draft.startTime} UTC');
    }
    
    final event = EventEntity(
      id: eventId,
      title: draft.title,
      description: draft.description,
      startDt: startUtc.toIso8601String(),
      endDt: endUtc?.toIso8601String(),
      allDay: draft.allDay,
      location: draft.location,
      sourcePlatform: draft.sourcePlatform,
      platformColor: draft.platformColor,
      updatedAt: now.toIso8601String(),
    );
    
    // Transaction: DB write + change notification
    await _dao.upsert(event);
    
    _changeBus.emit(EventChanged(
      eventId: eventId,
      type: EventChangeType.created,
      timestamp: now,
    ));
    
    if (kDebugMode) {
      debugPrint('✅ Event added: $eventId');
    }
  }
  
  /// Update existing event  
  /// TIMEZONE CONTRACT: patch.startTime/endTime must be UTC
  Future<void> updateEvent(EventPatch patch) async {
    // ✅ 이중 안전장치: 런타임 방어 + 디버그 경고
    final startUtc = patch.startTime?.isUtc == false ? patch.startTime!.toUtc() : patch.startTime;
    final endUtc = patch.endTime?.isUtc == false ? patch.endTime!.toUtc() : patch.endTime;
    
    if (kDebugMode) {
      if (patch.startTime?.isUtc == false) {
        debugPrint('[Event Update WARN] non-UTC startTime passed: ${patch.startTime}');
      }
      if (patch.endTime?.isUtc == false) {
        debugPrint('[Event Update WARN] non-UTC endTime passed: ${patch.endTime}');
      }
    }
    
    final now = DateTime.now().toUtc(); // Ensure UTC for metadata
    
    if (kDebugMode) {
      debugPrint('📝 Updating event: ${patch.id}');
    }
    
    // Get current event
    final current = await _dao.getById(patch.id);
    if (current == null) {
      throw Exception('Event not found: ${patch.id}');
    }
    
    // Apply patch
    final updated = current.copyWith(
      title: patch.title ?? current.title,
      description: patch.description ?? current.description,
      startDt: startUtc?.toIso8601String() ?? current.startDt,
      endDt: endUtc?.toIso8601String() ?? current.endDt,
      allDay: patch.allDay ?? current.allDay,
      location: patch.location ?? current.location,
      sourcePlatform: patch.sourcePlatform ?? current.sourcePlatform,
      platformColor: patch.platformColor ?? current.platformColor,
      updatedAt: now.toIso8601String(),
    );
    
    // Transaction: DB write + change notification
    await _dao.upsert(updated);
    
    _changeBus.emit(EventChanged(
      eventId: patch.id,
      type: EventChangeType.updated,
      timestamp: now,
    ));
    
    if (kDebugMode) {
      debugPrint('✅ Event updated: ${patch.id}');
    }
  }
  
  /// Delete event
  Future<void> deleteEvent(String id, {bool hard = false}) async {
    final now = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('🗑️ Deleting event: $id (hard: $hard)');
    }
    
    if (hard) {
      await _dao.hardDelete(id);
    } else {
      await _dao.softDelete(id, now.toIso8601String());
    }
    
    _changeBus.emit(EventChanged(
      eventId: id,
      type: EventChangeType.deleted,
      timestamp: now,
    ));
    
    if (kDebugMode) {
      debugPrint('✅ Event deleted: $id');
    }
  }
  
  /// Batch operations
  Future<void> addEvents(List<EventDraft> drafts) async {
    if (drafts.isEmpty) return;
    
    final now = DateTime.now();
    final events = <EventEntity>[];
    final changes = <EventChanged>[];
    
    for (final draft in drafts) {
      final eventId = const Uuid().v4();
      
      events.add(EventEntity(
        id: eventId,
        title: draft.title,
        description: draft.description,
        startDt: draft.startTime.toIso8601String(),
        endDt: draft.endTime?.toIso8601String(),
        allDay: draft.allDay,
        location: draft.location,
        sourcePlatform: draft.sourcePlatform,
        platformColor: draft.platformColor,
        updatedAt: now.toIso8601String(),
      ));
      
      changes.add(EventChanged(
        eventId: eventId,
        type: EventChangeType.created,
        timestamp: now,
      ));
    }
    
    // Batch transaction
    await _dao.upsertAll(events);
    _changeBus.emitAll(changes);
    
    if (kDebugMode) {
      debugPrint('✅ Batch added ${events.length} events');
    }
  }
}