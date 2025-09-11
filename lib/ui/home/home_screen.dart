import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/today_summary_data.dart';
import '../../data/providers/unified_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_chip.dart';
import '../../core/time/app_time.dart';
import '../../core/time/date_key.dart';
import 'summary/fixed_height_header.dart';
import 'summary/today_summary_card.dart';
import 'summary/today_summary_layout.dart';
import 'timeline/day_timeline_view.dart';
import '../common/measure_size.dart';
import '../../devtools/consistency_debug_panel.dart';
import '../../devtools/dev_config.dart';
import 'package:flutter/foundation.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _timelineController;
  final GlobalKey<_DayTimelineViewWrapperState> _timelineKey = GlobalKey();
  double _navBarH = 0, _fabCardH = 0;
  
  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToNowInitial();
    });
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  void _jumpToNowInitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timelineKey.currentState?.jumpToInclude(AppTime.nowKst());
    });
  }

  void _jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }

  double _computeSummaryHeight(BuildContext context, {required bool hasNext}) {
    // 화면/텍스트 스케일에 따른 대략값. 필요하면 정교화 가능.
    final scale = MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.3);
    final base = 32.0 /*헤더*/ + 16.0 /*gap*/ + (hasNext ? 88.0 : 0.0) + 16.0 /*gap*/ + 52.0 /*버튼 행*/ + 32.0 /*패딩 합산*/ + 24.0 /*동기화 라인*/;
    return (base * scale).clamp(120.0, 280.0);
  }

  // 통일된 reservedBottom 계산 (extendBody: true 환경)
  double _computeReservedBottom(BuildContext context) {
    final mq = MediaQuery.of(context);
    final systemBottom = mq.padding.bottom;              // 제스처/홈 인디케이터
    
    // 기본적인 bottomNavigationBar 높이 (대략 56-80dp) + FAB 높이 (대략 56dp)
    // 실제 위젯이 있으면 MeasureSize로 측정, 없으면 기본값 사용
    final estimatedNavBarH = _navBarH > 0 ? _navBarH : 72.0;  // BottomAppBar 기본 높이
    final estimatedFabH = _fabCardH > 0 ? _fabCardH : 56.0;   // FAB 기본 높이
    
    return systemBottom + estimatedNavBarH + estimatedFabH + 16.0;   // 실측 기반 + 여백
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true, // 유지 가능
      // bottomNavigationBar: MeasureSize(
      //   onChange: (s) => setState(() => _navBarH = s.height),
      //   child: const MyBottomNavBar(), // 네가 쓰는 하단바 위젯
      // ),
      // floatingActionButton: MeasureSize(
      //   onChange: (s) => setState(() => _fabCardH = s.height),
      //   child: const MyFabCardButton(), // "모으기" 카드 형태 FAB
      // ),
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
        bottom: false, // extendBody: true이므로 하단 중복 패딩 방지
        child: Stack(
          children: [
            Consumer(
              builder: (context, ref, child) {
                // Use unified providers with stable DateKey
                final todayKey = ref.watch(todayKeyProvider);
                final summaryAsync = ref.watch(todaySummaryProvider(todayKey));
                final occurrencesAsync = ref.watch(occurrencesForDayProvider(todayKey));
                
                // Debug logging
                if (kDebugMode) {
                  occurrencesAsync.whenData((occs) => 
                    debugPrint('UI got $todayKey count=${occs.length}'));
                }
            
                return summaryAsync.when(
                  loading: () => _buildLoadingSkeleton(context),
                  error: (error, stack) => _buildErrorState(context, error, stack),
              data: (summaryData) {
                final hasNext = summaryData.next != null;
                final headerHeight = _computeSummaryHeight(context, hasNext: hasNext);
                
                // 상단 요약 카드 높이(이미 계산한 headerHeight 사용)
                final double reservedTop = headerHeight + 8; // 카드와 타임라인 사이 간격 포함
                
                // 통일된 하단 예약 영역 계산
                final reservedBottom = _computeReservedBottom(context);
            
                return CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: FixedHeightHeader(
                        height: headerHeight,
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(AppTokens.s16),
                          child: TodaySummaryCard(
                            data: summaryData,
                            onViewDetails: () => context.go('/agenda'),
                            onJumpToNow: _jumpToNow,
                          ),
                        ),
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 300,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
                          child: occurrencesAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTokens.s16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timeline,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                    ),
                                    const SizedBox(height: AppTokens.s12),
                                    Text(
                                      '타임라인 로드 실패',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.s8),
                                    Text(
                                      error.toString(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            data: (occurrences) {
                              // Trigger initial jump when data loads
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _jumpToNowInitial();
                              });
                              
                              return _DayTimelineViewWrapper(
                                key: _timelineKey,
                                controller: _timelineController,
                                occurrences: occurrences,
                                onEventTap: (eventId) => context.go('/detail/$eventId'),
                                onEventLongPress: _showEventQuickActions,
                                reservedTop: reservedTop,
                                reservedBottom: reservedBottom,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
              },
            ),
            
            // Debug panel (opt-in only)
            if (kEnableDevTools && kDebugMode) const ConsistencyDebugPanel(),
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
      final writeService = ref.read(eventWriteServiceProvider);
      await writeService.deleteEvent(eventId);
      
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

  Widget _buildLoadingSkeleton(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            margin: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 400,
            margin: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: const Center(
              child: Text('타임라인 로딩 중...'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, StackTrace? stack) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              '일정을 불러올 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s16),
            ElevatedButton(
              onPressed: () {
                // Force refresh by rebuilding the widget
                setState(() {});
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTimelineViewWrapper extends StatefulWidget {
  final ScrollController controller;
  final List<EventOccurrence> occurrences;
  final Function(String) onEventTap;
  final Function(String) onEventLongPress;
  final double reservedTop;
  final double reservedBottom;

  const _DayTimelineViewWrapper({
    super.key,
    required this.controller,
    required this.occurrences,
    required this.onEventTap,
    required this.onEventLongPress,
    required this.reservedTop,
    required this.reservedBottom,
  });

  @override
  State<_DayTimelineViewWrapper> createState() => _DayTimelineViewWrapperState();
}

class _DayTimelineViewWrapperState extends State<_DayTimelineViewWrapper> {
  final GlobalKey<DayTimelineViewState> _timelineKey = GlobalKey<DayTimelineViewState>();

  void jumpToNow() {
    _timelineKey.currentState?.jumpToNow();
  }
  
  void jumpToInclude(DateTime target, {double anchor = 0.3}) {
    _timelineKey.currentState?.jumpToInclude(target, anchor: anchor);
  }

  @override
  Widget build(BuildContext context) {
    return DayTimelineView(
      key: _timelineKey,
      date: DateTime.now(),
      controller: widget.controller,
      onEventTap: widget.onEventTap,
      onEventLongPress: widget.onEventLongPress,
      reservedTop: widget.reservedTop,
      reservedBottom: widget.reservedBottom,
    );
  }
}