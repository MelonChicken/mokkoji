import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/time/kst.dart';
import '../../events/providers/events_providers.dart';
import '../../events/providers/events_watch_provider.dart';
import '../../events/providers/debounced_sync_provider.dart';
import '../../events/data/event_entity.dart';

class DayEventsConsumer extends ConsumerWidget {
  const DayEventsConsumer({
    super.key,
    required this.startIso,
    required this.endIso,
    this.platforms,
    this.useOfflineMode = false,
  });

  final String startIso; // 00:00 포함
  final String endIso; // 다음날 00:00 (미만)
  final List<String>? platforms;
  final bool useOfflineMode; // true면 동기화 없이 로컬만

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (
      startIso: startIso,
      endIso: endIso,
      platforms: platforms,
    );

    // 범위 변경 시 자동 디바운스된 동기화 트리거 (오프라인 모드가 아닐 때만)
    if (!useOfflineMode) {
      ref.watch(autoRangeSyncProvider(args));
    }

    // 실시간 이벤트 구독 (온라인/오프라인 모드에 따라 다른 provider 사용)
    final asyncEvents = useOfflineMode
        ? ref.watch(localEventsWatchProvider(args))
        : ref.watch(eventsWatchProvider(args));

    return asyncEvents.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('불러오지 못했어요: $e'),
            const SizedBox(height: 16),
            if (!useOfflineMode)
              ElevatedButton(
                onPressed: () {
                  if (useOfflineMode) {
                    ref.invalidate(localEventsWatchProvider(args));
                  } else {
                    ref.invalidate(eventsWatchProvider(args));
                  }
                },
                child: const Text('다시 시도'),
              ),
          ],
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  useOfflineMode ? '저장된 일정이 없어요' : '오늘 일정이 없어요',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _EventTile(event: events[i]),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateTime.parse(event.startDt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목과 플랫폼
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (event.platformColor != null)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(event.platformColor!),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 시간 정보
            Row(
              children: [
                Icon(
                  event.allDay ? Icons.event : Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  event.allDay
                      ? '하루 종일'
                      : '${KST.hmFromIso(event.startDt)}${event.endDt != null ? ' - ${KST.hmFromIso(event.endDt!)}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            // 위치
            if (event.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // 설명 (있을 경우)
            if (event.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // iCalendar 정보 (디버그용)
            if (event.icalUid != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'UID: ${event.icalUid!.length > 20 ? event.icalUid!.substring(0, 20) + '...' : event.icalUid!}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.grey;
    } catch (_) {
      return Colors.grey;
    }
  }
}