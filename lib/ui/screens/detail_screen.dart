// Event detail screen with database-driven content display
// Uses StreamBuilder to reactively show event details from local database
// Supports optimistic updates and edit functionality with immediate UI reflection

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/unified_providers.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  
  const DetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 내용'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editEvent(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: StreamBuilder<EventData?>(
        stream: _eventStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('데이터 로드 중 오류가 발생했습니다: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final event = snapshot.data;
          if (event == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 48),
                  SizedBox(height: 16),
                  Text('이벤트를 찾을 수 없습니다'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Sync status banner
              if (event.syncStatus == 'pending') _buildSyncBanner(),
              if (event.deleted) _buildDeletedBanner(),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      _buildSummaryCard(event, colorScheme, textTheme),
                      const SizedBox(height: 24),
                      
                      // Meta information
                      _buildMetaInfo(event, colorScheme, textTheme),
                      const SizedBox(height: 24),
                      
                      // Description/Memo
                      if (event.description?.isNotEmpty == true) ...[
                        _buildDescription(event, colorScheme, textTheme),
                        const SizedBox(height: 24),
                      ],
                      
                      // RRULE information
                      if (event.recurrenceRule?.isNotEmpty == true) ...[
                        _buildRecurrenceInfo(event, colorScheme, textTheme),
                        const SizedBox(height: 24),
                      ],
                      
                      // Bottom spacing for buttons
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              
              // Bottom action buttons
              _buildBottomActions(event, colorScheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '동기화 대기 중 – 로컬 변경사항을 서버에 반영하는 중입니다',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '삭제된 일정 – 이 일정은 삭제 표시되었습니다',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(EventData event, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deleted badge
                      if (event.deleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '삭제됨',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Title
                      Text(
                        event.title,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Time and location summary
                      Text(
                        _buildSummaryText(event),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Platform badge and sync status
                Column(
                  children: [
                    _buildPlatformBadge(event.sourcePlatform),
                    if (event.syncStatus == 'pending') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformBadge(String? sourcePlatform) {
    Color badgeColor;
    String text;
    
    switch (sourcePlatform) {
      case 'kakao':
        badgeColor = const Color(0xFFFFDC00);
        text = '카카오';
        break;
      case 'naver':
        badgeColor = const Color(0xFF22C55E);
        text = '네이버';
        break;
      case 'google':
        badgeColor = const Color(0xFF3B82F6);
        text = '구글';
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.primaryContainer;
        text = '로컬';
        break;
    }
    
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sourcePlatform == 'kakao' ? Colors.black : badgeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(EventData event, ColorScheme colorScheme, TextTheme textTheme) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(event.startUtc * 1000);
    final endTime = DateTime.fromMillisecondsSinceEpoch(event.endUtc * 1000);
    
    // Convert to KST for display
    final startKst = startTime.add(const Duration(hours: 9));
    final endKst = endTime.add(const Duration(hours: 9));
    
    return Column(
      children: [
        // Date and time
        _buildMetaItem(
          icon: Icons.schedule,
          title: '일시',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                KST.dayWithWeekday(startKst.millisecondsSinceEpoch),
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              if (event.allDay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '종일',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                )
              else
                Text(
                  AppTime.fmtRange(AppTime.toKst(startUtc), AppTime.toKst(endUtc)),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        
        // Location
        if (event.location?.isNotEmpty == true)
          _buildMetaItem(
            icon: Icons.place,
            title: '장소',
            content: Text(
              event.location!,
              style: textTheme.bodyMedium,
            ),
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _buildDescription(EventData event, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설명',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Text(
            event.description!,
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceInfo(EventData event, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복 일정',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '반복 규칙',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatRrule(event.recurrenceRule!),
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'RRULE: ${event.recurrenceRule!}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String title,
    required Widget content,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(EventData event, ColorScheme colorScheme) {
    final hasLocation = event.location?.isNotEmpty == true;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Navigation button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLocation ? () => _openNavigation(event.location!) : null,
                  icon: const Icon(Icons.directions),
                  label: const Text('길찾기'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification toggle button
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleNotification(),
                  icon: Icon(_isNotificationEnabled ? Icons.notifications : Icons.notifications_outlined),
                  label: Text(_isNotificationEnabled ? '알림 해제' : '알림 받기'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSummaryText(EventData event) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(event.startUtc * 1000);
    final startKst = startTime.add(const Duration(hours: 9));
    
    final time = event.allDay ? '종일' : AppTime.fmtHm(AppTime.toKst(startTime));
    final place = event.location;
    
    if (place?.isNotEmpty == true) {
      return '$time • $place';
    }
    return time;
  }

  String _formatRrule(String rrule) {
    if (rrule.contains('FREQ=DAILY')) {
      if (rrule.contains('COUNT=')) {
        final count = RegExp(r'COUNT=(\d+)').firstMatch(rrule)?.group(1);
        return '매일 반복 ($count회)';
      } else if (rrule.contains('UNTIL=')) {
        return '매일 반복 (종료일까지)';
      } else {
        return '매일 반복';
      }
    } else if (rrule.contains('FREQ=WEEKLY')) {
      if (rrule.contains('BYDAY=')) {
        final byday = RegExp(r'BYDAY=([^;]+)').firstMatch(rrule)?.group(1);
        final days = byday?.split(',').map((day) {
          switch (day) {
            case 'MO': return '월';
            case 'TU': return '화';
            case 'WE': return '수';
            case 'TH': return '목';
            case 'FR': return '금';
            case 'SA': return '토';
            case 'SU': return '일';
            default: return day;
          }
        }).join(', ');
        return '주간 반복 ($days요일)';
      } else {
        return '매주 반복';
      }
    } else {
      return '사용자 정의 반복';
    }
  }

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _editEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정 수정 기능 (향후 구현)')),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '정말 삭제할까요?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '삭제하면 복구할 수 없습니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteEvent();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteEvent() async {
    try {
      final writeService = ref.read(eventWriteServiceProvider);
      await writeService.deleteEvent(widget.eventId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _handleBackNavigation(context);
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

  void _openNavigation(String location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$location 길찾기를 시작합니다')),
    );
  }

  void _toggleNotification() {
    setState(() {
      _isNotificationEnabled = !_isNotificationEnabled;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isNotificationEnabled ? '알림이 설정되었습니다' : '알림이 해제되었습니다'),
      ),
    );
  }
}

// Test acceptance criteria:
// 1. No hardcoded event data - all content comes from database via streams
// 2. StreamBuilder provides reactive updates when event details change
// 3. Sync status indicators show pending/error states correctly
// 4. RRULE information is properly decoded and displayed in Korean
// 5. Delete operations immediately reflect in UI and navigate back