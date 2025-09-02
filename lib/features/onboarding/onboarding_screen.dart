import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../theme/tokens.dart';
import 'widgets/onb_video_hero.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  static const _videoAssetP1 = 'assets/videos/Onboarding_Illustration_Generation_First.mp4';
  static const _videoAssetP2 = 'assets/videos/Onboarding_Illustration_Generation_Second.mp4';
  static const _videoAssetP3 = 'assets/videos/Generating_Onboarding_Illustration_Third.mp4';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 건너뛰기 버튼
                  Align(
                    alignment: Alignment.topRight,
                    child: Semantics(
                      label: '건너뛰기 버튼',
                      child: TextButton(
                        onPressed: _finishOnboarding,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8, right: 8),
                          child: Text('건너뛰기'),
                        ),
                      ),
                    ),
                  ),
                  
                  // Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      children: const [
                        _OnboardingPage(
                          color: Color(0xFFFF6B6B),
                          title: '모든 일정을 한자리에',
                          subtitle: '카카오, 네이버, 구글 캘린더를\n모꼬지에서 한 번에 확인하세요',
                          hero: OnbVideoHero(assetPath: _videoAssetP1, size: 160, playbackSpeed: 1.25),
                        ),
                        _OnboardingPage(
                          color: Color(0xFF2BD47D),
                          title: '똑똑한 일정 브리핑',
                          subtitle: '오늘의 첫 일정부터 총 몇 건까지\n간단하게 요약해드려요',
                          hero: OnbVideoHero(assetPath: _videoAssetP2, size: 160, playbackSpeed: 1.25),
                        ),
                        _OnboardingPage(
                          color: Color(0xFF9B8CFF),
                          title: '함께하는 모임 관리',
                          subtitle: '모꼬지로 친구들과의 약속을\n쉽게 만들고 관리하세요',
                          hero: OnbVideoHero(assetPath: _videoAssetP3, size: 160, playbackSpeed: 1.25),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 페이지 인디케이터
                  _PageIndicator(
                    currentIndex: _currentIndex,
                    pageCount: 3,
                    activeColor: colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // CTA 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Semantics(
                        label: _currentIndex < 2 ? '다음 버튼' : '시작하기 버튼',
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            if (_currentIndex < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else {
                              _finishOnboarding();
                            }
                          },
                          child: Text(_currentIndex < 2 ? '다음' : '시작하기'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    
    if (!mounted) return;
    
    context.go('/home');
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.color,
    required this.title,
    required this.subtitle,
    this.hero,
  });

  final Color color;
  final String title;
  final String subtitle;
  final Widget? hero;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        
        // Hero widget or fallback loader
        hero ??
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        
        const SizedBox(height: 24),
        
        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 설명
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentIndex,
    required this.pageCount,
    required this.activeColor,
  });

  final int currentIndex;
  final int pageCount;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentIndex;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,  // 활성: 6dp 반지름 = 12dp 직경, 비활성: 4dp 반지름 = 8dp 직경
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: isActive 
                ? activeColor 
                : colorScheme.onSurfaceVariant.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}