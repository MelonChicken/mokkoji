import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

TextTheme _textTheme(BuildContext context, {required bool dark}) {
  final base = GoogleFonts.notoSansKrTextTheme(Theme.of(context).textTheme);
  // Apply tabular numbers to Body
  return base.copyWith(
    headlineSmall: const TextStyle(fontSize: 28, height: 36/28, fontWeight: FontWeight.w600),
    titleMedium: const TextStyle(fontSize: 22, height: 30/22, fontWeight: FontWeight.w600),
    bodyMedium: const TextStyle(fontSize: 16, height: 24/16, fontWeight: FontWeight.w400, fontFeatures: [FontFeature.tabularFigures()]),
    labelLarge: const TextStyle(fontSize: 16, height: 20/16, fontWeight: FontWeight.w600),
  );
}

ThemeData lightTheme(BuildContext context) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary500,
    primary: AppTokens.primary500,
    secondary: AppTokens.mint400,
    surface: const Color(0xFFF9FAFB),
    onSurface: AppTokens.neutral900,
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppTokens.neutral0,
    textTheme: _textTheme(context, dark: false),
    useMaterial3: true,
    cardTheme: const CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
      ),
    ),
  );
}

ThemeData darkTheme(BuildContext context) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary300,
    primary: AppTokens.primary300,
    secondary: AppTokens.mint400,
    surface: const Color(0xFF1F2937),
    onSurface: AppTokens.neutral0,
    brightness: Brightness.dark,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF111827),
    textTheme: _textTheme(context, dark: true),
    useMaterial3: true,
    cardTheme: CardTheme(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        side: BorderSide(color: Color(0xFF273244), width: 1),
      ),
      color: const Color(0xFF1F2937),
      elevation: 0,
    ),
  );
}
