import 'package:flutter/material.dart';

class MokkojiColors extends ThemeExtension<MokkojiColors> {
  // Aqua pastel color palette
  static const Color aqua600 = Color(0xFF26C6DA);
  static const Color aqua500 = Color(0xFF4DD0E1);
  static const Color aqua300 = Color(0xFF80DEEA);
  static const Color aqua200 = Color(0xFFB2EBF2);
  static const Color aqua50 = Color(0xFFE0F7FA);
  static const Color onAqua = Color(0xFF001317); // Dark theme compatible
  
  // Dark theme neutral colors
  static const Color darkBg = Color(0xFF0B1F28);
  static const Color darkSurface = Color(0xFF0F2A33);
  static const Color darkHair = Color(0xFF1E4752);
  static const Color onSurface = Color(0xFFE6F7FA);
  static const Color onSurface2 = Color(0xFFB6D4DC);

  const MokkojiColors();

  @override
  MokkojiColors copyWith() {
    return const MokkojiColors();
  }

  @override
  MokkojiColors lerp(MokkojiColors? other, double t) {
    return const MokkojiColors();
  }

  static const MokkojiColors light = MokkojiColors();
}

extension MokkojiColorsContext on BuildContext {
  MokkojiColors get mokkojiColors => 
      Theme.of(this).extension<MokkojiColors>() ?? MokkojiColors.light;
}