import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/today_summary_data.dart';
import '../../theme/tokens.dart';
import '../../widgets/source_chip.dart';

class TodaySummaryCard extends StatelessWidget {
  final TodaySummaryData data;
  final VoidCallback onViewDetails;
  final VoidCallback onJumpToNow;
  
  const TodaySummaryCard({
    super.key,
    required this.data,
    required this.onViewDetails,
    required this.onJumpToNow,
  });

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: Theme.of(context).brightness == Brightness.light 
            ? AppTokens.e2 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: cs.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                '오늘의 일정 ${data.count}건',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              if (data.offline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 14,
                        color: cs.onSurface,
                      ),
                      const SizedBox(width: AppTokens.s4),
                      Text(
                        '오프라인',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (data.next != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 일정',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        DateFormat('HH:mm').format(data.next!.startTime),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.next!.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (data.next!.location != null) ...[
                          const SizedBox(height: AppTokens.s4),
                          Text(
                            data.next!.location!,
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  SourceChip(type: _getSourceType(data.next!.sourcePlatform)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppTokens.s16),
          
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('자세히'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.surface,
                    foregroundColor: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onJumpToNow,
                  icon: const Icon(Icons.schedule),
                  label: const Text('지금으로'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.onPrimaryContainer),
                    foregroundColor: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTokens.s8),
          
          Text(
            '마지막 동기화: ${DateFormat('HH:mm').format(data.lastSyncAt)}',
            style: textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}