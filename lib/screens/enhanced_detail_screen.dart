import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/mokkoji_colors.dart';
import '../ui/event/detail/detail_event_viewmodel.dart';
import '../ui/event/detail_edit_controller.dart';
import '../ui/event/detail_edit_form.dart';
import '../ui/widgets/field_card.dart';
import '../ui/event/widgets/source_chip.dart';
import '../ui/event/widgets/time_block.dart';

/// Enhanced detail screen with in-place editing capability
class EnhancedDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EnhancedDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EnhancedDetailScreen> createState() => _EnhancedDetailScreenState();
}

class _EnhancedDetailScreenState extends ConsumerState<EnhancedDetailScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final detailStateAsync = ref.watch(detailEventVmProvider(widget.eventId));
    final editState = _isEditMode ? ref.watch(detailEditControllerProvider(widget.eventId)) : null;
    final editController = _isEditMode ? ref.read(detailEditControllerProvider(widget.eventId).notifier) : null;

    return PopScope(
      canPop: !_isEditMode || editState?.isDirty != true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation(context, editState, editController);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? '일정 편집' : '일정 상세'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _handleBackNavigation(context, editState, editController),
          ),
          actions: _buildAppBarActions(context, editState, editController),
        ),
        body: detailStateAsync.when(
        data: (detailState) => _buildBody(context, detailState, editState, editController),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorContent(
          error: error.toString(),
          onRetry: () => ref.read(detailEventVmProvider(widget.eventId).notifier).retry(),
        ),
        ),
        // Bottom actions bar (delete button in edit mode, save/cancel in app bar)
        bottomNavigationBar: _isEditMode ? _buildBottomActionBar(context, detailStateAsync) : null,
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, DetailEditState? editState, DetailEditController? editController) {
    if (!_isEditMode) {
      // View mode - show edit button
      return [
        IconButton(
          onPressed: () {
            setState(() {
              _isEditMode = true;
            });
          },
          icon: const Icon(Icons.edit),
          tooltip: '편집',
        ),
        PopupMenuButton<String>(
          itemBuilder: (context) => [
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
          onSelected: (action) => _handleMenuAction(context, action),
        ),
      ];
    } else {
      // Edit mode - show cancel/save buttons
      return [
        // Cancel button
        TextButton(
          onPressed: () => _handleCancel(context, editState, editController),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        // Save button
        FilledButton(
          onPressed: editState?.formIsValid == true && !editState!.isSaving
              ? () => _handleSave(context, editController!)
              : null,
          child: editState?.isSaving == true
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ];
    }
  }

  Widget _buildBody(BuildContext context, DetailEventState detailState, DetailEditState? editState, DetailEditController? editController) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isEditMode
                  ? _buildEditMode(context, editState, editController)
                  : _buildViewMode(context, detailState),
            ),
          ),
        ),
        // Add bottom spacing to prevent overlap with bottomNavigationBar
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildViewMode(BuildContext context, DetailEventState state) {
    return Column(
      key: const ValueKey('view_mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        if (state.sourceChips.isNotEmpty) ...[
          _SourceAndSyncRow(
            sourceChips: state.sourceChips,
            syncState: state.syncState,
          ),
          const SizedBox(height: 16),
        ],

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
              maxLines: null,
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
    );
  }

  Widget _buildEditMode(BuildContext context, DetailEditState? editState, DetailEditController? editController) {
    if (editState == null || editController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      key: const ValueKey('edit_mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // DetailEditForm now handles its own scrolling
        DetailEditForm(eventId: widget.eventId),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, AsyncValue<DetailEventState> detailStateAsync) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
        child: OutlinedButton.icon(
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text('일정 삭제'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  void _handleBackNavigation(BuildContext context, DetailEditState? editState, DetailEditController? editController) {
    if (_isEditMode) {
      // In edit mode - check for unsaved changes
      if (editState?.isDirty == true) {
        _showDiscardDialog(context).then((shouldDiscard) {
          if (shouldDiscard) {
            editController?.cancel();
            setState(() => _isEditMode = false);
          }
        });
      } else {
        // No changes, just exit edit mode
        editController?.cancel();
        setState(() => _isEditMode = false);
      }
    } else {
      // In view mode - navigate back to previous screen
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _handleCancel(BuildContext context, DetailEditState? editState, DetailEditController? editController) async {
    if (editState?.isDirty == true) {
      final shouldDiscard = await _showDiscardDialog(context);
      if (!shouldDiscard) return;
    }

    editController?.cancel();
    setState(() {
      _isEditMode = false;
    });
  }

  void _handleSave(BuildContext context, DetailEditController editController) async {
    await editController.save(context);

    // If save was successful (no error), exit edit mode
    final currentState = ref.read(detailEditControllerProvider(widget.eventId));
    if (!currentState.hasConflict && currentState.error == null) {
      setState(() {
        _isEditMode = false;
      });
    }
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'share':
        try {
          await ref.read(detailEventVmProvider(widget.eventId).notifier).shareEvent();
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
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close detail screen

              try {
                // Delete and get the deleted event for undo
                final deletedEvent = await ref.read(detailEventVmProvider(widget.eventId).notifier).deleteEvent();

                if (context.mounted && deletedEvent != null) {
                  // Show undo snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${deletedEvent.title} 삭제됨'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: '되돌리기',
                        onPressed: () async {
                          try {
                            await ref.read(detailEventVmProvider(widget.eventId).notifier).restoreEvent();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${deletedEvent.title} 복구됨'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('복구 실패: $e'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
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

  Future<bool> _showDiscardDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항 버리기'),
        content: const Text('저장하지 않은 변경사항이 있습니다.\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('버리기'),
          ),
        ],
      ),
    ) ?? false;
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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