import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/agenda_screen.dart';
import '../screens/group_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/detail_screen.dart';
import '../widgets/navigation_shell.dart';
import '../features/onboarding/onboarding_gate.dart';
import '../features/onboarding/onboarding_screen.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      // 온보딩 게이트 - 루트 경로에서 온보딩 여부 판단
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const OnboardingGate(),
        ),
      ),
      // 온보딩 화면
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const OnboardingScreen(),
        ),
      ),
      // 메인 앱 네비게이션 (홈, 그룹, 설정)
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/group',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const GroupScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: '/detail/:eventId',
        builder: (context, state) => DetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
    ],
  );
}
