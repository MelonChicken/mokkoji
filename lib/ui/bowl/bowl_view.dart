import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/time/app_time.dart';
import '../../data/dao/event_dao.dart';
import '../../data/repository/event_repository.dart';

/// Bowl View - Visual representation of events in a fishbowl metaphor
/// Uses real-time streams for immediate updates when new events are collected
class BowlView extends ConsumerWidget {
  final DateTime? targetDate;
  final BowlViewMode mode;

  const BowlView({
    super.key,
    this.targetDate,
    this.mode = BowlViewMode.today,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(eventRepositoryProvider);
    final effectiveDate = targetDate ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BowlHeader(date: effectiveDate, mode: mode),
            const SizedBox(height: 16),
            Expanded(
              child: _BowlContent(
                repository: repository,
                date: effectiveDate,
                mode: mode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header section of the bowl view
class _BowlHeader extends StatelessWidget {
  final DateTime date;
  final BowlViewMode mode;

  const _BowlHeader({required this.date, required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          Icons.waves,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              _getSubtitle(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Refresh is automatic via streams, but this gives user feedback
          },
          tooltip: '새로고침',
        ),
      ],
    );
  }

  String _getTitle() {
    switch (mode) {
      case BowlViewMode.today:
        return '오늘의 어항';
      case BowlViewMode.week:
        return '이번 주 어항';
      case BowlViewMode.month:
        return '이번 달 어항';
      case BowlViewMode.custom:
        return '어항';
    }
  }

  String _getSubtitle() {
    final kstDate = AppTime.toKst(date.toUtc());
    switch (mode) {
      case BowlViewMode.today:
        return '${kstDate.month}/${kstDate.day} (${_getWeekdayName(kstDate.weekday)})';
      case BowlViewMode.week:
        final weekStart = date.startOfWeek;
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
      case BowlViewMode.month:
        return '${date.year}년 ${date.month}월';
      case BowlViewMode.custom:
        return '${kstDate.month}/${kstDate.day}';
    }
  }

  String _getWeekdayName(int weekday) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[weekday - 1];
  }
}

/// Main content area with real-time event stream
class _BowlContent extends StatelessWidget {
  final EventRepository repository;
  final DateTime date;
  final BowlViewMode mode;

  const _BowlContent({
    required this.repository,
    required this.date,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _getEventStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '데이터를 불러올 수 없습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];
        
        if (events.isEmpty) {
          return _EmptyBowlView(mode: mode);
        }

        return BowlCanvas(events: events);
      },
    );
  }

  Stream<List<EventModel>> _getEventStream() {
    switch (mode) {
      case BowlViewMode.today:
        return repository.watchTodayEvents();
      case BowlViewMode.week:
        return repository.watchEventsForWeek(date.startOfWeek);
      case BowlViewMode.month:
        return repository.watchEventsForMonth(date.startOfMonth);
      case BowlViewMode.custom:
        return repository.watchEventsForLocalDate(date);
    }
  }
}

/// Empty state when no events are found
class _EmptyBowlView extends StatelessWidget {
  final BowlViewMode mode;

  const _EmptyBowlView({required this.mode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.set_meal_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyMessage(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 일정을 모아보세요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (mode) {
      case BowlViewMode.today:
        return '오늘은 조용한 어항이네요';
      case BowlViewMode.week:
        return '이번 주는 한적한 어항이에요';
      case BowlViewMode.month:
        return '이번 달은 여유로운 어항이에요';
      case BowlViewMode.custom:
        return '텅 빈 어항이에요';
    }
  }
}

/// Canvas for drawing events as fish in a bowl
class BowlCanvas extends StatelessWidget {
  final List<EventModel> events;

  const BowlCanvas({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Water effect
          Positioned.fill(
            child: CustomPaint(
              painter: WaterEffectPainter(),
            ),
          ),
          // Events as fish
          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return _EventFish(
              event: event,
              index: index,
              totalEvents: events.length,
            );
          }),
          // Event count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${events.length}마리',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual event represented as a fish
class _EventFish extends StatelessWidget {
  final EventModel event;
  final int index;
  final int totalEvents;

  const _EventFish({
    required this.event,
    required this.index,
    required this.totalEvents,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate position based on event time and index
    final position = _calculatePosition();
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _showEventDetails(context),
        child: Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: _getEventColor(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.schedule,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Offset _calculatePosition() {
    // Simple positioning logic - spread events around the bowl
    const bowlWidth = 300.0;
    const bowlHeight = 200.0;
    
    final angle = (index / totalEvents) * 2 * 3.14159;
    final radius = 60.0 + (index % 3) * 20.0; // Vary depth
    
    final x = bowlWidth / 2 + radius * (angle.cos() * 0.8);
    final y = bowlHeight / 2 + radius * angle.sin() * 0.6;
    
    return Offset(x, y);
  }

  Color _getEventColor() {
    if (event.platformColor != null) {
      try {
        return Color(int.parse(event.platformColor!.replaceFirst('#', '0xFF')));
      } catch (_) {
        // Fall through to default color
      }
    }
    
    // Default colors based on source
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

  void _showEventDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description?.isNotEmpty == true) ...[
              Text(event.description!),
              const SizedBox(height: 8),
            ],
            Text('시작: ${AppTime.fmtHm(AppTime.toKst(event.start))}'),
            if (event.end != null)
              Text('종료: ${AppTime.fmtHm(AppTime.toKst(event.end!))}'),
            if (event.location?.isNotEmpty == true)
              Text('장소: ${event.location}'),
            Text('출처: ${event.source}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for water effects
class WaterEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles for water ripples
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, i * 30.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bowl view modes
enum BowlViewMode { today, week, month, custom }

/// Riverpod providers
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dao = EventDao();
  return EventRepository(dao);
});