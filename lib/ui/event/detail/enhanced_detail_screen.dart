import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// TODO: Add url_launcher dependency to use launchUrlString
// import 'package:url_launcher/url_launcher_string.dart';
import '../../../theme/mokkoji_colors.dart';
import '../../widgets/field_card.dart';
import '../widgets/source_chip.dart';
import '../widgets/time_block.dart';
import '../edit/edit_event_sheet.dart';
import 'detail_event_viewmodel.dart';

/// Enhanced detail screen with updated UI and proper CTA organization
class EnhancedDetailScreen extends ConsumerWidget {
  final String eventId;

  const EnhancedDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(detailEventVmProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [
          // Edit button (only show if editable)
          if (stateAsync.valueOrNull?.isEditable == true)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSheet(context, eventId),
              tooltip: '수정',
            ),
          // Overflow menu (only show if has external source or other actions)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              if (stateAsync.valueOrNull?.sourceUrl != null)
                const PopupMenuItem(
                  value: 'openSource',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new),
                      SizedBox(width: 8),
                      Text('원본 보기'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('공유'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('삭제'),
                  ],
                ),
              ),
            ],
            onSelected: (action) => _handleMenuAction(context, ref, action),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const _LoadingContent(),
        error: (error, stackTrace) => _ErrorContent(
          error: error.toString(),
          onRetry: () => ref.read(detailEventVmProvider(eventId).notifier).retry(),
        ),
        data: (state) => _DetailContent(state: state),
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showEditSheet(BuildContext context, String eventId) {
    showEditEventSheet(context, eventId);
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'openSource':
        final state = ref.read(detailEventVmProvider(eventId)).valueOrNull;
        if (state?.sourceUrl != null) {
          // TODO: Implement URL launching when url_launcher is available
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('원본 보기: ${state!.sourceUrl!}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          /*
          try {
            await launchUrlString(state!.sourceUrl!);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('링크를 열 수 없습니다: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          */
        }
        break;
      case 'share':
        try {
          await ref.read(detailEventVmProvider(eventId).notifier).shareEvent();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('일정을 공유했습니다'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('공유 실패: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?\n삭제된 일정은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog

              try {
                await ref.read(detailEventVmProvider(eventId).notifier).deleteEvent();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('일정이 삭제되었습니다'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _handleBackNavigation(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 실패: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

}

/// Detail content with enhanced layout
class _DetailContent extends StatelessWidget {
  final DetailEventState state;

  const _DetailContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          FieldCard(
            child: Text(
              state.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time block with date and range
          TimeBlock(
            dateLine: state.dateLine,
            rangeLine: state.rangeLine,
            tzNote: state.tzNote,
            isCrossDay: state.isCrossDay,
          ),
          const SizedBox(height: 16),

          // Source and sync information
          _SourceAndSyncRow(
            sourceChips: state.sourceChips,
            syncState: state.syncState,
          ),
          const SizedBox(height: 16),

          // Location (if exists)
          if (state.hasLocation) ...[
            FieldCard(
              label: '장소',
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.event.location!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Description/memo (if exists)
          if (state.hasDescription) ...[
            FieldCard(
              label: '메모',
              child: Text(
                state.event.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: null, // ✨ 무제한 줄 표시
                // overflow: TextOverflow.visible, // (기본값이므로 생략)
                // softWrap: true, // (기본 true이므로 생략)
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Feature indicators
          if (state.hasRecurrence || state.hasReminder) ...[
            _FeatureIndicators(
              hasRecurrence: state.hasRecurrence,
              hasReminder: state.hasReminder,
            ),
          ],
        ],
      ),
    );
  }
}

/// Source chips and sync status row
class _SourceAndSyncRow extends StatelessWidget {
  final List<String> sourceChips;
  final String syncState;

  const _SourceAndSyncRow({
    required this.sourceChips,
    required this.syncState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Source chips
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sourceChips
                .map((source) => SourceChip(source: source))
                .toList(),
          ),
        ),

        const SizedBox(width: 12),

        // Sync status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? MokkojiColors.darkGray100
                : MokkojiColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            syncState,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? MokkojiColors.darkGray800
                  : MokkojiColors.gray800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Feature indicators for recurrence and reminders
class _FeatureIndicators extends StatelessWidget {
  final bool hasRecurrence;
  final bool hasReminder;

  const _FeatureIndicators({
    required this.hasRecurrence,
    required this.hasReminder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (hasRecurrence)
          _FeatureChip(
            icon: Icons.repeat,
            label: '반복',
            color: colorScheme.secondary,
          ),
        if (hasReminder)
          _FeatureChip(
            icon: Icons.notifications_outlined,
            label: '알림',
            color: colorScheme.tertiary,
          ),
      ],
    );
  }
}

/// Individual feature chip
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state content
class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error state content with retry button
class _ErrorContent extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorContent({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
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
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}




