import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/events/data/events_dao.dart';
import '../../data/repositories/today_summary_repository.dart';
import '../../data/models/today_summary_data.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_chip.dart';
import '../../core/time/app_time.dart';
import 'summary/sticky_summary_header.dart';
import 'summary/today_summary_card.dart';
import 'summary/today_summary_layout.dart';
import 'timeline/day_timeline_view.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TodaySummaryRepository _summaryRepository;
  late final ScrollController _timelineController;
  final GlobalKey<_DayTimelineViewWrapperState> _timelineKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _summaryRepository = TodaySummaryRepository(dao: EventsDao());
    _timelineController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToNowInitial();
    });
  }

  @override
  void dispose() {
    _summaryRepository.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _jumpToNowInitial() {
    _timelineKey.currentState?.jumpToInclude(AppTime.nowKst());
  }

  void _jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '모꼬지',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: StickySummaryHeader(
                minHeight: 92,
                maxHeightCap: 220,
                childBuilder: (context, maxWidth) {
                  return Container(
                    padding: const EdgeInsets.all(AppTokens.s16),
                    child: StreamBuilder<TodaySummaryData>(
                      stream: _summaryRepository.stream,
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? TodaySummaryData(
                          count: 0,
                          next: null,
                          lastSyncAt: AppTime.nowKst(),
                          offline: true,
                        );
                        
                        return TodaySummaryCard(
                          data: data,
                          onViewDetails: () => context.go('/agenda'),
                          onJumpToNow: _jumpToNow,
                        );
                      },
                    ),
                  );
                },
                heightMeasurer: (context, maxWidth) {
                  return TodaySummaryLayout.computeHeight(
                    context,
                    hasNext: _summaryRepository.currentData?.next != null,
                    showSyncChip: _summaryRepository.currentData?.offline ?? false,
                  );
                },
              ),
            ),
            
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
                  child: _DayTimelineViewWrapper(
                    key: _timelineKey,
                    controller: _timelineController,
                    summaryRepository: _summaryRepository,
                    onEventTap: (eventId) => context.go('/detail/$eventId'),
                    onEventLongPress: _showEventQuickActions,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventQuickActions(String eventId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: AppTokens.s16),
                
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('편집'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/detail/$eventId');
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.directions),
                  title: const Text('길찾기'),
                  onTap: () {
                    Navigator.pop(context);
                    _openMap('일정 위치');
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  title: Text('삭제', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEvent(eventId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMap(String location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$location 길찾기를 시작합니다'),
        action: SnackBarAction(
          label: '확인',
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final dao = EventsDao();
      await dao.softDelete(eventId, DateTime.now().toIso8601String());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 삭제 실패: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s20),
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
                const SizedBox(height: AppTokens.s16),
                Text(
                  '플랫폼 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                const Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: [
                    SourceChip(type: SourceType.kakao),
                    SourceChip(type: SourceType.naver),
                    SourceChip(type: SourceType.google),
                  ],
                ),
                const SizedBox(height: AppTokens.s24),
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

class _DayTimelineViewWrapper extends StatefulWidget {
  final ScrollController controller;
  final TodaySummaryRepository summaryRepository;
  final Function(String) onEventTap;
  final Function(String) onEventLongPress;

  const _DayTimelineViewWrapper({
    super.key,
    required this.controller,
    required this.summaryRepository,
    required this.onEventTap,
    required this.onEventLongPress,
  });

  @override
  State<_DayTimelineViewWrapper> createState() => _DayTimelineViewWrapperState();
}

class _DayTimelineViewWrapperState extends State<_DayTimelineViewWrapper> {
  final GlobalKey<DayTimelineViewState> _timelineKey = GlobalKey<DayTimelineViewState>();

  void jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimelineEvent>>(
      future: widget.summaryRepository.getTodayEvents().then((events) =>
        events.map(TimelineEvent.fromEntity).toList()),
      builder: (context, snapshot) {
        final events = snapshot.data ?? <TimelineEvent>[];
        
        return DayTimelineView(
          key: _timelineKey,
          date: DateTime.now(),
          events: events,
          controller: widget.controller,
          onEventTap: widget.onEventTap,
          onEventLongPress: widget.onEventLongPress,
        );
      },
    );
  }
}