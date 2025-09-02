import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MokkojiApp());
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
