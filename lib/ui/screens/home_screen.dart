// Home screen with real-time database-driven event display
// Uses StreamBuilder to reactively show today's events from local database
// Removes all hardcoded event lists in favor of repository-based data

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/local/rrule_expander.dart';
import '../../core/time/app_time.dart';
import '../widgets/sync_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isIntegratedView = true;
  late final Stream<List<EventOccurrence>> _todayEventsStream;

  @override
  void initState() {
    super.initState();
    // Initialize repository and watch today's events
    eventRepository.initialize();
    final today = DateTime.now();
    _todayEventsStream = eventRepository.watchEventsForDay(today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('모꼬지', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isIntegratedView = !_isIntegratedView),
            icon: Icon(_isIntegratedView ? Icons.view_list : Icons.filter_list),
            label: Text(_isIntegratedView ? '한데 보기' : '개별 보기'),
            style: TextButton.styleFrom(
              foregroundColor: _isIntegratedView ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<List<EventOccurrence>>(
                  stream: _todayEventsStream,
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
                          ],
                        ),
                      );
                    }

                    final events = snapshot.data ?? [];
                    return ListView(
                      children: [
                        _buildSummaryCard(context, events),
                        const SizedBox(height: 16),
                        ...events.map((event) => _buildEventCard(context, event)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<EventOccurrence> events) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final firstEventTime = events.isNotEmpty 
        ? AppTime.fmtHm(AppTime.toKst(events.first.startTime))
        : '예정된 일정 없음';
    
    final eventCount = events.length;
    final nextLocation = events.isNotEmpty ? events.first.displayLocation ?? '위치 미정' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: colorScheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                '오늘의 일정',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eventCount > 0 
                ? '첫 일정 $firstEventTime, 총 ${eventCount}건${nextLocation.isNotEmpty ? ' · $nextLocation' : ''}'
                : '오늘 예정된 일정이 없습니다',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.go('/agenda'),
                icon: const Icon(Icons.view_list),
                label: const Text('통합 상세'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
              if (events.isNotEmpty && nextLocation.isNotEmpty) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _openMap(nextLocation),
                  icon: const Icon(Icons.directions),
                  label: const Text('길찾기'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.onPrimaryContainer),
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventOccurrence event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final timeFormat = event.isAllDay ? 'MMM d일 (종일)' : 'HH:mm';
    final timeText = DateFormat(timeFormat).format(event.startTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            DateFormat('HH').format(event.startTime),
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          event.displayTitle,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeText),
            if (event.displayLocation?.isNotEmpty == true)
              Text(
                event.displayLocation!,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'details', child: Text('상세보기')),
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            const PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
          onSelected: (value) {
            switch (value) {
              case 'details':
                context.go('/detail/${event.eventId}');
                break;
              case 'edit':
                // TODO: Implement edit functionality
                break;
              case 'delete':
                _deleteEvent(event.eventId);
                break;
            }
          },
        ),
        onTap: () => context.go('/detail/${event.eventId}'),
      ),
    );
  }

  void _openMap(String location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$location 길찾기를 시작합니다'),
        action: SnackBarAction(label: '확인', onPressed: () {}),
      ),
    );
  }

  void _deleteEvent(String eventId) {
    eventRepository.deleteEvent(eventId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정이 삭제되었습니다')),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '플랫폼 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('필터 옵션은 향후 구현 예정'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Test acceptance criteria:
// 1. No hardcoded event lists - all data comes from database via streams
// 2. StreamBuilder provides reactive UI updates when events change
// 3. Today's events are correctly filtered and displayed in KST
// 4. Event CRUD operations (delete) immediately reflect in UI
// 5. Loading and error states are properly handled