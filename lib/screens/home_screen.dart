import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/event_card.dart';
import '../widgets/source_chip.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isIntegratedView = true; // 통합 보기 토글 상태

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('모꼬지',
          style: TextStyle(
            fontWeight: FontWeight.w800
          ),
        ),
        centerTitle: false,
        actions: [
          // 통합 보기 토글
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isIntegratedView = !_isIntegratedView;
              });
            },
            icon: Icon(_isIntegratedView ? Icons.view_list : Icons.filter_list),
            label: Text(_isIntegratedView ? '한데 보기' : '개별 보기'),
            style: TextButton.styleFrom(
              foregroundColor: _isIntegratedView ? cs.primary : cs.onSurface,
            ),
          ),
          // 필터 아이콘
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: ListView(
            children: [
              // 요약 카드 (SummaryCard)
              _buildSummaryCard(context),
              const SizedBox(height: AppTokens.s16),

              // 이벤트 리스트
              ..._buildEventList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: Theme.of(context).brightness == Brightness.light ? AppTokens.e2 : null,
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
                '오늘의 일정',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            '첫 일정 09:30, 총 4건 · 강남역까지 23분',
            style: text.bodyLarge?.copyWith(
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.go('/agenda'),
                icon: const Icon(Icons.view_list),
                label: const Text('통합 상세'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.surface,
                  foregroundColor: cs.onSurface,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              OutlinedButton.icon(
                onPressed: () => _openMap('스타벅스 강남역점'),
                icon: const Icon(Icons.directions),
                label: const Text('길찾기'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.onPrimaryContainer),
                  foregroundColor: cs.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventList(BuildContext context) {
    final events = _getFilteredEvents();
    
    return events.map((event) => Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: EventCard(
        time: event['time'],
        title: Text(event['title']),
        place: event['place'],
        source: event['source'],
        onOpen: () => context.go('/detail/${event['id']}'),
        onNavigate: () => _openMap(event['place']),
      ),
    )).toList();
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    final allEvents = [
      {
        'id': '1',
        'time': '09:30',
        'title': '디자인 킥오프',
        'place': '스타벅스 강남역점',
        'source': SourceType.google,
        'allDay': false,
        'status': 'confirmed',
      },
      {
        'id': '2',
        'time': '12:00',
        'title': '런치 미팅',
        'place': '역삼 메가박스 옆',
        'source': SourceType.kakao,
        'allDay': false,
        'status': 'confirmed',
      },
      {
        'id': '3',
        'time': '14:30',
        'title': '클라이언트 발표',
        'place': '을지로 오피스텔',
        'source': SourceType.naver,
        'allDay': false,
        'status': 'tentative',
      },
      {
        'id': '4',
        'time': '16:20',
        'title': '개발 스프린트 계획',
        'place': '온라인(Zoom)',
        'source': SourceType.naver,
        'allDay': false,
        'status': 'confirmed',
      },
    ];

    // 통합 보기일 때는 모든 이벤트, 아니면 필터링된 이벤트
    if (_isIntegratedView) {
      return allEvents;
    } else {
      // 실제로는 선택된 플랫폼만 필터링
      return allEvents;
    }
  }

  void _openMap(String location) {
    // TODO: 실제 지도 딥링크 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$location 길찾기를 시작합니다'),
        action: SnackBarAction(
          label: '확인',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLg),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 그랩 핸들
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Text(
                  '플랫폼 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: const [
                    SourceChip(type: SourceType.kakao),
                    SourceChip(type: SourceType.naver),
                    SourceChip(type: SourceType.google),
                  ],
                ),
                const SizedBox(height: AppTokens.s24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
