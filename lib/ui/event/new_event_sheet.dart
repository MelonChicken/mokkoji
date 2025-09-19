import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/time/app_time.dart';
import '../../data/services/event_write_service.dart';
import '../../data/providers/unified_providers.dart';
import '../widgets/field_card.dart';
import '../widgets/gradient_button.dart';
import '../../theme/mokkoji_colors.dart';

/// State for the simplified new event form
class NewEventFormState {
  final String title;
  final DateTime dateKst;       // KST date only (no time component)
  final TimeOfDay? startTod;    // KST start time
  final int durationMinutes;    // Duration in minutes (default 60)
  final String location;        // Optional location
  final bool isSaving;          // Loading state
  final String? error;          // Error message

  const NewEventFormState({
    this.title = '',
    required this.dateKst,
    this.startTod,
    this.durationMinutes = 60,
    this.location = '',
    this.isSaving = false,
    this.error,
  });

  /// Form is valid if title and start time are provided
  bool get isValid => title.trim().isNotEmpty && startTod != null && durationMinutes >= 5;

  /// Copy method to create new state instances
  NewEventFormState copyWith({
    String? title,
    DateTime? dateKst,
    TimeOfDay? startTod,
    int? durationMinutes,
    String? location,
    bool? isSaving,
    String? error,
  }) {
    return NewEventFormState(
      title: title ?? this.title,
      dateKst: dateKst ?? this.dateKst,
      startTod: startTod ?? this.startTod,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
    );
  }
}

/// Form state notifier for the new event sheet
class NewEventFormNotifier extends Notifier<NewEventFormState> {
  @override
  NewEventFormState build() {
    // Initialize with today's date in KST
    final nowKst = AppTime.nowKst();
    return NewEventFormState(
      dateKst: DateTime(nowKst.year, nowKst.month, nowKst.day),
    );
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setDate(DateTime dateKst) {
    state = state.copyWith(dateKst: dateKst);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(startTod: time);
  }

  void setDuration(int minutes) {
    final clampedMinutes = minutes.clamp(5, 720); // 5 minutes to 12 hours
    state = state.copyWith(durationMinutes: clampedMinutes);
  }

  void setLocation(String location) {
    state = state.copyWith(location: location);
  }

  /// Normalize text by trimming and basic cleanup
  String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Save the event using the EventWriteService
  Future<void> save(WidgetRef ref, BuildContext context) async {
    if (!state.isValid || state.isSaving) return;

    state = state.copyWith(isSaving: true, error: null);

    try {
      // 1. Combine KST date + time into KST DateTime
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

      // 2. Convert to UTC for storage (ENFORCED UTC CONTRACT)
      final startUtc = AppTime.fromKstToUtc(startKst);

      // 3. Assert UTC contract in debug mode
      assert(startUtc.isUtc, 'startUtc must be UTC: $startUtc');

      // 4. Normalize text fields only at save time (preserves IME composition during editing)
      final normalizedTitle = _normalizeText(state.title);
      final normalizedLocation = state.location.trim();

      // 5. Create event draft with guaranteed UTC times and normalized text
      final draft = EventDraft(
        title: normalizedTitle,
        startTime: startUtc,    // Guaranteed UTC for storage
        durationMin: state.durationMinutes, // Duration in minutes
        location: normalizedLocation.isEmpty ? null : normalizedLocation,
        sourcePlatform: 'internal', // Internal events only
      );

      // 6. Save through EventWriteService
      await ref.read(eventWriteServiceProvider).addEvent(draft);

      // 7. Success - close sheet immediately
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 8. Handle error - show snackbar but keep form open
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // 9. ALWAYS restore button state (prevent stuck "저장 중..." state)
      state = state.copyWith(isSaving: false);
    }
  }
}

/// Provider for the new event form state
final newEventFormProvider = NotifierProvider<NewEventFormNotifier, NewEventFormState>(
  NewEventFormNotifier.new,
);

/// Simplified event creation bottom sheet
class NewEventSheetV2 extends ConsumerWidget {
  const NewEventSheetV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newEventFormProvider);
    final notifier = ref.read(newEventFormProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with drag handle
            _HeaderBar(),
            const SizedBox(height: 8),
            
            // Title field (required)
            _TitleField(
              initialValue: state.title,
              onChanged: notifier.setTitle,
            ),
            const SizedBox(height: 12),
            
            // Date and time row
            _DateAndTimeRow(
              date: state.dateKst,
              onPickDate: notifier.setDate,
              time: state.startTod,
              onPickTime: notifier.setTime,
            ),
            const SizedBox(height: 12),
            
            // Duration row with quick chips
            _DurationRow(
              minutes: state.durationMinutes,
              onChanged: notifier.setDuration,
            ),
            const SizedBox(height: 12),
            
            // Location field (optional)
            _LocationField(
              initialValue: state.location,
              onChanged: notifier.setLocation,
            ),
            const SizedBox(height: 20),
            
            // Save button using GradientButton
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: (!state.isValid || state.isSaving)
                    ? null
                    : () => notifier.save(ref, context),
                enabled: state.isValid && !state.isSaving,
                child: Text(state.isSaving ? '저장 중…' : '모으기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header bar with drag handle and title (no gradients)
class _HeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      decoration: BoxDecoration(
        color: MokkojiColors.aqua50,
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
          // Title
          Text(
            '새 일정 만들기',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Title input field with Korean IME composition support
class _TitleField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TitleField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      // READ ONLY: No re-setting or processing during input
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '제목 *',
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '일정 제목을 입력하세요',
          prefixIcon: Icon(Icons.title, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          letterSpacing: 0, // Prevent Korean character separation
        ),
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.none,
        enableSuggestions: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(200), // Length limit only
        ],
      ),
    );
  }
}

/// Date and time picker row
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
        // Date picker
        Expanded(
          child: _DateField(
            date: date,
            onPick: onPickDate,
          ),
        ),
        const SizedBox(width: 12),
        // Time picker
        Expanded(
          child: _TimeField(
            time: time,
            onPick: onPickTime,
          ),
        ),
      ],
    );
  }
}

/// Date picker field
class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.date,
    required this.onPick,
  });

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

  const _TimeField({
    required this.time,
    required this.onPick,
  });

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

/// Duration input row with quick chips
class _DurationRow extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _DurationRow({
    required this.minutes,
    required this.onChanged,
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
        
        // Duration input field
        Row(
          children: [
            Expanded(
              child: TextField(
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
            ),
            const SizedBox(width: 8),
            // Stepper buttons
            Column(
              children: [
                InkWell(
                  onTap: () => onChanged(minutes + 15),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Icon(Icons.add, size: 16, color: colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => onChanged((minutes - 15).clamp(5, 720)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline),
                    ),
                    child: Icon(Icons.remove, size: 16, color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Quick duration chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [30, 60, 90, 120, 180]
              .map((m) => ActionChip(
                    label: Text('${m}분'),
                    onPressed: () => onChanged(m),
                    backgroundColor: minutes == m
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: minutes == m
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: minutes == m ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Location input field with Korean IME composition support
class _LocationField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _LocationField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      // READ ONLY: No re-setting or processing during input
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '장소',
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '장소를 입력하세요 (선택)',
          prefixIcon: Icon(Icons.place_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          letterSpacing: 0, // Prevent Korean character separation
        ),
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
        enableSuggestions: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(500), // Length limit only
        ],
      ),
    );
  }
}

/// Show the new event sheet
Future<void> showNewEventSheetV2(BuildContext context) {
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
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: const NewEventSheetV2(),
    ),
  );
}