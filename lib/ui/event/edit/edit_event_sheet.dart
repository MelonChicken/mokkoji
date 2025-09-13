import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/time/app_time.dart';
import '../../../core/time/kst.dart';
import '../../../data/services/event_write_service.dart';
import '../../../data/providers/unified_providers.dart';
import '../../../features/events/data/event_entity.dart';
import '../../../features/events/providers/events_providers.dart';
import '../../widgets/field_card.dart';
import '../../widgets/gradient_button.dart';
import '../../../theme/mokkoji_colors.dart';

/// Edit event form state
class EditEventFormState {
  final String title;
  final DateTime dateKst;
  final TimeOfDay? startTod;
  final int durationMinutes;
  final String location;
  final String description;
  final bool isSaving;
  final String? error;
  final bool hasChanges;
  final bool saved;
  final bool isLoading;

  const EditEventFormState({
    this.title = '',
    required this.dateKst,
    this.startTod,
    this.durationMinutes = 60,
    this.location = '',
    this.description = '',
    this.isSaving = false,
    this.error,
    this.hasChanges = false,
    this.saved = false,
    this.isLoading = false,
  });

  bool get isValid => title.trim().isNotEmpty && startTod != null && durationMinutes >= 5;

  /// Get preview end time in KST
  TimeOfDay? get endTimePreview {
    if (startTod == null) return null;
    final totalMinutes = startTod!.hour * 60 + startTod!.minute + durationMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  EditEventFormState copyWith({
    String? title,
    DateTime? dateKst,
    TimeOfDay? startTod,
    int? durationMinutes,
    String? location,
    String? description,
    bool? isSaving,
    String? error,
    bool? hasChanges,
    bool? saved,
    bool? isLoading,
  }) {
    return EditEventFormState(
      title: title ?? this.title,
      dateKst: dateKst ?? this.dateKst,
      startTod: startTod ?? this.startTod,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      description: description ?? this.description,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
      hasChanges: hasChanges ?? this.hasChanges,
      saved: saved ?? this.saved,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Edit event form notifier
class EditEventFormNotifier extends FamilyNotifier<EditEventFormState, String> {
  EventEntity? _originalEvent;

  @override
  EditEventFormState build(String arg) {
    final eventId = arg;
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    
    return eventAsync.when(
      data: (event) {
        if (event != null) {
          _originalEvent = event;
          return _initializeFromEvent(event);
        }
        return EditEventFormState(dateKst: DateTime.now());
      },
      loading: () => EditEventFormState(dateKst: DateTime.now()),
      error: (_, __) => EditEventFormState(dateKst: DateTime.now()),
    );
  }

  EditEventFormState _initializeFromEvent(EventEntity event) {
    // Parse UTC times safely
    final startUtc = KST.parseUtcIsoLenient(event.startDt);
    final endUtc = event.endDt != null ? KST.parseUtcIsoLenient(event.endDt!) : null;

    // Convert to KST for editing
    final startKst = AppTime.toKst(startUtc);
    final endKst = endUtc != null ? AppTime.toKst(endUtc) : null;

    // Extract date and time components
    final dateKst = DateTime(startKst.year, startKst.month, startKst.day);
    final startTod = TimeOfDay(hour: startKst.hour, minute: startKst.minute);

    // Calculate duration
    int durationMinutes = 60;
    if (endKst != null) {
      durationMinutes = endKst.difference(startKst).inMinutes;
    }

    return EditEventFormState(
      title: event.title,
      dateKst: dateKst,
      startTod: startTod,
      durationMinutes: durationMinutes,
      location: event.location ?? '',
      description: event.description ?? '',
    );
  }

  void setTitle(String title) {
    state = state.copyWith(title: title, hasChanges: true);
  }

  void setDate(DateTime dateKst) {
    state = state.copyWith(dateKst: dateKst, hasChanges: true);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(startTod: time, hasChanges: true);
  }

  void setDuration(int minutes) {
    final clampedMinutes = minutes.clamp(5, 720);
    state = state.copyWith(durationMinutes: clampedMinutes, hasChanges: true);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location, hasChanges: true);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description, hasChanges: true);
  }

  Future<void> save(BuildContext context) async {
    if (!state.isValid || state.isSaving || _originalEvent == null) return;

    state = state.copyWith(isSaving: true, error: null, saved: false);

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
      final endUtc = startUtc.add(Duration(minutes: state.durationMinutes));

      // Create patch
      final patch = EventPatch(
        id: _originalEvent!.id,
        title: state.title.trim(),
        description: state.description.trim().isEmpty ? null : state.description.trim(),
        startTime: startUtc,
        endTime: endUtc,
        location: state.location.trim().isEmpty ? null : state.location.trim(),
      );

      // Save through service
      await ref.read(eventWriteServiceProvider).updateEvent(patch);

      // Success - mark as saved and reset dirty flag
      state = state.copyWith(isSaving: false, saved: true, hasChanges: false);

      // Close sheet and show success
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 수정되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Error state - keep form open for retry
      state = state.copyWith(isSaving: false, error: e.toString());

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

  bool hasUnsavedChanges() => state.hasChanges;
}

/// Provider for edit event form
final editEventFormProvider = NotifierProvider.family<EditEventFormNotifier, EditEventFormState, String>(
  EditEventFormNotifier.new,
);

/// Edit event bottom sheet
class EditEventSheet extends ConsumerWidget {
  final String eventId;

  const EditEventSheet({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editEventFormProvider(eventId));
    final notifier = ref.read(editEventFormProvider(eventId).notifier);

    return PopScope(
      canPop: !state.hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && state.hasChanges) {
          final shouldDiscard = await _showDiscardDialog(context);
          if (shouldDiscard && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _HeaderBar(hasChanges: state.hasChanges),
              const SizedBox(height: 8),

              // Form content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Title field
                      _TitleField(
                        value: state.title,
                        onChanged: notifier.setTitle,
                      ),
                      const SizedBox(height: 12),

                      // Date and time
                      _DateAndTimeRow(
                        date: state.dateKst,
                        onPickDate: notifier.setDate,
                        time: state.startTod,
                        onPickTime: notifier.setTime,
                      ),
                      const SizedBox(height: 12),

                      // Duration with end time preview
                      _DurationRow(
                        minutes: state.durationMinutes,
                        onChanged: notifier.setDuration,
                        endTimePreview: state.endTimePreview,
                      ),
                      const SizedBox(height: 12),

                      // Location field
                      _LocationField(
                        value: state.location,
                        onChanged: notifier.setLocation,
                      ),
                      const SizedBox(height: 12),

                      // Description field
                      _DescriptionField(
                        value: state.description,
                        onChanged: notifier.setDescription,
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: GradientButton(
                          onPressed: (!state.isValid || state.isSaving)
                              ? null
                              : () => notifier.save(context),
                          enabled: state.isValid && !state.isSaving,
                          child: Text(state.isSaving ? '저장 중…' : '수정 완료'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항 버리기'),
        content: const Text('저장하지 않은 변경사항이 있습니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('버리기'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// Header bar with drag handle and title
class _HeaderBar extends StatelessWidget {
  final bool hasChanges;

  const _HeaderBar({required this.hasChanges});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      decoration: BoxDecoration(
        color: isDark ? MokkojiColors.darkAqua50 : MokkojiColors.aqua50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title with change indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '일정 편집',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasChanges) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: MokkojiColors.orange500,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Title input field
class _TitleField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TitleField({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '제목 *',
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        decoration: InputDecoration(
          hintText: '일정 제목을 입력하세요',
          prefixIcon: Icon(Icons.title, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}

/// Date and time picker row (reusing from new event sheet)
class _DateAndTimeRow extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPickDate;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPickTime;

  const _DateAndTimeRow({
    required this.date,
    required this.onPickDate,
    required this.time,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(date: date, onPick: onPickDate),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TimeField(time: time, onPick: onPickTime),
        ),
      ],
    );
  }
}

/// Date picker field
class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'yyyy-mm-dd',
            prefixIcon: Icon(Icons.calendar_month, color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          controller: TextEditingController(
            text: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              onPick(picked);
            }
          },
        ),
      ],
    );
  }
}

/// Time picker field
class _TimeField extends StatelessWidget {
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPick;

  const _TimeField({required this.time, required this.onPick});

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시간 *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: '-- --:--',
            prefixIcon: Icon(Icons.access_time, color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          controller: TextEditingController(
            text: time == null ? '' : _formatTime(time!),
          ),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) {
              onPick(picked);
            }
          },
        ),
      ],
    );
  }
}

/// Duration row with end time preview
class _DurationRow extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  final TimeOfDay? endTimePreview;

  const _DurationRow({
    required this.minutes,
    required this.onChanged,
    this.endTimePreview,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소요 시간',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: '분',
                      prefixIcon: Icon(Icons.schedule, color: colorScheme.onSurface.withOpacity(0.7)),
                      suffixText: '분',
                    ),
                    controller: TextEditingController(text: minutes.toString()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null) {
                        onChanged(parsed);
                      }
                    },
                  ),
                  if (endTimePreview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '종료 시각: ${_formatTimePreview(endTimePreview!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quick duration chips
            Wrap(
              spacing: 4,
              children: [30, 60, 90, 120]
                  .map((m) => ActionChip(
                        label: Text('${m}분'),
                        onPressed: () => onChanged(m),
                        backgroundColor: minutes == m
                            ? colorScheme.primary.withOpacity(0.15)
                            : colorScheme.surfaceContainerHigh,
                        labelStyle: TextStyle(
                          color: minutes == m ? colorScheme.primary : colorScheme.onSurface,
                          fontWeight: minutes == m ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimePreview(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:$minute';
  }
}

/// Location input field
class _LocationField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LocationField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '장소',
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        decoration: InputDecoration(
          hintText: '장소를 입력하세요 (선택)',
          prefixIcon: Icon(Icons.place_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}

/// Description input field
class _DescriptionField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DescriptionField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '설명',
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        decoration: InputDecoration(
          hintText: '추가 설명을 입력하세요 (선택)',
          prefixIcon: Icon(Icons.description_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: onChanged,
        textInputAction: TextInputAction.done,
        maxLines: 3,
        minLines: 1,
      ),
    );
  }
}

/// Show edit event sheet
Future<void> showEditEventSheet(BuildContext context, String eventId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    barrierColor: Colors.black.withOpacity(0.5),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
      ),
    ),
    builder: (ctx) => EditEventSheet(eventId: eventId),
  );
}