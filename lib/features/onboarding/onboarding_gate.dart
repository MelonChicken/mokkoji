import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_screen.dart';

/// 온보딩 표시 여부를 결정하는 게이트 위젯
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _shouldShowOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      
      if (onboardingDone) {
        setState(() => _shouldShowOnboarding = false);
        return;
      }

      // 간단한 로직으로 시작 - 실제 구현에서는 이벤트 캐시나 연동 상태를 확인
      // TODO: 실제 이벤트 캐시 확인 및 캘린더 연동 상태 확인
      // final hasEvents = await _checkHasEvents();
      // final hasConnections = await _checkHasConnections();
      // final shouldShow = !(hasEvents || hasConnections);
      
      // 지금은 onboarding_done 플래그만 확인
      setState(() => _shouldShowOnboarding = true);
    } catch (e) {
      // 에러 발생 시 홈화면으로
      setState(() => _shouldShowOnboarding = false);
    }
  }

  // TODO: 실제 이벤트 캐시 확인 로직
  // Future<bool> _checkHasEvents() async {
  //   // SQLite: SELECT COUNT(*) FROM events WHERE ... > 0
  //   return false;
  // }

  // TODO: 실제 캘린더 연동 상태 확인 로직  
  // Future<bool> _checkHasConnections() async {
  //   // GET /api/integrations/sync-status
  //   return false;
  // }

  @override
  Widget build(BuildContext context) {
    if (_shouldShowOnboarding == null) {
      // 로딩 중
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 온보딩이 필요하면 온보딩 화면으로, 아니면 홈으로 리다이렉트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowOnboarding!) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}