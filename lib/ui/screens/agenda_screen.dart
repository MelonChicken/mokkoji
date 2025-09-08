// Agenda screen with database-driven event display for weekly/monthly views
// Uses StreamBuilder for reactive updates with date range queries and RRULE expansion
// Supports search, filtering, and navigation with real-time data from repository

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/local/rrule_expander.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showWeekView = false;
  
  late Stream<List<EventOccurrence>> _eventsStream;

  @override
  void initState() {
    super.initState();
    eventRepository.initialize();
    _updateEventsStream();
  }

  void _updateEventsStream() {
    if (_showWeekView) {
      // Week view - show Monday to Sunday
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      _eventsStream = eventRepository.watchEventsForRange(startOfWeek, endOfWeek);
    } else {
      // Day view - show selected day
      _eventsStream = eventRepository.watchEventsForDay(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('통합 일정'),
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackNavigation(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(_showWeekView ? Icons.calendar_view_day : Icons.calendar_view_week),
                  onPressed: () {
                    setState(() {
                      _showWeekView = !_showWeekView;
                      _updateEventsStream();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('월간 달력으로 이동 (향후 구현)')),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '일정 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),

                // Date navigation pager
                _buildDatePager(),
                const SizedBox(height: 16),

                // View toggle
                _buildViewToggle(),
                const SizedBox(height: 16),

                // Events list
                Expanded(child: _buildEventsList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정 생성 기능 (향후 구현)')),
          );
        },
        label: const Text('모으기'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDatePager() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(
                  Duration(days: _showWeekView ? 7 : 1),
                );
                _updateEventsStream();
              });
            },
          ),
          Expanded(
            child: InkWell(
              onTap: _showDatePicker,
              child: Center(
                child: Text(
                  _formatSelectedDate(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(
                  Duration(days: _showWeekView ? 7 : 1),
                );
                _updateEventsStream();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              label: Text('일간'),
              icon: Icon(Icons.calendar_view_day),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('주간'),
              icon: Icon(Icons.calendar_view_week),
            ),
          ],
          selected: {_showWeekView},
          onSelectionChanged: (Set<bool> selection) {
            setState(() {
              _showWeekView = selection.first;
              _updateEventsStream();
            });
          },
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    return StreamBuilder<List<EventOccurrence>>(
      stream: _eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('데이터 로드 중 오류가 발생했습니다: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _updateEventsStream();
                    });
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final allEvents = snapshot.data ?? [];
        final filteredEvents = _filterEvents(allEvents);
        
        if (filteredEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                      ? '검색 결과가 없습니다'
                      : '${_formatSelectedDate()}에 일정이 없습니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (_showWeekView) {
          return _buildWeekView(filteredEvents);
        } else {
          return _buildDayView(filteredEvents);
        }
      },
    );
  }

  Widget _buildDayView(List<EventOccurrence> events) {
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildWeekView(List<EventOccurrence> events) {
    // Group events by day
    final eventsByDay = <DateTime, List<EventOccurrence>>{};
    for (final event in events) {
      final dayKey = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      eventsByDay.putIfAbsent(dayKey, () => []).add(event);
    }

    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = startOfWeek.add(Duration(days: index));
        final dayEvents = eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('M월 d일 (E)', 'ko_KR').format(day),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (dayEvents.isEmpty)
                  Text(
                    '일정 없음',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...dayEvents.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildEventCard(event, compact: true),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(EventOccurrence event, {bool compact = false}) {
    final timeFormat = event.isAllDay ? 'MMM d일 (종일)' : 'HH:mm';
    final timeText = DateFormat(timeFormat).format(event.startTime);
    
    return Card(
      child: ListTile(
        dense: compact,
        leading: compact ? null : CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            DateFormat('HH').format(event.startTime),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: _highlightSearchText(event.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeText),
            if (event.displayLocation?.isNotEmpty == true)
              Text(
                event.displayLocation!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (event.isRecurringInstance)
              Text(
                '반복 일정',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: compact ? null : PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'details', child: Text('상세보기')),
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            const PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
          onSelected: (value) => _handleEventAction(value as String, event),
        ),
        onTap: () => context.go('/detail/${event.eventId}'),
      ),
    );
  }

  List<EventOccurrence> _filterEvents(List<EventOccurrence> events) {
    if (_searchQuery.isEmpty) return events;
    
    return events.where((event) {
      final title = event.displayTitle.toLowerCase();
      final location = (event.displayLocation ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || location.contains(query);
    }).toList();
  }

  Widget _highlightSearchText(String text) {
    if (_searchQuery.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = _searchQuery.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    
    if (index == -1) {
      return Text(text);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + _searchQuery.length),
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + _searchQuery.length)),
        ],
      ),
    );
  }

  String _formatSelectedDate() {
    if (_showWeekView) {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('M월 d일').format(startOfWeek)} - ${DateFormat('M월 d일').format(endOfWeek)}';
    } else {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[_selectedDate.weekday - 1];
      return '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 ($weekday)';
    }
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateEventsStream();
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _handleEventAction(String action, EventOccurrence event) {
    switch (action) {
      case 'details':
        context.go('/detail/${event.eventId}');
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 수정 기능 (향후 구현)')),
        );
        break;
      case 'delete':
        _deleteEvent(event.eventId);
        break;
    }
  }

  void _deleteEvent(String eventId) {
    eventRepository.deleteEvent(eventId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정이 삭제되었습니다')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Test acceptance criteria:
// 1. No hardcoded event lists - all data comes from database via streams
// 2. Weekly and daily views both use appropriate date range queries
// 3. RRULE expansion works correctly for recurring events in both views
// 4. Search filtering works in real-time without affecting database queries
// 5. Date navigation updates stream queries correctly for week/day views