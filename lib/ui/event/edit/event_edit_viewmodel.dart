import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/time/app_time.dart';
import '../../../data/services/event_write_service.dart';

/// ViewModel for event edit screen
/// TIMEZONE CONTRACT: UI uses KST, converts to UTC before saving
class EventEditViewModel {
  final EventWriteService _writeService;
  
  EventEditViewModel(this._writeService);

  /// Save new event from UI form
  /// TIMEZONE CONTRACT: dateKst + time pickers are KST, converted to UTC for storage
  Future<void> saveEvent({
    required String title,
    String? description,
    required DateTime dateKst, // Date picker result (KST)
    required TimeOfDay startTimeKst, // Time picker result (KST)
    required TimeOfDay endTimeKst, // Time picker result (KST) 
    bool allDay = false,
    String? location,
    String sourcePlatform = 'internal',
    String? platformColor,
  }) async {
    // Combine date + time in KST timezone
    final startKst = tz.TZDateTime(
      AppTime.kst,
      dateKst.year, dateKst.month, dateKst.day,
      startTimeKst.hour, startTimeKst.minute,
    );
    
    final endKst = tz.TZDateTime(
      AppTime.kst,
      dateKst.year, dateKst.month, dateKst.day,
      endTimeKst.hour, endTimeKst.minute,
    );

    // Convert KST to UTC for DB storage
    final startUtc = AppTime.fromKstToUtc(startKst);
    final endUtc = AppTime.fromKstToUtc(endKst);

    // Create draft with UTC times
    final draft = EventDraft(
      title: title,
      description: description,
      startTime: startUtc, // ✅ UTC for DB
      endTime: endUtc,     // ✅ UTC for DB
      allDay: allDay,
      location: location,
      sourcePlatform: sourcePlatform,
      platformColor: platformColor,
    );

    await _writeService.addEvent(draft);
  }

  /// Update existing event from UI form
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? dateKst, // Date picker result (KST)
    TimeOfDay? startTimeKst, // Time picker result (KST)
    TimeOfDay? endTimeKst, // Time picker result (KST)
    bool? allDay,
    String? location,
    String? sourcePlatform,
    String? platformColor,
  }) async {
    DateTime? startUtc;
    DateTime? endUtc;

    // Convert KST inputs to UTC if provided
    if (dateKst != null && startTimeKst != null) {
      final startKst = tz.TZDateTime(
        AppTime.kst,
        dateKst.year, dateKst.month, dateKst.day,
        startTimeKst.hour, startTimeKst.minute,
      );
      startUtc = AppTime.fromKstToUtc(startKst);
    }

    if (dateKst != null && endTimeKst != null) {
      final endKst = tz.TZDateTime(
        AppTime.kst,
        dateKst.year, dateKst.month, dateKst.day,
        endTimeKst.hour, endTimeKst.minute,
      );
      endUtc = AppTime.fromKstToUtc(endKst);
    }

    // Create patch with UTC times
    final patch = EventPatch(
      id: eventId,
      title: title,
      description: description,
      startTime: startUtc, // ✅ UTC for DB
      endTime: endUtc,     // ✅ UTC for DB
      allDay: allDay,
      location: location,
      sourcePlatform: sourcePlatform,
      platformColor: platformColor,
    );

    await _writeService.updateEvent(patch);
  }
}