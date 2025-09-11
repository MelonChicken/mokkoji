import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'features/events/data/events_api.dart';
import 'features/events/providers/events_providers.dart';
import 'app/app_lifecycle_sync.dart';
import 'data/repositories/event_repository.dart';
import 'core/time/app_time.dart';
import 'core/time/kst.dart';
import 'db/app_database.dart';
import 'data/migrations/001_fix_utc_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize KST timezone data - REQUIRED for strict UTC/KST contract
  await AppTime.init();
  
  // Initialize KST forced display - ensures consistent timezone regardless of device settings
  KST.init();
  
  // Run UTC migration to fix any corrupted timezone data
  final db = await AppDatabase.instance.database;
  await FixUtcMigration.run(db);
  
  // Initialize database with seed data
  await eventRepository.initialize();
  
  // Provider container 생성
  final container = ProviderContainer(
    overrides: [
      // 개발 환경에서는 Mock API 사용, 프로덕션에서는 HTTP API 사용
      eventsApiProvider.overrideWithValue(
        MockEventsApi(
          // 개발용 Mock 데이터 사용
          mockDelay: const Duration(milliseconds: 300),
        ),
      ),
    ],
  );

  // 앱 생명주기 동기화 설정
  final appLifecycleSync = AppLifecycleSync(
    container: container,
    getCurrentRangeStart: () {
      // 현재 보이는 달력 범위 시작 날짜
      final range = container.read(visibleRangeProvider);
      return range?.startIso ?? 
             DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    },
    getCurrentRangeEnd: () {
      // 현재 보이는 달력 범위 종료 날짜
      final range = container.read(visibleRangeProvider);
      return range?.endIso ?? 
             DateTime.now().add(const Duration(days: 30)).toIso8601String();
    },
  );

  // AppLifecycleSync provider 바인딩
  final finalContainer = ProviderContainer(
    parent: container,
    overrides: [
      appLifecycleSyncProvider.overrideWithValue(appLifecycleSync),
    ],
  );

  appLifecycleSync.start();

  runApp(
    UncontrolledProviderScope(
      container: finalContainer,
      child: const MokkojiApp(),
    ),
  );
}

class MokkojiApp extends StatefulWidget {
  const MokkojiApp({super.key});

  @override
  State<MokkojiApp> createState() => _MokkojiAppState();
}

class _MokkojiAppState extends State<MokkojiApp> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '모꼬지',
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: _mode,
      routerConfig: AppRouter.router,
      locale: const Locale('ko'),
      supportedLocales: const [
        Locale('ko'), Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
