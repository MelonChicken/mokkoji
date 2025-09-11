import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/time/app_time.dart';
import '../../data/dao/event_dao.dart';
import '../../data/repository/event_repository.dart';
import '../../services/collector/collect_service.dart';

/// Debug Panel for real-time diagnostics and event collection testing
/// Provides insights into collection stats, recent events, and system status
class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  bool _isCollecting = false;
  CollectionResult? _lastResult;
  String _statusMessage = 'Ready';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(eventRepositoryProvider);
    final collectService = ref.watch(collectServiceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DebugHeader(),
            const SizedBox(height: 16),
            
            // Collection controls
            _CollectionControls(
              isCollecting: _isCollecting,
              onCollect: () => _collectEvents(collectService),
              lastResult: _lastResult,
              statusMessage: _statusMessage,
            ),
            
            const SizedBox(height: 16),
            
            // Recent events display
            Expanded(
              child: _RecentEventsView(repository: repository),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _collectEvents(CollectService service) async {
    if (_isCollecting) return;
    
    setState(() {
      _isCollecting = true;
      _statusMessage = 'Collecting events...';
    });

    try {
      final result = await service.collectNewEvents();
      setState(() {
        _lastResult = result;
        _statusMessage = 'Collection completed';
      });
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collected ${result.totalFetched} events'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Collection failed: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCollecting = false);
    }
  }
}

/// Debug panel header with title and status
class _DebugHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          Icons.bug_report,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '디버그 패널',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '이벤트 수집 및 진단',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        Icon(
          Icons.developer_mode,
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

/// Collection controls and status display
class _CollectionControls extends StatelessWidget {
  final bool isCollecting;
  final VoidCallback onCollect;
  final CollectionResult? lastResult;
  final String statusMessage;

  const _CollectionControls({
    required this.isCollecting,
    required this.onCollect,
    required this.lastResult,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: isCollecting ? null : onCollect,
                icon: isCollecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(isCollecting ? '수집 중...' : '새 일정 모으기'),
              ),
              const SizedBox(width: 16),
              Text(
                statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          if (lastResult != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Last collection results
            Text(
              '최근 수집 결과',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                _StatChip(
                  label: '가져옴',
                  value: '${lastResult!.totalFetched}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '추가',
                  value: '${lastResult!.stats.inserted}',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '업데이트',
                  value: '${lastResult!.stats.updated}',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '건너뜀',
                  value: '${lastResult!.stats.skipped}',
                  color: Colors.grey,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              '소스: ${lastResult!.sources.join(", ")}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Statistics chip widget
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent events view with real-time updates
class _RecentEventsView extends StatelessWidget {
  final EventRepository repository;

  const _RecentEventsView({required this.repository});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '최근 5분 생성',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                iconSize: 18,
                onPressed: () {
                  // Refresh is automatic via streams
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: FutureBuilder<List<EventModel>>(
              future: repository.getRecentEvents(5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final events = snapshot.data ?? [];
                
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '최근 생성된 이벤트가 없습니다',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${events.length}건',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: ListView.separated(
                        itemCount: events.take(10).length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _RecentEventTile(event: event);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual recent event tile
class _RecentEventTile extends StatelessWidget {
  final EventModel event;

  const _RecentEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startKst = AppTime.toKst(event.start);
    
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _getSourceColor(),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        event.title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${AppTime.fmtHm(startKst)} • ${event.source}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: Icon(
          Icons.content_copy,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Color _getSourceColor() {
    switch (event.source) {
      case 'google':
        return Colors.blue;
      case 'naver':
        return Colors.green;
      case 'kakao':
        return Colors.yellow.shade700;
      case 'internal':
        return Colors.purple;
      case 'mock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _copyToClipboard(BuildContext context) {
    final text = '${event.title} @ ${event.start}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('클립보드에 복사됨'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Riverpod providers
final collectServiceProvider = Provider<CollectService>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return CollectServiceFactory.create(repository);
});

/// Debug panel overlay widget for development
class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _showDebug = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Debug toggle button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'debug_toggle',
            onPressed: () {
              setState(() => _showDebug = !_showDebug);
            },
            backgroundColor: Colors.red,
            child: Icon(
              _showDebug ? Icons.close : Icons.bug_report,
              color: Colors.white,
            ),
          ),
        ),
        
        // Debug panel overlay
        if (_showDebug)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  height: 400,
                  child: const DebugPanel(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}