import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/section_header.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('모꼬지')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Column(
            children: [
              const SectionHeader(
                title: '참가 중인 모꼬지',
                subtitle: '2개',
              ),
              const SizedBox(height: AppTokens.s8),
              Expanded(
                child: ListView.separated(
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s12),
                  itemBuilder: (context, index) {
                    final groupData = _getGroupData(index);
                    return Container(
                      padding: const EdgeInsets.all(AppTokens.s16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        boxShadow: Theme.of(context).brightness == Brightness.light ? AppTokens.e1 : null,
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: const Color(0xFF273244), width: 1)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: groupData['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppTokens.s12),
                              Expanded(
                                child: Text(
                                  groupData['name'],
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s8),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                groupData['schedule'],
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: AppTokens.s16),
                              Icon(
                                Icons.place,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                groupData['location'],
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.s12),
                          Row(
                            children: [
                              AvatarStack(
                                avatarUrls: groupData['members'],
                                size: 28,
                              ),
                              const Spacer(),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'yes', label: Text('예')),
                                  ButtonSegment(value: 'no', label: Text('아니오')),
                                  ButtonSegment(value: 'maybe', label: Text('미정')),
                                ],
                                selected: {groupData['response']},
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                                    return states.contains(WidgetState.selected) 
                                        ? cs.primary 
                                        : cs.surface;
                                  }),
                                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                                    return states.contains(WidgetState.selected) 
                                        ? cs.onPrimary 
                                        : cs.onSurface;
                                  }),
                                ),
                                onSelectionChanged: (selection) {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getGroupData(int index) {
    final groupsData = [
      {
        'name': '주간 스터디 모임',
        'schedule': '수 19:30',
        'location': '강남',
        'color': AppTokens.primary500,
        'members': ['김철수', '이영희', '박민수', '최지연'],
        'response': 'yes',
      },
      {
        'name': '월례 독서 모임',
        'schedule': '매월 둘째 토 14:00',
        'location': '홍대',
        'color': AppTokens.mint400,
        'members': ['정우진', '송하나', '이민준'],
        'response': 'maybe',
      },
    ];
    return groupsData[index];
  }
}
