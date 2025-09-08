// 설계 요지: WCAG 2.1 기준 대비율 계산 및 자동 보정 유틸리티
// 배경 색상에 따라 최적의 전경 색상을 자동 선택하여 접근성 준수
// 일반 텍스트 4.5:1, 큰 텍스트 3:1 이상의 대비율 보장

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// WCAG 2.1 기준 대비율 계산 클래스
class ContrastUtils {
  ContrastUtils._();

  /// 상대 휘도(relative luminance) 계산 (WCAG 공식)
  static double _luminance(Color color) {
    final r = _srgbToLinear(color.red / 255.0);
    final g = _srgbToLinear(color.green / 255.0);
    final b = _srgbToLinear(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// sRGB → 선형 RGB 변환
  static double _srgbToLinear(double value) {
    return value <= 0.03928 
        ? value / 12.92 
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  /// 두 색상 간의 대비율 계산 (1:1 ~ 21:1)
  static double contrastRatio(Color foreground, Color background) {
    final luminance1 = _luminance(foreground);
    final luminance2 = _luminance(background);
    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 배경색에 적합한 전경색 결정 (흰색/검은색 중 대비가 더 높은 것)
  static Color resolveOnColor(
    Color background, {
    Color light = Colors.white,
    Color dark = Colors.black,
    double minRatio = 4.5,
  }) {
    final lightRatio = contrastRatio(light, background);
    final darkRatio = contrastRatio(dark, background);
    
    // 둘 다 최소 대비를 만족하면 더 높은 대비를 선택
    if (lightRatio >= minRatio && darkRatio >= minRatio) {
      return lightRatio > darkRatio ? light : dark;
    }
    
    // 하나만 만족하면 그것을 선택
    if (lightRatio >= minRatio) return light;
    if (darkRatio >= minRatio) return dark;
    
    // 둘 다 부족하면 더 나은 쪽을 선택하고 보정 시도
    final betterColor = lightRatio > darkRatio ? light : dark;
    final currentRatio = math.max(lightRatio, darkRatio);
    
    // 대비가 부족한 경우 경고 출력 (디버그 모드)
    assert(() {
      debugPrint('⚠️ Contrast ratio ${currentRatio.toStringAsFixed(2)}:1 '
          'is below minimum ${minRatio}:1');
      return true;
    }());
    
    return _adjustForBetterContrast(betterColor, background, minRatio);
  }

  /// 대비가 부족한 경우 색상 조정 시도
  static Color _adjustForBetterContrast(Color color, Color background, double targetRatio) {
    // 간단한 명도 조정을 통한 대비 개선
    final hsl = HSLColor.fromColor(color);
    
    // 배경이 어두우면 전경을 밝게, 밝으면 어둡게
    final backgroundLuminance = _luminance(background);
    final shouldBrighten = backgroundLuminance < 0.5;
    
    for (var adjustment = 0.1; adjustment <= 0.9; adjustment += 0.1) {
      final newLightness = shouldBrighten 
          ? math.min(1.0, hsl.lightness + adjustment)
          : math.max(0.0, hsl.lightness - adjustment);
      
      final adjustedColor = hsl.withLightness(newLightness).toColor();
      if (contrastRatio(adjustedColor, background) >= targetRatio) {
        return adjustedColor;
      }
    }
    
    // 조정이 불가능하면 원본 반환
    return color;
  }

  /// TextStyle에 적절한 색상 자동 적용
  static TextStyle ensureReadable(
    TextStyle baseStyle, 
    Color backgroundColor, {
    double minRatio = 4.5,
  }) {
    final currentColor = baseStyle.color ?? Colors.black;
    final ratio = contrastRatio(currentColor, backgroundColor);
    
    if (ratio >= minRatio) {
      return baseStyle; // 이미 충분한 대비
    }
    
    // 대비 부족 시 자동 보정
    final improvedColor = resolveOnColor(
      backgroundColor,
      minRatio: minRatio,
    );
    
    return baseStyle.copyWith(color: improvedColor);
  }

  /// 큰 텍스트 여부 판단 (≥18pt 또는 ≥14pt bold)
  static bool isLargeText(TextStyle style) {
    final fontSize = style.fontSize ?? 14.0;
    final fontWeight = style.fontWeight ?? FontWeight.normal;
    
    return fontSize >= 18.0 || 
           (fontSize >= 14.0 && fontWeight.index >= FontWeight.bold.index);
  }

  /// 텍스트 스타일에 맞는 최소 대비율 반환
  static double getMinContrastRatio(TextStyle style) {
    return isLargeText(style) ? 3.0 : 4.5;
  }

  /// 디버그용: 색상 정보와 대비율 출력
  static void debugContrastInfo(Color foreground, Color background, [String? label]) {
    final ratio = contrastRatio(foreground, background);
    final passes = ratio >= 4.5 ? '✅' : ratio >= 3.0 ? '⚠️' : '❌';
    debugPrint('$passes ${label ?? 'Contrast'}: ${ratio.toStringAsFixed(2)}:1 '
        '(fg: ${foreground.value.toRadixString(16)}, '
        'bg: ${background.value.toRadixString(16)})');
  }

  /// Material 3 ColorScheme 기반 on-color 매핑
  static Map<String, Color> resolveAllOnColors(ColorScheme scheme) {
    return {
      'onPrimary': resolveOnColor(scheme.primary),
      'onPrimaryContainer': resolveOnColor(scheme.primaryContainer),
      'onSecondary': resolveOnColor(scheme.secondary),
      'onSecondaryContainer': resolveOnColor(scheme.secondaryContainer),
      'onTertiary': resolveOnColor(scheme.tertiary),
      'onTertiaryContainer': resolveOnColor(scheme.tertiaryContainer),
      'onSurface': resolveOnColor(scheme.surface),
      'onSurfaceVariant': resolveOnColor(scheme.surfaceVariant),
      'onError': resolveOnColor(scheme.error),
      'onErrorContainer': resolveOnColor(scheme.errorContainer),
    };
  }
}

/// ColorScheme 확장: 대비 검증된 색상 조합 제공
extension ContrastAwareColorScheme on ColorScheme {
  /// 배경에 적합한 전경색 자동 결정
  Color onColorFor(Color backgroundColor) {
    return ContrastUtils.resolveOnColor(backgroundColor);
  }

  /// 안전한 텍스트 색상 (최소 4.5:1 대비 보장)
  Color safeTextColor(Color backgroundColor) {
    return ContrastUtils.resolveOnColor(backgroundColor, minRatio: 4.5);
  }

  /// 큰 텍스트용 색상 (최소 3:1 대비 보장)
  Color largeTextColor(Color backgroundColor) {
    return ContrastUtils.resolveOnColor(backgroundColor, minRatio: 3.0);
  }
}

// 수용 기준 (Acceptance Criteria):
// - WCAG 2.1 AA 기준 대비율 계산 정확도 (4.5:1, 3:1)
// - 모든 UI 컴포넌트에서 배경-전경 조합 자동 최적화
// - 다크/라이트 모드 전환 시 일관된 가독성 유지
// - 런타임 대비 부족 검출 및 디버그 정보 제공