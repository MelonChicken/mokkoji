import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/events/data/event_entity.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/source_chip.dart';

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
    return endTime!.difference(startTime).inMinutes;
  }

  int get startMinuteFromMidnight {
    return startTime.hour * 60 + startTime.minute;
  }
}

class DayTimelineView extends StatefulWidget {
  final DateTime date;
  final List<TimelineEvent> events;
  final Function(String eventId)? onEventTap;
  final Function(String eventId)? onEventLongPress;
  final ScrollController? controller;

  const DayTimelineView({
    super.key,
    required this.date,
    required this.events,
    this.onEventTap,
    this.onEventLongPress,
    this.controller,
  });

  @override
  State<DayTimelineView> createState() => DayTimelineViewState();
}

class DayTimelineViewState extends State<DayTimelineView> {
  late ScrollController _scrollController;
  static const double _hourHeight = 80.0;
  static const double _timeColumnWidth = 60.0;

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

  void jumpToInclude(DateTime target, {double anchor = 0.3}) {
    final minutesFromMidnight = target.hour * 60 + target.minute;
    final pixelsPerMinute = _hourHeight / 60.0;
    final targetOffset = minutesFromMidnight * pixelsPerMinute;
    
    if (_scrollController.hasClients) {
      final viewportHeight = _scrollController.position.viewportDimension;
      final adjustedOffset = (targetOffset - viewportHeight * anchor).clamp(
        0.0, 
        _scrollController.position.maxScrollExtent,
      );
      
      _scrollController.animateTo(
        adjustedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void jumpToNow() {
    final now = DateTime.now();
    if (_isSameDay(now, widget.date)) {
      jumpToInclude(now);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isToday = _isSameDay(DateTime.now(), widget.date);
    
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
            child: SizedBox(
              height: 24 * _hourHeight,
              child: Stack(
                children: [
                  _buildTimeGrid(context),
                  if (isToday) _buildCurrentTimeLine(context),
                  _buildEvents(context, timedEvents),
                ],
              ),
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
            children: List.generate(24, (hour) {
              return SizedBox(
                height: _hourHeight,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm').format(
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
              Column(
                children: List.generate(24, (hour) {
                  return Container(
                    height: _hourHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: cs.outlineVariant,
                          width: hour == 0 ? 1.0 : 0.5,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: _hourHeight / 2,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 0.5,
                            color: cs.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTimeLine(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final minutesFromMidnight = now.hour * 60 + now.minute;
    final pixelsPerMinute = _hourHeight / 60.0;
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
                DateFormat('HH:mm').format(now),
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
    final pixelsPerMinute = _hourHeight / 60.0;
    
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