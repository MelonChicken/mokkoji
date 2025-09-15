import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/recurrence/rrule_codec.dart';
import '../widgets/field_card.dart';

/// Repeat/Recurrence configuration section for event editing
class RepeatSection extends StatefulWidget {
  final RepeatRule repeat;
  final ValueChanged<RepeatRule> onChanged;

  const RepeatSection({
    super.key,
    required this.repeat,
    required this.onChanged,
  });

  @override
  State<RepeatSection> createState() => _RepeatSectionState();
}

class _RepeatSectionState extends State<RepeatSection> {
  late TextEditingController _intervalController;
  late TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(text: widget.repeat.interval.toString());
    _countController = TextEditingController(
      text: widget.repeat.count?.toString() ?? '',
    );

    _intervalController.addListener(() {
      final interval = int.tryParse(_intervalController.text) ?? 1;
      if (interval > 0) {
        _updateRepeat(widget.repeat.copyWith(interval: interval));
      }
    });

    _countController.addListener(() {
      if (widget.repeat.endType == RepeatEnd.count) {
        final count = int.tryParse(_countController.text);
        if (count != null && count > 0) {
          _updateRepeat(widget.repeat.copyWith(count: count));
        }
      }
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _updateRepeat(RepeatRule newRepeat) {
    if (newRepeat != widget.repeat) {
      widget.onChanged(newRepeat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FieldCard(
      label: '반복',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frequency selection
            _FrequencySelector(
              freq: widget.repeat.freq,
              onChanged: (freq) => _updateRepeat(
                widget.repeat.copyWith(
                  freq: freq,
                  byWeekday: freq == RepeatFreq.weekly ? {1} : {}, // Default to Monday
                ),
              ),
            ),

            if (widget.repeat.freq != RepeatFreq.none) ...[
              const SizedBox(height: 12),

              // Interval
              _IntervalSelector(
                freq: widget.repeat.freq,
                controller: _intervalController,
              ),

              // Weekly: day selection with AnimatedSize for smooth transitions
              if (widget.repeat.freq == RepeatFreq.weekly) ...[
                const SizedBox(height: 12),
                _WeekdaySelector(
                  selectedDays: widget.repeat.byWeekday,
                  onChanged: (days) => _updateRepeat(
                    widget.repeat.copyWith(byWeekday: days),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // End condition
              _EndSelector(
                endType: widget.repeat.endType,
                count: widget.repeat.count,
                untilKst: widget.repeat.untilKst,
                countController: _countController,
                onEndTypeChanged: (endType) => _updateRepeat(
                  widget.repeat.copyWith(endType: endType),
                ),
                onUntilChanged: (date) => _updateRepeat(
                  widget.repeat.copyWith(untilKst: date),
                ),
              ),

              const SizedBox(height: 8),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.repeat.getSummary(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Frequency selector (None/Daily/Weekly/Monthly)
class _FrequencySelector extends StatelessWidget {
  final RepeatFreq freq;
  final ValueChanged<RepeatFreq> onChanged;

  const _FrequencySelector({
    required this.freq,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FreqChip(
          label: '반복 없음',
          selected: freq == RepeatFreq.none,
          onPressed: () => onChanged(RepeatFreq.none),
        ),
        _FreqChip(
          label: '매일',
          selected: freq == RepeatFreq.daily,
          onPressed: () => onChanged(RepeatFreq.daily),
        ),
        _FreqChip(
          label: '매주',
          selected: freq == RepeatFreq.weekly,
          onPressed: () => onChanged(RepeatFreq.weekly),
        ),
        _FreqChip(
          label: '매월',
          selected: freq == RepeatFreq.monthly,
          onPressed: () => onChanged(RepeatFreq.monthly),
        ),
      ],
    );
  }
}

/// Frequency selection chip
class _FreqChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FreqChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: selected
          ? colorScheme.primary.withOpacity(0.15)
          : colorScheme.surfaceContainerHigh,
      labelStyle: TextStyle(
        color: selected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// Interval selector (Every N days/weeks/months)
class _IntervalSelector extends StatelessWidget {
  final RepeatFreq freq;
  final TextEditingController controller;

  const _IntervalSelector({
    required this.freq,
    required this.controller,
  });

  String _getLabel() {
    switch (freq) {
      case RepeatFreq.daily:
        return '일';
      case RepeatFreq.weekly:
        return '주';
      case RepeatFreq.monthly:
        return '개월';
      case RepeatFreq.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          '간격:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              letterSpacing: 0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_getLabel()}마다',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Weekday selector for weekly repeats
class _WeekdaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  const _WeekdaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '요일 선택:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1; // 1=Mon, 7=Sun
            final isSelected = selectedDays.contains(day);

            return ActionChip(
              label: Text(dayNames[index]),
              onPressed: () {
                final newDays = Set<int>.from(selectedDays);
                if (isSelected) {
                  newDays.remove(day);
                } else {
                  newDays.add(day);
                }
                // Ensure at least one day is selected
                if (newDays.isNotEmpty) {
                  onChanged(newDays);
                }
              },
              backgroundColor: isSelected
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.surfaceContainerHigh,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// End condition selector (Forever/Count/Until)
class _EndSelector extends StatelessWidget {
  final RepeatEnd endType;
  final int? count;
  final DateTime? untilKst;
  final TextEditingController countController;
  final ValueChanged<RepeatEnd> onEndTypeChanged;
  final ValueChanged<DateTime> onUntilChanged;

  const _EndSelector({
    required this.endType,
    required this.count,
    required this.untilKst,
    required this.countController,
    required this.onEndTypeChanged,
    required this.onUntilChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '종료 조건:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // End type chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FreqChip(
              label: '계속',
              selected: endType == RepeatEnd.none,
              onPressed: () => onEndTypeChanged(RepeatEnd.none),
            ),
            _FreqChip(
              label: '횟수',
              selected: endType == RepeatEnd.count,
              onPressed: () => onEndTypeChanged(RepeatEnd.count),
            ),
            _FreqChip(
              label: '날짜',
              selected: endType == RepeatEnd.until,
              onPressed: () => onEndTypeChanged(RepeatEnd.until),
            ),
          ],
        ),

        // Count input with AnimatedSize
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: endType == RepeatEnd.count
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: countController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            letterSpacing: 0,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            hintText: '1',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '회 반복',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Until date picker with AnimatedSize
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: endType == RepeatEnd.until
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: untilKst ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        onUntilChanged(picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      untilKst == null
                          ? '날짜 선택'
                          : '${untilKst!.year}.${untilKst!.month.toString().padLeft(2, '0')}.${untilKst!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}