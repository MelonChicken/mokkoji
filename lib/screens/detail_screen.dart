import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../widgets/source_chip.dart';
import '../widgets/avatar_stack.dart';
import '../data/repositories/event_repository.dart';
import '../features/events/data/event_entity.dart';

class DetailScreen extends StatefulWidget {
  final String eventId;
  
  const DetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isNotificationEnabled = false;
  bool _isLoading = true;
  bool _isOffline = false;
  bool _hasError = false;
  EventEntity? _event;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final event = await eventRepository.getById(widget.eventId);
      
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
          _hasError = event == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('일정 내용'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _handleBackNavigation(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError || _event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('일정 내용'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _handleBackNavigation(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '일정을 불러올 수 없습니다',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '일정이 삭제되었거나 접근할 수 없습니다',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadEvent,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // Convert EventEntity to display data
    final eventData = _convertEventToDisplayData(_event!);
    final title = _event!.title;
    
    return Scaffold(
      // AppBar
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
      body: Column(
        children: [
          // 오프라인/에러 배너
          if (_isOffline) _buildOfflineBanner(),
          if (_hasError) _buildErrorBanner(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 요약 카드
                  _buildSummaryCard(eventData, colorScheme, textTheme),
                  const SizedBox(height: 24),
                  
                  // 메타 정보
                  _buildMetaInfo(eventData, colorScheme, textTheme),
                  const SizedBox(height: 24),
                  
                  // 참여자
                  if (eventData['participants'] != null)
                    _buildParticipants(eventData, colorScheme, textTheme),
                  
                  // 메모
                  if (eventData['memo'] != null) ...[
                    const SizedBox(height: 24),
                    _buildMemo(eventData, colorScheme, textTheme),
                  ],
                  
                  // 하단 여백 (버튼 공간)
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // 하단 고정 버튼들
          _buildBottomActions(eventData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '오프라인 – 캐시 데이터를 표시 중 (마지막 동기화 09:30)',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '불러오지 못했어요.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _retry(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> eventData, ColorScheme colorScheme, TextTheme textTheme) {
    final isCanceled = eventData['status'] == 'canceled';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 취소 배지
                      if (isCanceled) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '취소됨',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // 제목
                      Text(
                        eventData['title'],
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // 시간 • 장소 요약
                      Text(
                        _buildSummaryText(eventData),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 우측 플랫폼 배지 + 동기화 상태
                Column(
                  children: [
                    _buildPlatformBadge(eventData['source']),
                    if (eventData['syncStatus'] == 'pending') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
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

  Widget _buildPlatformBadge(SourceType source) {
    Color badgeColor;
    String text;
    
    switch (source) {
      case SourceType.kakao:
        badgeColor = const Color(0xFFFFDC00);
        text = '카카오';
        break;
      case SourceType.naver:
        badgeColor = const Color(0xFF22C55E);
        text = '네이버';
        break;
      case SourceType.google:
        badgeColor = const Color(0xFF3B82F6);
        text = '구글';
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
            color: source == SourceType.kakao ? AppTokens.neutral900 : badgeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(Map<String, dynamic> eventData, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // 일시
        _buildMetaItem(
          icon: Icons.schedule,
          title: '일시',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['date'] ?? '2024-12-31',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              if (eventData['allDay'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                  eventData['time'] ?? '09:30 - 11:00',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        
        // 장소
        if (eventData['place'] != null && eventData['place'].isNotEmpty)
          _buildMetaItem(
            icon: Icons.place,
            title: '장소',
            content: Text(
              eventData['place'],
              style: textTheme.bodyMedium,
            ),
            colorScheme: colorScheme,
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
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
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

  Widget _buildParticipants(Map<String, dynamic> eventData, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참여자',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            AvatarStack(
              avatarUrls: eventData['participants'],
              size: 32,
              maxVisible: 5,
            ),
            const SizedBox(width: 12),
            Text(
              '${eventData['participants'].length}명',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemo(Map<String, dynamic> eventData, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            eventData['memo'],
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> eventData, ColorScheme colorScheme) {
    final hasLocation = eventData['place'] != null && eventData['place'].isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // 길찾기 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLocation ? () => _openNavigation(eventData['place']) : null,
                  icon: const Icon(Icons.directions),
                  label: const Text('길찾기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 알림 받기 버튼
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleNotification(),
                  icon: Icon(_isNotificationEnabled ? Icons.notifications : Icons.notifications_outlined),
                  label: Text(_isNotificationEnabled ? '알림 해제' : '알림 받기'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSummaryText(Map<String, dynamic> eventData) {
    final time = eventData['allDay'] == true ? '종일' : (eventData['time'] ?? '09:30');
    final place = eventData['place'];
    
    if (place != null && place.isNotEmpty) {
      return '$time • $place';
    }
    return time;
  }

  void _handleBackNavigation(BuildContext context) {
    // 이전 화면으로 돌아갈 수 있는지 확인
    if (context.canPop()) {
      context.pop();
    } else {
      // 돌아갈 화면이 없으면 홈으로 이동
      context.go('/');
    }
  }

  void _editEvent() {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정 수정 화면으로 이동')),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
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

  void _openNavigation(String location) {
    // TODO: Implement navigation to maps
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$location 길찾기를 시작합니다')),
    );
  }

  void _toggleNotification() {
    setState(() {
      _isNotificationEnabled = !_isNotificationEnabled;
    });
    
    // TODO: Implement notification toggle logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isNotificationEnabled ? '알림이 설정되었습니다' : '알림이 해제되었습니다'),
      ),
    );
  }
  
  /// EventEntity를 UI용 데이터로 변환
  Map<String, dynamic> _convertEventToDisplayData(EventEntity event) {
    // Parse start date time
    final startDateTime = DateTime.parse(event.startDt);
    final endDateTime = event.endDt != null ? DateTime.parse(event.endDt!) : null;
    
    // Format date
    final dateFormat = DateFormat('yyyy년 MM월 dd일', 'ko');
    final formattedDate = dateFormat.format(startDateTime);
    
    // Format time
    String? formattedTime;
    if (!event.allDay) {
      final timeFormat = DateFormat('HH:mm');
      final startTime = timeFormat.format(startDateTime);
      final endTime = endDateTime != null ? timeFormat.format(endDateTime) : null;
      
      if (endTime != null) {
        formattedTime = '$startTime - $endTime';
      } else {
        formattedTime = startTime;
      }
    }
    
    // Determine source type
    SourceType sourceType;
    switch (event.sourcePlatform.toLowerCase()) {
      case 'kakao':
        sourceType = SourceType.kakao;
        break;
      case 'naver':
        sourceType = SourceType.naver;
        break;
      case 'google':
        sourceType = SourceType.google;
        break;
      default:
        sourceType = SourceType.google; // default fallback
    }
    
    return {
      'title': event.title,
      'time': formattedTime,
      'date': formattedDate,
      'place': event.location,
      'source': sourceType,
      'allDay': event.allDay,
      'status': event.status ?? 'confirmed',
      'syncStatus': 'synced', // assume synced for simplicity
      'participants': event.attendees?.map((a) => a['name'] ?? '').toList(),
      'memo': event.description,
      'link': event.url,
    };
  }

  void _deleteEvent() async {
    try {
      await eventRepository.deleteEvent(widget.eventId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정이 삭제되었습니다')),
        );
        _handleBackNavigation(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${e.toString()}')),
        );
      }
    }
  }

  void _retry() {
    _loadEvent();
  }
}