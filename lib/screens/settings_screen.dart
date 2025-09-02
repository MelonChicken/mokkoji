import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/section_header.dart';
import '../widgets/source_chip.dart';
import '../features/settings/notifications/notifications_screen.dart';

enum CalendarBrand { kakao, naver, google }

Color brandColor(CalendarBrand b) => switch (b) {
  CalendarBrand.kakao => const Color(0xFFFEE500),
  CalendarBrand.naver => const Color(0xFF03C75A),
  CalendarBrand.google => const Color(0xFF4285F4),
};

class BrandCalendarIcon extends StatelessWidget {
  const BrandCalendarIcon({super.key, required this.brand, this.size = 48});
  final CalendarBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = brandColor(brand);
    final r = size * 0.22;
    return Semantics(
      label: '${_brandName(brand)} 캘린더 아이콘',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          // Base card
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(r),
              border: Border.all(color: cs.outlineVariant),
            ),
          ),
          // Top bar
          Positioned(
            left: 0, right: 0, top: 0,
            height: size * 0.28,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
              ),
            ),
          ),
          // Binder rings
          Positioned(
            top: size * 0.22,
            left: size * 0.18,
            child: _ring(size),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.18,
            child: _ring(size),
          ),
          // Day grid (6 dots)
          Positioned(
            top: size * 0.40,
            left: 0,
            right: 0,
            child: Center(
              child: Wrap(
                spacing: size * 0.10,
                runSpacing: size * 0.10,
                children: List.generate(6, (_) => _dot(size, cs.onSurfaceVariant.withOpacity(0.7))),
              ),
            ),
          ),
          // Accent dot
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: _dot(size, color),
          ),
        ]),
      ),
    );
  }

  Widget _ring(double size) => Container(
        width: size * 0.12,
        height: size * 0.12,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );

  Widget _dot(double size, Color c) => Container(
        width: size * 0.10,
        height: size * 0.10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
  
  String _brandName(CalendarBrand brand) => switch (brand) {
    CalendarBrand.kakao => '카카오',
    CalendarBrand.naver => '네이버',
    CalendarBrand.google => '구글',
  };
}

class CalendarProviderTile extends StatelessWidget {
  const CalendarProviderTile({
    super.key,
    required this.brand,
    required this.title,
    required this.connected,
    required this.subtitle,
    required this.onChanged,
    this.lastSyncedText,
  });
  
  final CalendarBrand brand;
  final String title;
  final bool connected;
  final String subtitle;
  final String? lastSyncedText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 4),
                BrandCalendarIcon(brand: brand, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (connected)
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: brandColor(brand).withOpacity(0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '연결됨',
                                  style: TextStyle(
                                    color: brand == CalendarBrand.kakao 
                                        ? AppTokens.neutral900 
                                        : brandColor(brand),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: '$title 동기화 스위치, ${connected ? "켜짐" : "꺼짐"}',
                  child: Switch(
                    value: connected,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: cs.outlineVariant,
            ),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Text(
                    '마지막 동기화',
                    style: textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    lastSyncedText ?? '—',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<CalendarBrand, bool> _calendarConnections = {
    CalendarBrand.kakao: true,
    CalendarBrand.naver: true,
    CalendarBrand.google: false,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SectionHeader(
              title: '알림',
              subtitle: '일정과 리마인더 설정을 관리하세요',
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTokens.primary500.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppTokens.primary500,
                    size: 20,
                  ),
                ),
                title: const Text('알림 설정'),
                subtitle: const Text('일정 알림, 브리핑 등을 설정하세요'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            const SectionHeader(
              title: '연결된 캘린더',
              subtitle: '계정을 연결해 일정을 한데로 모아요',
            ),
            
            // 카카오 캘린더
            CalendarProviderTile(
              brand: CalendarBrand.kakao,
              title: '카카오 캘린더',
              connected: _calendarConnections[CalendarBrand.kakao]!,
              subtitle: '모든 일정을 동기화합니다',
              lastSyncedText: '방금 전',
              onChanged: (value) {
                setState(() {
                  _calendarConnections[CalendarBrand.kakao] = value;
                });
                _handleCalendarToggle(CalendarBrand.kakao, value);
              },
            ),
            
            // 네이버 캘린더
            CalendarProviderTile(
              brand: CalendarBrand.naver,
              title: '네이버 캘린더',
              connected: _calendarConnections[CalendarBrand.naver]!,
              subtitle: '모든 일정을 동기화합니다',
              lastSyncedText: '5분 전',
              onChanged: (value) {
                setState(() {
                  _calendarConnections[CalendarBrand.naver] = value;
                });
                _handleCalendarToggle(CalendarBrand.naver, value);
              },
            ),
            
            // 구글 캘린더
            CalendarProviderTile(
              brand: CalendarBrand.google,
              title: '구글 캘린더',
              connected: _calendarConnections[CalendarBrand.google]!,
              subtitle: '연결하여 일정을 동기화하세요',
              lastSyncedText: _calendarConnections[CalendarBrand.google]! ? '1시간 전' : null,
              onChanged: (value) {
                setState(() {
                  _calendarConnections[CalendarBrand.google] = value;
                });
                _handleCalendarToggle(CalendarBrand.google, value);
              },
            ),
            
            const SizedBox(height: 32),
            
            const SectionHeader(
              title: '정보',
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('앱 버전'),
                    subtitle: const Text('0.1.0'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('도움말'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('개인정보 처리방침'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCalendarToggle(CalendarBrand brand, bool connected) {
    final brandName = switch (brand) {
      CalendarBrand.kakao => '카카오',
      CalendarBrand.naver => '네이버',
      CalendarBrand.google => '구글',
    };
    
    // TODO: Implement actual calendar connection logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected 
              ? '$brandName 캘린더가 연결되었습니다'
              : '$brandName 캘린더 연결이 해제되었습니다'
        ),
        action: connected ? null : SnackBarAction(
          label: '다시 연결',
          onPressed: () {
            setState(() {
              _calendarConnections[brand] = true;
            });
          },
        ),
      ),
    );
  }
}
