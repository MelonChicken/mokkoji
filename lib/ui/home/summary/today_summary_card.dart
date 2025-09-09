import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/today_summary_data.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/source_chip.dart';
import '../../../core/time/app_time.dart';

/// 오버플로우 방지가 적용된 오늘 요약 카드
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: !isDark ? AppTokens.e2 : null,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
          // 헤더 행
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isDark ? cs.onSurface : cs.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  '오늘의 일정 ${data.count}건',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? cs.onSurface : cs.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (data.offline) ...[
                const SizedBox(width: AppTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.8),
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
            ],
          ),
          
          // 다음 일정 정보 (있을 때)
          if (data.next != null) ...[
            const SizedBox(height: AppTokens.s12),
            Container(
              padding: const EdgeInsets.all(AppTokens.s12),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시각 (고정폭)
                  SizedBox(
                    width: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '다음 일정',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          DateFormat('HH:mm', 'ko_KR').format(AppTime.toKst(data.next!.startTime)),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppTokens.s12),
                  
                  // 제목 및 위치 (확장 가능)
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
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppTokens.s8),
                  
                  // 소스 칩
                  SourceChip(type: _getSourceType(data.next!.sourcePlatform)),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppTokens.s16),
          
          // 버튼 행 (자동 줄바꿈)
          Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s8,
            children: [
              FilledButton(
                onPressed: onViewDetails,
                child: const Text('자세히'),
              ),
              OutlinedButton(
                onPressed: onJumpToNow,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? cs.onSurface : cs.onPrimaryContainer,
                  ),
                  foregroundColor: isDark ? cs.onSurface : cs.onPrimaryContainer,
                ),
                child: const Text('지금으로'),
              ),
            ],
          ),
          
          const SizedBox(height: AppTokens.s8),
          
          // 동기화 정보
          Text(
            '마지막 동기화: ${DateFormat('HH:mm', 'ko_KR').format(AppTime.toKst(data.lastSyncAt))}',
            style: textTheme.labelSmall?.copyWith(
              color: (isDark ? cs.onSurface : cs.onPrimaryContainer).withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
        ),
      ),
    );
  }
}