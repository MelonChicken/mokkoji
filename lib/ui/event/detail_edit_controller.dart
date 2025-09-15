import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/time/app_time.dart';
import '../../core/time/kst.dart';
import '../../core/recurrence/rrule_codec.dart';
import '../../data/services/event_write_service.dart';
import '../../data/providers/unified_providers.dart';
import '../../features/events/data/event_entity.dart';
import '../../features/events/providers/events_providers.dart';

/// State for in-place detail editing
class DetailEditState {
  // Basic fields
  final String title;
  final DateTime dateKst;       // KST date only (no time component)
  final TimeOfDay? startTod;    // KST start time
  final int durationMin;        // Duration in minutes
  final String location;        // Location
  final String memo;           // Description/memo

  // Repeat fields
  final RepeatRule repeat;      // Repeat configuration

  // State management
  final bool isDirty;           // Has unsaved changes
  final bool isValid;           // Form is valid
  final bool isSaving;          // Currently saving
  final String? error;          // Error message
  final String? conflictMessage; // Conflict warning
  final bool hasConflict;       // Conflict detected

  const DetailEditState({
    this.title = '',
    required this.dateKst,
    this.startTod,
    this.durationMin = 60,
    this.location = '',
    this.memo = '',
    this.repeat = const RepeatRule(),
    this.isDirty = false,
    this.isValid = false,
    this.isSaving = false,
    this.error,
    this.conflictMessage,
    this.hasConflict = false,
  });

  /// Get preview end time in KST
  TimeOfDay? get endTimePreview {
    if (startTod == null) return null;
    final totalMinutes = startTod!.hour * 60 + startTod!.minute + durationMin;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// Form validation
  bool get formIsValid =>
      title.trim().isNotEmpty &&
      startTod != null &&
      durationMin >= 5 &&
      repeat.isValid;

  DetailEditState copyWith({
    String? title,
    DateTime? dateKst,
    TimeOfDay? startTod,
    int? durationMin,
    String? location,
    String? memo,
    RepeatRule? repeat,
    bool? isDirty,
    bool? isValid,
    bool? isSaving,
    String? error,
    String? conflictMessage,
    bool? hasConflict,
  }) {
    return DetailEditState(
      title: title ?? this.title,
      dateKst: dateKst ?? this.dateKst,
      startTod: startTod ?? this.startTod,
      durationMin: durationMin ?? this.durationMin,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      repeat: repeat ?? this.repeat,
      isDirty: isDirty ?? this.isDirty,
      isValid: isValid ?? this.isValid,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      conflictMessage: conflictMessage,
      hasConflict: hasConflict ?? this.hasConflict,
    );
  }
}

/// Controller for detail edit state
class DetailEditController extends FamilyNotifier<DetailEditState, String> {
  EventEntity? _originalEvent;

  @override
  DetailEditState build(String arg) {
    final eventId = arg;
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event != null) {
          _originalEvent = event;
          return _initializeFromEvent(event);
        }
        return DetailEditState(dateKst: DateTime.now());
      },
      loading: () => DetailEditState(dateKst: DateTime.now()),
      error: (_, __) => DetailEditState(dateKst: DateTime.now()),
    );
  }

  DetailEditState _initializeFromEvent(EventEntity event) {
    // Parse UTC times safely
    final startUtc = KST.parseUtcIsoLenient(event.startDt);

    // Convert to KST for editing
    final startKst = AppTime.toKst(startUtc);

    // Extract date and time components
    final dateKst = DateTime(startKst.year, startKst.month, startKst.day);
    final startTod = TimeOfDay(hour: startKst.hour, minute: startKst.minute);

    // Parse repeat rule
    final repeat = RepeatRule.fromRRule(event.rrule) ?? const RepeatRule();

    return DetailEditState(
      title: event.title,
      dateKst: dateKst,
      startTod: startTod,
      durationMin: event.durationMin,
      location: event.location ?? '',
      memo: event.description ?? '',
      repeat: repeat,
      isValid: true, // Initially valid from existing event
    );
  }

  // Field setters - mark as dirty and validate
  void setTitle(String title) {
    final newState = state.copyWith(
      title: title,
      isDirty: true,
      isValid: state.copyWith(title: title).formIsValid,
    );
    state = newState;
  }

  void setDate(DateTime dateKst) {
    final newState = state.copyWith(
      dateKst: dateKst,
      isDirty: true,
    );
    state = newState;
  }

  void setTime(TimeOfDay time) {
    final newState = state.copyWith(
      startTod: time,
      isDirty: true,
      isValid: state.copyWith(startTod: time).formIsValid,
    );
    state = newState;
  }

  void setDuration(int minutes) {
    final clampedMinutes = minutes.clamp(5, 720); // 5 minutes to 12 hours
    final newState = state.copyWith(
      durationMin: clampedMinutes,
      isDirty: true,
      isValid: state.copyWith(durationMin: clampedMinutes).formIsValid,
    );
    state = newState;
  }

  void setLocation(String location) {
    final newState = state.copyWith(
      location: location,
      isDirty: true,
    );
    state = newState;
  }

  void setMemo(String memo) {
    final newState = state.copyWith(
      memo: memo,
      isDirty: true,
    );
    state = newState;
  }

  void setRepeat(RepeatRule repeat) {
    final newState = state.copyWith(
      repeat: repeat,
      isDirty: true,
      isValid: state.copyWith(repeat: repeat).formIsValid,
    );
    state = newState;
  }

  /// Normalize text by trimming and basic cleanup
  String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Save changes
  Future<void> save(BuildContext context) async {
    if (!state.formIsValid || state.isSaving || _originalEvent == null) return;

    state = state.copyWith(isSaving: true, error: null, hasConflict: false);

    try {
      // Combine KST date + time
      final date = state.dateKst;
      final time = state.startTod!;
      final startKst = tz.TZDateTime(
        AppTime.kst,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Convert to UTC for storage
      final startUtc = AppTime.fromKstToUtc(startKst);

      // Normalize text fields only at save time (preserves IME composition during editing)
      final normalizedTitle = _normalizeText(state.title);
      final normalizedMemo = state.memo.trim();
      final normalizedLocation = state.location.trim();

      // Generate RRULE if needed
      final rrule = state.repeat.isNone ? null : state.repeat.toRRule(startKst);

      // Create patch with normalized text and recurrence
      final patch = EventPatch(
        id: _originalEvent!.id,
        title: normalizedTitle,
        description: normalizedMemo.isEmpty ? null : normalizedMemo,
        startTime: startUtc,
        location: normalizedLocation.isEmpty ? null : normalizedLocation,
        rrule: rrule,
        tzid: state.repeat.isNone ? null : 'Asia/Seoul',
        durationMin: state.durationMin,
      );

      // Save through service with conflict detection
      await ref.read(eventWriteServiceProvider).updateEvent(
        patch,
        expectedUpdatedAt: _originalEvent!.updatedAt,
      );

      // Success - mark as saved and reset dirty flag
      state = state.copyWith(
        isSaving: false,
        isDirty: false,
        hasConflict: false,
        conflictMessage: null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 수정되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } on EventConflictException catch (conflict) {
      // Conflict detected - show warning banner
      state = state.copyWith(
        isSaving: false,
        hasConflict: true,
        conflictMessage: conflict.message,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(conflict.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '새로고침',
              onPressed: () => refreshAndRetry(),
            ),
          ),
        );
      }
    } catch (e) {
      // General error state
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
        hasConflict: false,
        conflictMessage: null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => save(context),
            ),
          ),
        );
      }
    }
  }

  /// Cancel changes (reset to original)
  void cancel() {
    if (_originalEvent != null) {
      final originalState = _initializeFromEvent(_originalEvent!);
      state = originalState.copyWith(
        isDirty: false,
        error: null,
        hasConflict: false,
        conflictMessage: null,
      );
    }
  }

  /// Check if has unsaved changes
  bool hasUnsavedChanges() => state.isDirty;

  /// Refresh original event data and clear conflict state
  void refreshAndRetry() async {
    if (_originalEvent == null) return;

    try {
      // Get fresh event data
      final freshEvent = await ref.read(eventByIdProvider(_originalEvent!.id).future);
      if (freshEvent != null) {
        _originalEvent = freshEvent;
        // Clear conflict state
        state = state.copyWith(
          hasConflict: false,
          conflictMessage: null,
          error: null,
        );
      }
    } catch (e) {
      // Handle refresh failure
      state = state.copyWith(
        hasConflict: false,
        conflictMessage: null,
        error: 'Failed to refresh: $e',
      );
    }
  }
}

/// Provider for detail edit controller
final detailEditControllerProvider = NotifierProvider.family<DetailEditController, DetailEditState, String>(
  DetailEditController.new,
);