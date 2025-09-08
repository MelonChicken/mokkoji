// Design Tokens for Mokkoji
import 'package:flutter/material.dart';

class AppTokens {
  // Colors
  // Primary Coral (adjusted for better accessibility)
  static const primary500 = Color(0xFFD4282F); // Darker coral with 4.5:1 contrast on white
  static const primary600 = Color(0xFFBD242A); // Darker variant
  static const primary300 = Color(0xFFFF9999); // Light version for dark themes

  // Mint (secondary accent)
  static const mint400 = Color(0xFF0D9F79); // Darker mint for better contrast

  // Lilac (accent)
  static const lilac300 = Color(0xFF8B5CF6); // Darker lilac for accessibility

  // Neutrals
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral900 = Color(0xFF111827);

  // Semantic (WCAG AA compliant)
  static const success = Color(0xFF047857); // Emerald-700 (4.5:1 on white)
  static const warning = Color(0xFFB45309); // Amber-700 (4.5:1 on white) 
  static const error = Color(0xFFDC2626); // Red-600 (5.9:1 on white)

  // Spacing (8pt scale + extras)
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s64 = 64.0;

  // Radius
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;

  // Elevation
  static const e1 = <BoxShadow>[
    BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const e2 = <BoxShadow>[
    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
  ];
}
