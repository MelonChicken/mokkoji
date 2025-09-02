// Design Tokens for Mokkoji
import 'package:flutter/material.dart';

class AppTokens {
  // Colors
  // Primary Coral
  static const primary500 = Color(0xFFFF6B6B);
  static const primary600 = Color(0xFFE85A5A);
  static const primary300 = Color(0xFFECB6B6); // Dark 강조

  // Mint (secondary accent)
  static const mint400 = Color(0xFF2ED5A4);

  // Lilac (accent)
  static const lilac300 = Color(0xFFB79AFF);

  // Neutrals
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral900 = Color(0xFF111827);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Spacing (8pt scale + extras)
  static const s4 = 4.0;
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
