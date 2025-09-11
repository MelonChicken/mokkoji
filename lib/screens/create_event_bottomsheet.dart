import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/time/kst.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/time/app_time.dart';
import '../data/providers/unified_providers.dart';
import '../data/services/event_write_service.dart';
import '../ui/event/new_event_sheet_v2.dart';

Future<void> showEventCreateSheet(BuildContext context, {VoidCallback? onEventCreated}) {
  return showNewEventSheetV2(context);
}

// Helper widget for labeled input fields
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  
  const _LabeledField({required this.label, required this.child});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class EventCreateSheet extends ConsumerStatefulWidget {
  final VoidCallback? onEventCreated;
  
  const EventCreateSheet({super.key, this.onEventCreated});

  @override
  ConsumerState<EventCreateSheet> createState() => _EventCreateSheetState();
}

class _EventCreateSheetState extends ConsumerState<EventCreateSheet> {
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
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 12,
        bottom: bottomInset + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              Text('새 일정 만들기', style: textTheme.titleLarge),
              const SizedBox(height: 12),

              // 제목 (필수)
              _LabeledField(
                label: '제목 *',
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '일정 제목을 입력하세요',
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목은 필수입니다';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),

              // 날짜 및 시간
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: '날짜 *',
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _selectedDate == null
                              ? ''
                              : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                        ),
                        decoration: const InputDecoration(
                          hintText: '연도-월-일',
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: '시간 *',
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _selectedTime == null ? '' : _formatTime(_selectedTime!),
                        ),
                        decoration: const InputDecoration(
                          hintText: '-- --:--',
                          prefixIcon: Icon(Icons.access_time),
                        ),
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
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 장소
              _LabeledField(
                label: '장소',
                child: TextField(
                  controller: _placeController,
                  decoration: const InputDecoration(
                    hintText: '장소를 입력하세요',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 참여자
              _LabeledField(
                label: '참여자',
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _attendeeController,
                        decoration: const InputDecoration(
                          hintText: '참여자 이름 또는 연락처'
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
              Divider(color: colorScheme.outline.withOpacity(0.5)), // Block boundary
              const SizedBox(height: 12),

              // 캘린더 연동
              Text('캘린더 연동', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('카카오'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSources.add('kakao');
                        } else {
                          _selectedSources.remove('kakao');
                        }
                      });
                    },
                    selected: _selectedSources.contains('kakao'),
                  ),
                  FilterChip(
                    label: const Text('네이버'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSources.add('naver');
                        } else {
                          _selectedSources.remove('naver');
                        }
                      });
                    },
                    selected: _selectedSources.contains('naver'),
                  ),
                  FilterChip(
                    label: const Text('구글'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSources.add('google');
                        } else {
                          _selectedSources.remove('google');
                        }
                      });
                    },
                    selected: _selectedSources.contains('google'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CTA 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isFormValid
                      ? () async {
                          if (!_formKey.currentState!.validate()) return;
                          
                          // Create KST datetime from user input
                          final kstDateTime = tz.TZDateTime(
                            AppTime.kst,
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );
                          
                          // Convert to UTC for storage
                          final utcStartTime = AppTime.fromKstToUtc(kstDateTime);
                          final utcEndTime = utcStartTime.add(const Duration(hours: 1));
                          
                          // Selected platform for integration
                          String selectedPlatform = 'internal';
                          if (_selectedSources.isNotEmpty) {
                            selectedPlatform = _selectedSources.first;
                          }
                          
                          if (kDebugMode) {
                            print('🎯 KST input: ${kstDateTime.toIso8601String()}');
                            print('🎯 UTC storage: ${utcStartTime.toIso8601String()}');
                            print('🎯 Platform: $selectedPlatform');
                          }
                          
                          // Create event using unified write service
                          final writeService = ref.read(eventWriteServiceProvider);
                          final draft = EventDraft(
                            title: _titleController.text.trim(),
                            description: _placeController.text.trim().isNotEmpty 
                                ? _placeController.text.trim() 
                                : null,
                            startTime: utcStartTime, // UTC for storage
                            endTime: utcEndTime,     // UTC for storage
                            location: _placeController.text.trim().isNotEmpty 
                                ? _placeController.text.trim() 
                                : null,
                            sourcePlatform: selectedPlatform,
                          );
                          
                          try {
                            // Create event through unified write service
                            await writeService.addEvent(draft);
                            
                            // Show success feedback
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('일정이 성공적으로 추가되었습니다'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.of(context).pop();
                              
                              // 콜백 호출하여 홈 화면 새로고침
                              widget.onEventCreated?.call();
                            }
                          } catch (e) {
                            // Show error feedback
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('일정 추가 실패: ${e.toString()}'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    return '$period $hour:$minute';
  }
}


// Legacy class name for compatibility
class CreateEventBottomSheet extends EventCreateSheet {
  const CreateEventBottomSheet({super.key});
}