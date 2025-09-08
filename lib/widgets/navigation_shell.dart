import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/create_event_bottomsheet.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/home') return 0;
    if (location.startsWith('/group')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/group');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: '모꼬지',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
      floatingActionButton: _calculateSelectedIndex(context) == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _showCreateEventBottomSheet(context);
              },
              label: const Text('모으기'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateEventBottomSheet(BuildContext context) {
    showEventCreateSheet(context, onEventCreated: () {
      // 일정이 추가되면 홈 화면 새로고침
      // 현재 홈 화면이면 새로고침 트리거
      if (_calculateSelectedIndex(context) == 0) {
        // 간단하게 페이지를 다시 로드하는 방법
        context.go('/home');
      }
    });
  }
}