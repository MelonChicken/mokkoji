import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/time/app_time.dart';
import '../../data/dao/event_dao.dart';
import '../../data/repository/event_repository.dart';

/// Calendar View with real-time event updates
/// Shows monthly calendar with events represented as dots/indicators
class CalendarView extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final CalendarFormat initialFormat;
  final Function(DateTime)? onDaySelected;

  const CalendarView({
    super.key,
    this.initialDate,
    this.initialFormat = CalendarFormat.month,
    this.onDaySelected,
  });

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = _focusedDay;
    _calendarFormat = widget.initialFormat;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(eventRepositoryProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Calendar header with controls
        _CalendarHeader(
          focusedDay: _focusedDay,
          format: _calendarFormat,
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onLeftArrowTap: () {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
          onRightArrowTap: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
        ),
        
        // Calendar body with real-time event data
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: repository.watchEventsForMonth(_focusedDay.startOfMonth),
            builder: (context, snapshot) {
              final events = snapshot.data ?? [];
              final eventsByDay = _groupEventsByDay(events);

              return TableCalendar<EventModel>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                pageJumpingEnabled: true,
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDaySelected?.call(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                eventLoader: (day) => eventsByDay[_dayKey(day)] ?? [],
                
                // Styling
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  canMarkersOverflow: true,
                ),
                
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  titleTextStyle: theme.textTheme.titleLarge!,
                ),
                
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  weekendStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Selected day events
        _SelectedDayEvents(
          selectedDay: _selectedDay,
          repository: repository,
        ),
      ],
    );
  }

  /// Group events by day for efficient lookup
  Map<String, List<EventModel>> _groupEventsByDay(List<EventModel> events) {
    final grouped = <String, List<EventModel>>{};
    
    for (final event in events) {
      final eventDay = AppTime.toKst(event.start);
      final dayKey = _dayKey(DateTime(eventDay.year, eventDay.month, eventDay.day));
      
      grouped.putIfAbsent(dayKey, () => []).add(event);
    }
    
    return grouped;
  }

  /// Generate unique key for a day
  String _dayKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }
}

/// Calendar header with navigation controls
class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final CalendarFormat format;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;

  const _CalendarHeader({
    required this.focusedDay,
    required this.format,
    required this.onFormatChanged,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          
          // Month/Year title
          Expanded(
            child: Center(
              child: Text(
                '${focusedDay.year}년 ${focusedDay.month}월',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Next month button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
          
          const SizedBox(width: 8),
          
          // Format toggle
          PopupMenuButton<CalendarFormat>(
            icon: Icon(
              format == CalendarFormat.month
                  ? Icons.calendar_view_month
                  : format == CalendarFormat.twoWeeks
                      ? Icons.view_week
                      : Icons.view_agenda,
            ),
            onSelected: onFormatChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('월간 보기'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2주 보기'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('주간 보기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Events for selected day with real-time updates
class _SelectedDayEvents extends ConsumerWidget {
  final DateTime selectedDay;
  final EventRepository repository;

  const _SelectedDayEvents({
    required this.selectedDay,
    required this.repository,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.today,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${selectedDay.month}/${selectedDay.day} 일정',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Events list
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: repository.watchEventsForLocalDate(selectedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];
                
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '일정이 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _EventTile(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual event tile in the selected day list
class _EventTile extends StatelessWidget {
  final EventModel event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startKst = AppTime.toKst(event.start);
    final endKst = event.end != null ? AppTime.toKst(event.end!) : null;
    
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _getEventColor(),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        event.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            endKst != null
                ? '${AppTime.fmtHm(startKst)} - ${AppTime.fmtHm(endKst)}'
                : AppTime.fmtHm(startKst),
            style: theme.textTheme.bodySmall,
          ),
          if (event.location?.isNotEmpty == true)
            Text(
              event.location!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: _getSourceIcon(),
      dense: true,
    );
  }

  Color _getEventColor() {
    if (event.platformColor != null) {
      try {
        return Color(int.parse(event.platformColor!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // Fall through to default
      }
    }
    
    switch (event.source) {
      case 'google':
        return Colors.blue;
      case 'naver':
        return Colors.green;
      case 'kakao':
        return Colors.yellow.shade700;
      case 'internal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _getSourceIcon() {
    IconData iconData;
    switch (event.source) {
      case 'google':
        iconData = Icons.cloud;
        break;
      case 'naver':
        iconData = Icons.web;
        break;
      case 'kakao':
        iconData = Icons.chat;
        break;
      case 'internal':
        iconData = Icons.phone_android;
        break;
      default:
        iconData = Icons.event;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: _getEventColor(),
    );
  }
}