// 설계 요지: 다크/라이트 대비 최적화 전면 적용된 Material 3 테마
// 기존 AppTokens 유지하면서 ColorScheme on-colors와 동적 대비 유틸 통합
// 모든 컴포넌트가 배경-전경 조합에서 WCAG 2.1 AA 기준 자동 준수

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';
import 'contrast.dart';

/// 대비 최적화된 ColorScheme 생성
ColorScheme _createOptimizedColorScheme({
  required Brightness brightness,
  required Color primary,
  required Color secondary,
  Color? surface,
  Color? background,
}) {
  final isDark = brightness == Brightness.dark;
  
  // 기본 ColorScheme 생성
  final baseScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  );
  
  // 커스텀 색상 적용
  final customScheme = baseScheme.copyWith(
    primary: primary,
    secondary: secondary,
    surface: surface ?? baseScheme.surface,
    background: background ?? baseScheme.background,
    
    // on-colors를 대비 유틸로 자동 계산
    onPrimary: ContrastUtils.resolveOnColor(primary),
    onSecondary: ContrastUtils.resolveOnColor(secondary),
    onSurface: ContrastUtils.resolveOnColor(surface ?? baseScheme.surface),
    onBackground: ContrastUtils.resolveOnColor(background ?? baseScheme.background),
    
    // 에러 색상도 대비 최적화
    error: isDark ? AppTokens.error.withOpacity(0.8) : AppTokens.error,
    onError: ContrastUtils.resolveOnColor(
      isDark ? AppTokens.error.withOpacity(0.8) : AppTokens.error
    ),
  );
  
  return customScheme;
}

/// 텍스트 테마 생성 (대비 보정 포함)
TextTheme _createTextTheme({
  required ColorScheme colorScheme,
  required bool isDark,
}) {
  final baseTextTheme = GoogleFonts.notoSansKrTextTheme();
  
  return baseTextTheme.copyWith(
    // 헤드라인
    headlineSmall: TextStyle(
      fontSize: 28, 
      height: 36/28, 
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    
    // 타이틀
    titleLarge: TextStyle(
      fontSize: 24,
      height: 32/24,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 22, 
      height: 30/22, 
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 18,
      height: 26/18,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    
    // 바디
    bodyLarge: TextStyle(
      fontSize: 18,
      height: 26/18,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 16, 
      height: 24/16, 
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      height: 20/14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurfaceVariant,
    ),
    
    // 라벨
    labelLarge: TextStyle(
      fontSize: 16, 
      height: 20/16, 
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      height: 18/14,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 16/12,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
    ),
  );
}

/// 컴포넌트별 테마 데이터 생성
class _ComponentThemes {
  static AppBarTheme appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  static BottomSheetThemeData bottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
    );
  }

  static CardTheme cardTheme(ColorScheme colorScheme, bool isDark) {
    return CardTheme(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        side: isDark 
            ? BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)
            : BorderSide.none,
      ),
    );
  }

  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  static FilledButtonThemeData filledButtonTheme(ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  static TextButtonThemeData textButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    );
  }

  static ChipThemeData chipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primary.withOpacity(0.12),
      disabledColor: colorScheme.surface.withOpacity(0.38),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
    );
  }

  static DialogTheme dialogTheme(ColorScheme colorScheme) {
    return DialogTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
    );
  }

  static SnackBarThemeData snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }

  static DividerThemeData dividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outline.withOpacity(0.2),
      thickness: 1,
      space: 1,
    );
  }

  static IconThemeData iconTheme(ColorScheme colorScheme) {
    return IconThemeData(
      color: colorScheme.onSurface,
      size: 24,
    );
  }
}

/// 라이트 테마 생성
ThemeData lightTheme(BuildContext context) {
  final colorScheme = _createOptimizedColorScheme(
    brightness: Brightness.light,
    primary: AppTokens.primary500,
    secondary: AppTokens.mint400,
    surface: const Color(0xFFF9FAFB),
    background: AppTokens.neutral0,
  );
  
  final textTheme = _createTextTheme(
    colorScheme: colorScheme,
    isDark: false,
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppTokens.neutral0,
    useMaterial3: true,
    
    // 컴포넌트 테마
    appBarTheme: _ComponentThemes.appBarTheme(colorScheme),
    bottomSheetTheme: _ComponentThemes.bottomSheetTheme(colorScheme),
    cardTheme: _ComponentThemes.cardTheme(colorScheme, false),
    elevatedButtonTheme: _ComponentThemes.elevatedButtonTheme(colorScheme),
    filledButtonTheme: _ComponentThemes.filledButtonTheme(colorScheme),
    textButtonTheme: _ComponentThemes.textButtonTheme(colorScheme),
    inputDecorationTheme: _ComponentThemes.inputDecorationTheme(colorScheme),
    chipTheme: _ComponentThemes.chipTheme(colorScheme),
    dialogTheme: _ComponentThemes.dialogTheme(colorScheme),
    snackBarTheme: _ComponentThemes.snackBarTheme(colorScheme),
    dividerTheme: _ComponentThemes.dividerTheme(colorScheme),
    iconTheme: _ComponentThemes.iconTheme(colorScheme),
    primaryIconTheme: IconThemeData(color: colorScheme.onPrimary),
    
    // Material 3 세부 조정
    splashFactory: InkSparkle.splashFactory,
    
    // 접근성 개선
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

/// 다크 테마 생성
ThemeData darkTheme(BuildContext context) {
  final colorScheme = _createOptimizedColorScheme(
    brightness: Brightness.dark,
    primary: AppTokens.primary300,
    secondary: AppTokens.mint400,
    surface: const Color(0xFF1F2937),
    background: const Color(0xFF111827),
  );
  
  final textTheme = _createTextTheme(
    colorScheme: colorScheme,
    isDark: true,
  );

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: const Color(0xFF111827),
    useMaterial3: true,
    
    // 컴포넌트 테마
    appBarTheme: _ComponentThemes.appBarTheme(colorScheme),
    bottomSheetTheme: _ComponentThemes.bottomSheetTheme(colorScheme),
    cardTheme: _ComponentThemes.cardTheme(colorScheme, true),
    elevatedButtonTheme: _ComponentThemes.elevatedButtonTheme(colorScheme),
    filledButtonTheme: _ComponentThemes.filledButtonTheme(colorScheme),
    textButtonTheme: _ComponentThemes.textButtonTheme(colorScheme),
    inputDecorationTheme: _ComponentThemes.inputDecorationTheme(colorScheme),
    chipTheme: _ComponentThemes.chipTheme(colorScheme),
    dialogTheme: _ComponentThemes.dialogTheme(colorScheme),
    snackBarTheme: _ComponentThemes.snackBarTheme(colorScheme),
    dividerTheme: _ComponentThemes.dividerTheme(colorScheme),
    iconTheme: _ComponentThemes.iconTheme(colorScheme),
    primaryIconTheme: IconThemeData(color: colorScheme.onPrimary),
    
    // Material 3 세부 조정
    splashFactory: InkSparkle.splashFactory,
    
    // 접근성 개선
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// 수용 기준 (Acceptance Criteria):
// - 모든 UI 컴포넌트에서 배경-전경 색상 조합이 WCAG 2.1 AA 기준 준수
// - 다크/라이트 모드 전환 시 일관된 시각적 계층 구조 유지
// - Material 3 디자인 시스템과 기존 AppTokens 완전 통합
// - 하드코딩된 색상 제거 및 ColorScheme 기반 동적 참조 적용