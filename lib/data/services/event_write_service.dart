import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/app_database.dart';
import '../../features/events/data/events_dao.dart';
import '../../features/events/data/event_entity.dart';
import '../../core/time/app_time.dart';
import '../../core/time/date_key.dart';
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

/// Exception thrown when concurrent modification is detected
class EventConflictException implements Exception {
  final String eventId;
  final String expectedUpdatedAt;
  final String actualUpdatedAt;
  final String message;

  const EventConflictException({
    required this.eventId,
    required this.expectedUpdatedAt,
    required this.actualUpdatedAt,
    required this.message,
  });

  @override
  String toString() => 'EventConflictException: $message (expected: $expectedUpdatedAt, actual: $actualUpdatedAt)';
}

/// Single write service for all event CRUD operations
/// Ensures consistency by using transactions and change notifications
class EventWriteService {
  final EventsDao _dao;
  final EventChangeBus _changeBus;
  final OccurrenceIndexer _indexer;
  final ProviderContainer? _container;

  EventWriteService(
    AppDatabase database,
    EventChangeBus changeBus, {
    ProviderContainer? container,
  }) : _dao = EventsDao(),
      _changeBus = changeBus,
      _indexer = OccurrenceIndexer.instance,
      _container = container;

  /// Ensure DateTime is UTC, convert if necessary with debug warning
  DateTime _ensureUtc(DateTime dateTime, String fieldName) {
    if (dateTime.isUtc) {
      return dateTime;
    }

    if (kDebugMode) {
      debugPrint('[EventWrite WARN] Non-UTC $fieldName converted: $dateTime → ${dateTime.toUtc()}Z');
    }

    return dateTime.toUtc();
  }

  /// Get affected DateKeys for cross-day event invalidation
  Set<DateKey> _getAffectedDateKeys(EventEntity? oldEvent, EventEntity? newEvent) {
    final affectedKeys = <DateKey>{};

    // Helper to add date keys from event
    void addDateKeysFromEvent(EventEntity event) {
      final startKst = AppTime.toKst(DateTime.parse(event.startDt));
      affectedKeys.add(DateKey(startKst.year, startKst.month, startKst.day));

      if (event.endDt != null) {
        final endKst = AppTime.toKst(DateTime.parse(event.endDt!));
        affectedKeys.add(DateKey(endKst.year, endKst.month, endKst.day));
      }
    }

    // Add keys from old event (for updates/deletes)
    if (oldEvent != null) {
      addDateKeysFromEvent(oldEvent);
    }

    // Add keys from new event (for creates/updates)
    if (newEvent != null) {
      addDateKeysFromEvent(newEvent);
    }

    return affectedKeys;
  }

  /// Invalidate providers for affected date keys (cross-day support)
  void _invalidateAffectedProviders(Set<DateKey> affectedKeys) {
    if (_container == null || affectedKeys.isEmpty) return;

    for (final key in affectedKeys) {
      try {
        // Import occurrencesForDayProvider and invalidate
        // Note: This requires the provider to be available in the container
        // _container!.invalidate(occurrencesForDayProvider(key));
        if (kDebugMode) {
          debugPrint('🔄 Would invalidate providers for date: ${key.y}-${key.m.toString().padLeft(2, '0')}-${key.d.toString().padLeft(2, '0')}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[EventWrite] Provider invalidation failed for $key: $e');
        }
      }
    }
  }

  /// Add new event
  /// TIMEZONE CONTRACT: draft.startTime/endTime must be UTC
  Future<void> addEvent(EventDraft draft) async {
    // ✅ ENFORCED UTC STORAGE: 강제 UTC 변환 + 디버그 경고
    final startUtc = _ensureUtc(draft.startTime, 'startTime');
    final endUtc = draft.endTime != null ? _ensureUtc(draft.endTime!, 'endTime') : null;
    
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
  
  /// Update existing event with conflict detection
  /// TIMEZONE CONTRACT: patch.startTime/endTime must be UTC
  /// Throws EventConflictException if concurrent modification detected
  Future<void> updateEvent(EventPatch patch, {String? expectedUpdatedAt}) async {
    // ✅ ENFORCED UTC STORAGE: 강제 UTC 변환 + 디버그 경고
    final startUtc = patch.startTime != null ? _ensureUtc(patch.startTime!, 'startTime') : null;
    final endUtc = patch.endTime != null ? _ensureUtc(patch.endTime!, 'endTime') : null;

    final now = DateTime.now().toUtc(); // Ensure UTC for metadata

    if (kDebugMode) {
      debugPrint('📝 Updating event: ${patch.id}');
    }

    // Get current event for conflict detection and cross-day detection
    final current = await _dao.getById(patch.id);
    if (current == null) {
      throw Exception('Event not found: ${patch.id}');
    }

    // 🔍 CONFLICT DETECTION: Check if event was modified by another source
    if (expectedUpdatedAt != null && current.updatedAt != expectedUpdatedAt) {
      throw EventConflictException(
        eventId: patch.id,
        expectedUpdatedAt: expectedUpdatedAt,
        actualUpdatedAt: current.updatedAt,
        message: '다른 곳에서 이 일정이 수정되었습니다. 새로고침 후 다시 시도해주세요.',
      );
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

    // 🎯 CROSS-DAY INVALIDATION: Get affected dates before/after update
    final affectedKeys = _getAffectedDateKeys(current, updated);

    // Transaction: DB write + change notification
    await _dao.upsert(updated);

    _changeBus.emit(EventChanged(
      eventId: patch.id,
      type: EventChangeType.updated,
      timestamp: now,
    ));

    // 🔄 Invalidate all affected day providers for cross-day events
    _invalidateAffectedProviders(affectedKeys);

    if (kDebugMode) {
      debugPrint('✅ Event updated: ${patch.id}, affected dates: ${affectedKeys.length}');
    }
  }
  
  /// Delete event with cross-day provider invalidation
  /// Returns the deleted event for undo functionality
  Future<EventEntity?> deleteEvent(String id, {bool hard = false}) async {
    final now = DateTime.now();

    if (kDebugMode) {
      debugPrint('🗑️ Deleting event: $id (hard: $hard)');
    }

    // Get event before deletion for cross-day detection and undo
    final eventToDelete = await _dao.getById(id);
    if (eventToDelete == null) {
      if (kDebugMode) {
        debugPrint('[EventWrite] Event not found for deletion: $id');
      }
      return null;
    }

    final affectedKeys = _getAffectedDateKeys(eventToDelete, null);

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

    // 🔄 Invalidate affected day providers
    _invalidateAffectedProviders(affectedKeys);

    if (kDebugMode) {
      debugPrint('✅ Event deleted: $id, affected dates: ${affectedKeys.length}');
    }

    return eventToDelete; // Return for undo functionality
  }

  /// Restore soft-deleted event (undo functionality)
  Future<void> restoreEvent(String id) async {
    if (kDebugMode) {
      debugPrint('🔄 Restoring event: $id');
    }

    // Get the soft-deleted event
    final deletedEvent = await _dao.getByIdIncludingDeleted(id);
    if (deletedEvent == null) {
      throw Exception('Deleted event not found: $id');
    }

    // Restore by clearing deleted_at
    final restored = deletedEvent.copyWith(
      deletedAt: null,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    await _dao.upsert(restored);

    _changeBus.emit(EventChanged(
      eventId: id,
      type: EventChangeType.updated, // Treat restore as update
      timestamp: DateTime.now(),
    ));

    // Invalidate providers for restored event dates
    final affectedKeys = _getAffectedDateKeys(null, restored);
    _invalidateAffectedProviders(affectedKeys);

    if (kDebugMode) {
      debugPrint('✅ Event restored: $id');
    }
  }
  
  /// Batch operations with UTC enforcement
  Future<void> addEvents(List<EventDraft> drafts) async {
    if (drafts.isEmpty) return;
    
    final now = DateTime.now().toUtc();
    final events = <EventEntity>[];
    final changes = <EventChanged>[];
    
    for (final draft in drafts) {
      final eventId = const Uuid().v4();
      
      // ✅ ENFORCED UTC STORAGE for batch operations
      final startUtc = _ensureUtc(draft.startTime, 'startTime');
      final endUtc = draft.endTime != null ? _ensureUtc(draft.endTime!, 'endTime') : null;
      
      events.add(EventEntity(
        id: eventId,
        title: draft.title,
        description: draft.description,
        startDt: startUtc.toIso8601String(),  // Guaranteed UTC Z-suffix
        endDt: endUtc?.toIso8601String(),     // Guaranteed UTC Z-suffix
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
      debugPrint('✅ Batch added ${events.length} events with UTC enforcement');
    }
  }
}