import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/field_card.dart';
import 'detail_edit_controller.dart';
import 'repeat_section.dart';

/// In-place detail editing form with recurrence support
class DetailEditForm extends ConsumerWidget {
  final String eventId;

  const DetailEditForm({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detailEditControllerProvider(eventId));
    final controller = ref.read(detailEditControllerProvider(eventId).notifier);
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conflict warning banner
        if (state.hasConflict) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ConflictWarningBanner(
              message: state.conflictMessage ?? '충돌이 감지되었습니다.',
              onRefresh: () => controller.refreshAndRetry(),
              onDismiss: () => controller.refreshAndRetry(),
            ),
          ),
        ],

        // Title field
        _TitleField(
          initialValue: state.title,
          onChanged: controller.setTitle,
        ),
        const SizedBox(height: 16),

        // Date and time
        _DateAndTimeRow(
          date: state.dateKst,
          onPickDate: controller.setDate,
          time: state.startTod,
          onPickTime: controller.setTime,
        ),
        const SizedBox(height: 16),

        // Duration with end time preview
        _DurationRow(
          minutes: state.durationMin,
          onChanged: controller.setDuration,
          endTimePreview: state.endTimePreview,
        ),
        const SizedBox(height: 16),

        // Location field
        _LocationField(
          initialValue: state.location,
          onChanged: controller.setLocation,
        ),
        const SizedBox(height: 16),

        // Memo field
        _MemoField(
          initialValue: state.memo,
          onChanged: controller.setMemo,
        ),
        const SizedBox(height: 16),

        // Repeat section
        RepeatSection(
          repeat: state.repeat,
          onChanged: controller.setRepeat,
        ),

        // Bottom spacing for keyboard
        SizedBox(height: 16 + inset),
      ],
    );
  }
}

/// Title input field with Korean IME support
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
          letterSpacing: 0,
        ),
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.none,
        enableSuggestions: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(200),
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
            // Quick duration chips with safe layout
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
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

/// Location input field with Korean IME support
class _LocationField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _LocationField({required this.initialValue, required this.onChanged});

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
          letterSpacing: 0,
        ),
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.none,
        enableSuggestions: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(500),
        ],
      ),
    );
  }
}

/// Memo/description input field with Korean IME support
class _MemoField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _MemoField({required this.initialValue, required this.onChanged});

  @override
  State<_MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends State<_MemoField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
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
      label: '메모',
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '추가 설명을 입력하세요 (선택)',
          prefixIcon: Icon(Icons.description_outlined, color: colorScheme.onSurface.withOpacity(0.7)),
          border: InputBorder.none,
          filled: false,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          letterSpacing: 0,
        ),
        textInputAction: TextInputAction.done,
        maxLines: null, // Allow unlimited lines for memo
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.none,
        enableSuggestions: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(10000),
        ],
      ),
    );
  }
}

/// Conflict warning banner widget
class _ConflictWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;
  final VoidCallback onDismiss;

  const _ConflictWarningBanner({
    required this.message,
    required this.onRefresh,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRefresh,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('새로고침'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            color: colorScheme.onErrorContainer,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}