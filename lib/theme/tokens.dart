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

  // Neutrals - Full spectrum for dark mode support
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF9FAFB);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral400 = Color(0xFF9CA3AF);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral600 = Color(0xFF4B5563);
  static const neutral700 = Color(0xFF374151);
  static const neutral750 = Color(0xFF2D3748); // Custom for surface variants
  static const neutral800 = Color(0xFF1F2937);
  static const neutral875 = Color(0xFF1A202C); // Custom for input fields in dark
  static const neutral900 = Color(0xFF111827);
  static const neutral950 = Color(0xFF0C0F17); // Darkest for background
  
  // Dark mode specific tokens
  static const neutral650 = Color(0xFF3F4651); // For outline variants

  // Semantic (WCAG AA compliant)
  static const success = Color(0xFF047857); // Emerald-700 (4.5:1 on white)
  static const warning = Color(0xFFB45309); // Amber-700 (4.5:1 on white) 
  static const error = Color(0xFFDC2626); // Red-600 (5.9:1 on white)
  static const error400 = Color(0xFFF87171); // Red-400 for dark mode

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
