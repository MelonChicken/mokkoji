import 'package:flutter/material.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/section_header.dart';
import 'providers/notifications_provider.dart';
import 'widgets/setting_section_card.dart';
import 'widgets/time_dropdown.dart';
import 'widgets/offset_dropdown.dart';
import 'widgets/preview_bubble.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationsProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadSettings();
    _provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (!mounted) return;

    final errorMessage = _provider.errorMessage;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          action: SnackBarAction(
            label: '재시도',
            onPressed: () {
              _provider.clearError();
              _provider.loadSettings();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            if (_provider.isLoading) {
              return const _LoadingView();
            }

            final settings = _provider.settings;
            if (settings == null) {
              return const _ErrorView();
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                const SizedBox(height: 16),
                const SectionHeader(
                  title: '알림 설정',
                  subtitle: '다양한 알림을 설정하여 일정을 놓치지 마세요',
                ),
                const SizedBox(height: 16),
                
                // 일일 브리핑
                SettingSectionCard(
                  leadingColor: const Color(0xFFFF6B6B),
                  leadingIcon: Icons.calendar_today,
                  title: '일일 브리핑',
                  subtitle: '매일 아침 오늘의 일정을 요약해서 알려드려요',
                  enabled: settings.dailyBriefing.enabled,
                  onToggle: (value) => _provider.updateDailyBriefing(enabled: value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('알림 시간'),
                          const Spacer(),
                          SizedBox(
                            width: 120,
                            child: TimeDropdown(
                              value: settings.dailyBriefing.time,

                              onChanged: (time) => _provider.updateDailyBriefing(time: time),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const PreviewBubble(
                        title: '모꼬지',
                        subtitle: '오늘 일정 3개가 있어요. 첫 일정은 오전 10시부터입니다.',
                      ),
                    ],
                  ),
                ),

                // 일정 알림
                SettingSectionCard(
                  leadingColor: const Color(0xFF2BD47D),
                  leadingIcon: Icons.schedule,
                  title: '일정 알림',
                  subtitle: '일정 시작 전에 미리 알려드려요',
                  enabled: settings.eventReminder.enabled,
                  onToggle: (value) => _provider.updateEventReminder(enabled: value),
                  child: Row(
                    children: [
                      const Text('알림 시점'),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: OffsetDropdown(
                          value: settings.eventReminder.offsetMinutes,
                          onChanged: (offset) => _provider.updateEventReminder(offsetMinutes: offset),
                        ),
                      ),
                    ],
                  ),
                ),

                // 모꼬지 초대
                SettingSectionCard(
                  leadingColor: const Color(0xFF8E7DFF),
                  leadingIcon: Icons.group_add,
                  title: '모꼬지 초대',
                  subtitle: '새로운 모꼬지 초대를 받으면 알려드려요',
                  enabled: settings.mokkojiInvite.enabled,
                  onToggle: (value) => _provider.updateMokkojiInvite(enabled: value),
                ),

                // 참석 응답
                SettingSectionCard(
                  leadingColor: const Color(0xFF00C2FF),
                  leadingIcon: Icons.notifications_active,
                  title: '참석 응답',
                  subtitle: '참석자들의 응답 변경을 알려드려요',
                  enabled: settings.attendeeResponse.enabled,
                  onToggle: (value) => _provider.updateAttendeeResponse(enabled: value),
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SectionHeader(
          title: '알림 설정',
          subtitle: '다양한 알림을 설정하여 일정을 놓치지 마세요',
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (index) => _SkeletonCard()),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              '설정을 불러올 수 없습니다',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '네트워크 연결을 확인한 후 다시 시도해주세요',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}