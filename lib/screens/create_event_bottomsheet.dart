import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';

Future<void> showEventCreateSheet(BuildContext context) {
  const topRadius = Radius.circular(24); // ← 원하는 곡률 (24~28dp 권장)

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white, // 시트 바탕
    clipBehavior: Clip.antiAlias,   // ✅ 라운드 모서리에 맞춰 내부까지 클립
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: topRadius), // ✅ 상단만 둥글게
    ),
    // (선택) Flutter 버전에 따라 지원되면 드래그 핸들 노출
    // showDragHandle: true,
    builder: (ctx) => _RoundedSheetFrame(
      radius: topRadius,
      child: const EventCreateSheet(), // ← 기존 폼 (입력필드는 그대로)
    ),
  );
}

InputDecoration _inputDecoration(BuildContext context, {
  String? hint,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    suffixIcon: suffixIcon,
  );
}

class EventCreateSheet extends StatefulWidget {
  const EventCreateSheet({super.key});

  @override
  State<EventCreateSheet> createState() => _EventCreateSheetState();
}

class _EventCreateSheetState extends State<EventCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _attendeeController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  final Set<String> _selectedSources = {};
  final List<String> _attendees = [];

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
           _selectedDate != null &&
           _selectedTime != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _attendeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Text(
                    '새 일정 만들기',
                    style: textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 제목 (필수)
              Text('제목 *', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  context,
                  hint: '일정 제목을 입력하세요',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제목은 필수입니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 날짜 및 시간
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: '날짜 *',
                      value: _selectedDate,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 3),
                          initialDate: _selectedDate ?? now,
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: '시간 *',
                      value: _selectedTime,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 장소
              Text('장소', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _placeController,
                decoration: _inputDecoration(
                  context,
                  hint: '장소를 입력하세요',
                  suffixIcon: const Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 참여자
              Text('참여자', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _attendeeController,
                      decoration: _inputDecoration(
                        context,
                        hint: '참여자 이름 또는 연락처',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      final value = _attendeeController.text.trim();
                      if (value.isNotEmpty) {
                        setState(() {
                          _attendees.add(value);
                          _attendeeController.clear();
                        });
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_attendees.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attendees
                      .map((attendee) => InputChip(
                            label: Text(attendee),
                            onDeleted: () => setState(() {
                              _attendees.remove(attendee);
                            }),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),

              // 캘린더 연동
              Text('캘린더 연동', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _SourceChip(
                    label: '카카오',
                    color: const Color(0xFFFEE500),
                    value: 'kakao',
                    selectedSources: _selectedSources,
                    onChanged: () => setState(() {}),
                  ),
                  _SourceChip(
                    label: '네이버',
                    color: const Color(0xFF03C75A),
                    value: 'naver',
                    selectedSources: _selectedSources,
                    onChanged: () => setState(() {}),
                  ),
                  _SourceChip(
                    label: '구글',
                    color: const Color(0xFF4285F4),
                    value: 'google',
                    selectedSources: _selectedSources,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CTA 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isFormValid
                      ? () {
                          if (!_formKey.currentState!.validate()) return;
                          // TODO: Combine date + time → DateTime, call API, then pop
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('모으기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widgets
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextField(
              readOnly: true,
              controller: TextEditingController(
                text: value == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(value!),
              ),
              decoration: _inputDecoration(
                context,
                hint: '연도-월-일',
                suffixIcon: const Icon(Icons.event_outlined),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    String? displayText;
    if (value != null) {
      final hour = value!.hourOfPeriod == 0 ? 12 : value!.hourOfPeriod;
      final minute = value!.minute.toString().padLeft(2, '0');
      final period = value!.period == DayPeriod.am ? '오전' : '오후';
      displayText = '$period $hour:$minute';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: displayText ?? ''),
              decoration: _inputDecoration(
                context,
                hint: '-- --:--',
                suffixIcon: const Icon(Icons.access_time),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.color,
    required this.value,
    required this.selectedSources,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Color color;
  final Set<String> selectedSources;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedSources.contains(value);
    final colorScheme = Theme.of(context).colorScheme;
    
    return FilterChip(
      selected: selected,
      onSelected: (isSelected) {
        if (isSelected) {
          selectedSources.add(value);
        } else {
          selectedSources.remove(value);
        }
        onChanged();
      },
      label: Text(label),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? color : colorScheme.onSurface,
      ),
      backgroundColor: color.withOpacity(0.12),
      selectedColor: color.withOpacity(0.24),
      side: BorderSide(color: color.withOpacity(0.36)),
    );
  }
}

class _RoundedSheetFrame extends StatelessWidget {
  const _RoundedSheetFrame({super.key, required this.child, required this.radius});
  final Widget child;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      // ✅ 내부도 동일 shape + tint 제거로 완전 흰색 유지
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36, height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// Legacy class name for compatibility
class CreateEventBottomSheet extends EventCreateSheet {
  const CreateEventBottomSheet({super.key});
}