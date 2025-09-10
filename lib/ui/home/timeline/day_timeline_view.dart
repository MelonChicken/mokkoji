import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/events/data/event_entity.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/source_chip.dart';
import '../../../core/time/app_time.dart';

class TimelineEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final bool allDay;
  final String? location;
  final String sourcePlatform;
  final Color? color;

  const TimelineEvent({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.allDay,
    this.location,
    required this.sourcePlatform,
    this.color,
  });

  factory TimelineEvent.fromEntity(EventEntity entity) {
    return TimelineEvent(
      id: entity.id,
      title: entity.title,
      startTime: DateTime.parse(entity.startDt),
      endTime: entity.endDt != null ? DateTime.parse(entity.endDt!) : null,
      allDay: entity.allDay,
      location: entity.location,
      sourcePlatform: entity.sourcePlatform,
      color: entity.platformColor != null 
          ? Color(int.parse(entity.platformColor!.replaceFirst('#', '0xFF')))
          : null,
    );
  }

  int get durationMinutes {
    if (endTime == null) return 60; // Default 1 hour
    final duration = endTime!.difference(startTime).inMinutes;
    return duration < 1 ? 1 : duration; // 최소 1분 보장
  }

  int get startMinuteFromMidnight {
    // KST 기준으로 변환 후 자정부터의 분 계산 (타임라인 배치용)
    final kstTime = AppTime.toKst(startTime);
    return AppTime.minutesFromMidnightKst(kstTime);
  }
}

class DayTimelineView extends StatefulWidget {
  final DateTime date;
  final List<TimelineEvent> events;
  final Function(String eventId)? onEventTap;
  final Function(String eventId)? onEventLongPress;
  final ScrollController? controller;
  final double reservedTop;
  final double reservedBottom;

  const DayTimelineView({
    super.key,
    required this.date,
    required this.events,
    this.onEventTap,
    this.onEventLongPress,
    this.controller,
    this.reservedTop = 0.0,
    this.reservedBottom = 0.0,
  });

  @override
  State<DayTimelineView> createState() => DayTimelineViewState();
}

class DayTimelineViewState extends State<DayTimelineView> {
  late ScrollController _scrollController;
  static const double kHourRowHeight = 64.0; // 시간당 행 높이 통일
  static const double _timeColumnWidth = 60.0;
  DateTime? _pendingTarget;
  int _retry = 0;
  
  // 타임라인 콘텐츠 총 높이 (0:00-24:00, 24시간)
  double get _contentHeight => 24 * kHourRowHeight;
  
  // 뷰포트에서 실사용 가능한 높이(상/하단 예약 영역 제외)
  double get _effectiveViewport {
    if (!_scrollController.hasClients) return 0;
    final raw = _scrollController.position.viewportDimension;
    final eff = raw - widget.reservedTop - widget.reservedBottom;
    return eff.clamp(0, raw);
  }
  
  // 하단 스페이서(trailing spacer) 높이 계산
  double get _trailingSpacer => widget.reservedBottom + 32.0; // 추가 여백

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Enhanced: Support both pending targets and initial now jump
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingTarget != null) {
        jumpToInclude(_pendingTarget!, animate: false);
        _pendingTarget = null;
        _retry = 0;
      }
    });
  }

  @override
  void didUpdateWidget(DayTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle controller changes and retry pending jumps
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null && _scrollController != widget.controller) {
        _scrollController.dispose();
      }
      _scrollController = widget.controller ?? ScrollController();
    }
    
    // Retry any pending operations after widget rebuild
    if (_pendingTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpToInclude(_pendingTarget!, animate: false);
      });
    }
  }

  void jumpToInclude(DateTime target, {double anchor = 0.35, bool animate = false}) {
    final tryJump = () {
      if (!mounted) return false;
      if (!_scrollController.hasClients) {
        // Store target for retry when controller is ready
        _pendingTarget = target;
        return false;
      }
      
      // KST 기준으로 변환 후 분 계산 (AppTime 유틸 사용)
      final kstTarget = AppTime.toKst(target);
      final minuteFromStart = AppTime.minutesFromMidnightKst(kstTarget);
      final totalMinutes = 24 * 60;
      final pos = (minuteFromStart / totalMinutes) * _contentHeight;
      final viewport = _effectiveViewport; // 이미 reservedTop/Bottom 반영된 값
      final desired = pos - (anchor * viewport);
      
      // 최대 스크롤 가능한 거리 계산 (트레일링 스페이서 포함)
      final maxScrollExtent = (_contentHeight + _trailingSpacer) - viewport;
      final clampedOffset = desired.clamp(0.0, maxScrollExtent < 0 ? 0.0 : maxScrollExtent);
      
      if (animate) {
        _scrollController.animateTo(
          clampedOffset, 
          duration: const Duration(milliseconds: 250), 
          curve: Curves.easeOut
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
      return true;
    };

    if (!tryJump() && _retry < 3) {
      _pendingTarget = target;
      _retry++;
      WidgetsBinding.instance.addPostFrameCallback((_) => jumpToInclude(_pendingTarget!, anchor: anchor, animate: animate));
    }
  }

  void jumpToNow() {
    final now = AppTime.nowKst();
    final widgetDateKst = AppTime.toKst(widget.date);
    if (AppTime.isSameDayKst(now, widgetDateKst)) {
      jumpToInclude(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = AppTime.nowKst();
    final widgetDateKst = AppTime.toKst(widget.date);
    final isToday = AppTime.isSameDayKst(now, widgetDateKst);
    
    final timedEvents = widget.events.where((e) => !e.allDay).toList();
    final allDayEvents = widget.events.where((e) => e.allDay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allDayEvents.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '하루 종일',
                  style: textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: allDayEvents.map((event) => _buildAllDayEventChip(
                    context,
                    event,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
        
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 24시간 그리드(0:00-24:00, 25개 격자선 포함)
                SizedBox(
                  height: _contentHeight,
                  child: Stack(
                    children: [
                      _buildTimeGrid(context),
                      if (isToday) _buildCurrentTimeLine(context),
                      _buildEvents(context, timedEvents),
                    ],
                  ),
                ),
                // 하단 트레일링 스페이서 - UI 요소에 가려지지 않도록
                _buildTrailingSpacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllDayEventChip(BuildContext context, TimelineEvent event) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Material(
      color: event.color?.withOpacity(0.1) ?? cs.primaryContainer,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: InkWell(
        onTap: () => widget.onEventTap?.call(event.id),
        onLongPress: () => widget.onEventLongPress?.call(event.id),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: event.color ?? cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              SourceChip(type: _getSourceType(event.sourcePlatform)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      children: [
        SizedBox(
          width: _timeColumnWidth,
          child: Column(
            children: List.generate(25, (hour) { // 0시~24시 (25개)
              return SizedBox(
                height: hour == 24 ? 0 : kHourRowHeight, // 24:00 라인은 높이 0
                child: hour == 24 ? const SizedBox.shrink() : Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm', 'ko_KR').format(
                        DateTime(2024, 1, 1, hour),
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        
        Expanded(
          child: Stack(
            children: [
              // 사용자 정의 페인터로 0:00-24:00 그리드 라인 그리기
              CustomPaint(
                size: Size(double.infinity, _contentHeight),
                painter: _TimeGridPainter(cs.outlineVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTimeLine(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = AppTime.nowKst();
    final minutesFromMidnight = AppTime.minutesFromMidnightKst(now);
    final pixelsPerMinute = kHourRowHeight / 60.0;
    final topPosition = minutesFromMidnight * pixelsPerMinute;

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: _timeColumnWidth,
            height: 20,
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s6,
                vertical: AppTokens.s2,
              ),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Text(
                AppTime.fmtHm(now),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: cs.error,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvents(BuildContext context, List<TimelineEvent> events) {
    final overlappingGroups = _groupOverlappingEvents(events);
    
    return Positioned(
      left: _timeColumnWidth,
      top: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        children: overlappingGroups.expand((group) {
          return _buildEventGroup(context, group);
        }).toList(),
      ),
    );
  }

  List<List<TimelineEvent>> _groupOverlappingEvents(List<TimelineEvent> events) {
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final groups = <List<TimelineEvent>>[];
    
    for (final event in sortedEvents) {
      bool addedToGroup = false;
      
      for (final group in groups) {
        final lastEvent = group.last;
        final lastEventEnd = lastEvent.endTime ?? 
            lastEvent.startTime.add(Duration(minutes: lastEvent.durationMinutes));
        
        if (event.startTime.isBefore(lastEventEnd)) {
          group.add(event);
          addedToGroup = true;
          break;
        }
      }
      
      if (!addedToGroup) {
        groups.add([event]);
      }
    }
    
    return groups;
  }

  List<Widget> _buildEventGroup(BuildContext context, List<TimelineEvent> group) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pixelsPerMinute = kHourRowHeight / 60.0;
    
    return group.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      final columnCount = group.length > 3 ? 3 : group.length;
      final columnWidth = 1.0 / columnCount;
      final eventColor = event.color ?? cs.primary;
      
      if (index >= 2 && group.length > 3) {
        final remainingCount = group.length - 2;
        return Positioned(
          left: 2 * columnWidth * MediaQuery.of(context).size.width - _timeColumnWidth,
          top: event.startMinuteFromMidnight * pixelsPerMinute,
          width: columnWidth * (MediaQuery.of(context).size.width - _timeColumnWidth) - 8,
          height: 40,
          child: Container(
            margin: const EdgeInsets.only(right: 4, bottom: 2),
            padding: const EdgeInsets.all(AppTokens.s8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(color: cs.outline.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        );
      }
      
      if (index >= 2) return const SizedBox.shrink();
      
      return Positioned(
        left: index * columnWidth * (MediaQuery.of(context).size.width - _timeColumnWidth),
        top: event.startMinuteFromMidnight * pixelsPerMinute,
        width: columnWidth * (MediaQuery.of(context).size.width - _timeColumnWidth) - 8,
        height: (event.durationMinutes * pixelsPerMinute).clamp(40.0, double.infinity),
        child: Material(
          color: eventColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: InkWell(
            onTap: () => widget.onEventTap?.call(event.id),
            onLongPress: () => widget.onEventLongPress?.call(event.id),
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            child: Container(
              margin: const EdgeInsets.only(right: 4, bottom: 2),
              padding: const EdgeInsets.all(AppTokens.s8),
              decoration: BoxDecoration(
                border: Border.all(color: eventColor.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: eventColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: AppTokens.s4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: AppTokens.s2),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTrailingSpacer() {
    return Container(
      height: _trailingSpacer,
      width: double.infinity,
      decoration: kDebugMode 
          ? BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3), 
                width: 1.0,
              ),
            )
          : null,
      child: kDebugMode 
          ? Center(
              child: Text(
                'Trailing Spacer\n${_trailingSpacer.toStringAsFixed(1)}px',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }

  SourceType _getSourceType(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
        return SourceType.google;
      case 'kakao':
        return SourceType.kakao;
      case 'naver':
        return SourceType.naver;
      default:
        return SourceType.google;
    }
  }
}

/// CustomPainter for drawing time grid lines from 0:00 to 24:00 (25 lines total)
class _TimeGridPainter extends CustomPainter {
  final Color lineColor;
  
  const _TimeGridPainter(this.lineColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    
    final thickPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;
    
    // Draw 25 horizontal lines (0:00, 1:00, 2:00, ..., 24:00)
    for (int h = 0; h <= 24; h++) {
      final y = h * DayTimelineViewState.kHourRowHeight;
      final usePaint = (h == 0 || h == 24) ? thickPaint : paint;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        usePaint,
      );
      
      // Draw 30-minute half-lines (except for the last hour)
      if (h < 24) {
        final halfY = y + (DayTimelineViewState.kHourRowHeight / 2);
        final halfPaint = Paint()
          ..color = lineColor.withOpacity(0.3)
          ..strokeWidth = 0.5;
        
        canvas.drawLine(
          Offset(0, halfY),
          Offset(size.width, halfY),
          halfPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}