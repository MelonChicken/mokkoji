import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../widgets/event_card.dart';
import '../widgets/source_chip.dart';
import '../data/repositories/event_repository.dart';
import '../features/events/data/event_entity.dart';
import '../screens/create_event_bottomsheet.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<SourceType> _selectedPlatforms = {SourceType.kakao, SourceType.naver, SourceType.google};
  List<EventEntity> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final events = await eventRepository.getEventsForRange(
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      );
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('통합 일정'),
              floating: true,
              snap: true,
              expandedHeight: null,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackNavigation(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () {
                    // TODO: Navigate to monthly calendar view
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('월간 달력으로 이동')),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색바
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '일정 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16,
                      vertical: AppTokens.s12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: AppTokens.s16),

                // 날짜 네비게이션 (DatePager)
                _buildDatePager(),
                const SizedBox(height: AppTokens.s16),

                // 필터 바 (Chips)
                _buildFilterBar(),
                const SizedBox(height: AppTokens.s16),

                // 일정 리스트
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showEventCreateSheet(context, onEventCreated: () {
            _loadEvents(); // 일정 추가 후 새로고침
          });
        },
        label: const Text('모으기'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDatePager() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadEvents();
            },
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showDatePicker(),
              child: Center(
                child: Text(
                  _formatSelectedDate(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _showFilterBottomSheet(),
          icon: const Icon(Icons.filter_list),
          label: const Text('필터'),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SourceType.values.map((type) {
                final isSelected = _selectedPlatforms.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(right: AppTokens.s8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPlatforms.add(type);
                        } else {
                          _selectedPlatforms.remove(type);
                        }
                      });
                    },
                    label: SourceChip(type: type),
                    backgroundColor: isSelected ? null : Theme.of(context).colorScheme.surfaceVariant,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredEvents = _getFilteredEvents();
    
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              _searchQuery.isNotEmpty 
                  ? '검색 결과가 없습니다'
                  : '${_formatSelectedDate()}에 일정이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredEvents.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppTokens.s8),
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        final startTime = DateTime.parse(event.startDt);
        final timeStr = DateFormat('HH:mm').format(startTime);
        
        return EventCard(
          time: timeStr,
          title: _highlightSearchText(event.title),
          place: event.location ?? '장소 미정',
          source: _getSourceFromPlatform(event.sourcePlatform),
          onOpen: () => context.go('/detail/${event.id}'),
          onNavigate: () => _openMap(event.location ?? ''),
          onDelete: () => _deleteEvent(event.id),
        );
      },
    );
  }

  SourceType _getSourceFromPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
        return SourceType.google;
      case 'kakao':
        return SourceType.kakao;
      case 'naver':
        return SourceType.naver;
      default:
        return SourceType.google; // internal은 google로 표시
    }
  }

  List<EventEntity> _getFilteredEvents() {
    // 플랫폼 필터링
    final platformFiltered = _events.where((event) {
      final sourceType = _getSourceFromPlatform(event.sourcePlatform);
      return _selectedPlatforms.contains(sourceType);
    }).toList();

    // 검색 필터링
    if (_searchQuery.isNotEmpty) {
      return platformFiltered.where((event) {
        final title = event.title.toLowerCase();
        final location = (event.location ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    }

    return platformFiltered;
  }

  String _formatSelectedDate() {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_selectedDate.weekday - 1];
    return '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 ($weekday)';
  }

  Widget _highlightSearchText(String text) {
    if (_searchQuery.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = _searchQuery.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    
    if (index == -1) {
      return Text(text);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + _searchQuery.length),
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + _searchQuery.length)),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _loadEvents();
    }
  }

  void _openMap(String location) {
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

  Future<void> _deleteEvent(String eventId) async {
    try {
      await eventRepository.deleteEvent(eventId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // 삭제 후 이벤트 목록 새로고침
        _loadEvents();
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

  void _handleBackNavigation(BuildContext context) {
    // 이전 화면으로 돌아갈 수 있는지 확인
    if (context.canPop()) {
      context.pop();
    } else {
      // 돌아갈 화면이 없으면 홈으로 이동
      context.go('/');
    }
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
                  '필터 옵션',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                SwitchListTile(
                  title: const Text('중복 제거'),
                  subtitle: const Text('같은 일정이 여러 플랫폼에 있을 때 하나만 표시'),
                  value: true,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('종일 일정 숨기기'),
                  subtitle: const Text('종일 일정을 목록에서 제외'),
                  value: false,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('참석자 포함'),
                  subtitle: const Text('참석자가 있는 일정만 표시'),
                  value: false,
                  onChanged: (value) {},
                ),
                SwitchListTile(
                  title: const Text('장소 있는 일정만'),
                  subtitle: const Text('장소 정보가 있는 일정만 표시'),
                  value: false,
                  onChanged: (value) {},
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
