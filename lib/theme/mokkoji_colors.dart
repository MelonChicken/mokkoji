import 'package:flutter/material.dart';

class MokkojiColors extends ThemeExtension<MokkojiColors> {
  // Aqua pastel color palette
  static const Color aqua600 = Color(0xFF26C6DA);
  static const Color aqua500 = Color(0xFF4DD0E1);
  static const Color aqua300 = Color(0xFF80DEEA);
  static const Color aqua200 = Color(0xFFB2EBF2);
  static const Color aqua50 = Color(0xFFE0F7FA);
  static const Color onAqua = Color(0xFF001317); // Dark theme compatible

  // Orange color palette for time blocks
  static const Color orange500 = Color(0xFFF97316);
  
  // Blue color palette for source chips
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue50 = Color(0xFFEFF6FF);
  
  // Green color palette for source chips
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green800 = Color(0xFF166534);
  
  // Orange color palette for time blocks
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange700 = Color(0xFFC2410C);
  static const Color orange800 = Color(0xFF9A3412);
  
  // Gray color palette for source chips
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray800 = Color(0xFF1F2937);
  
  // Dark theme neutral colors
  static const Color darkBg = Color(0xFF0B1F28);
  static const Color darkSurface = Color(0xFF0F2A33);
  static const Color darkHair = Color(0xFF1E4752);
  static const Color onSurface = Color(0xFFE6F7FA);
  static const Color onSurface2 = Color(0xFFB6D4DC);

  // Dark theme variants for better contrast (WCAG AA compliance)
  static const Color darkAqua50 = Color(0xFF1A3D4A);
  static const Color darkAqua200 = Color(0xFF2A505E);
  static const Color darkGray100 = Color(0xFF2A3441);
  static const Color darkGray800 = Color(0xFFE2E8F0);
  static const Color darkBlue50 = Color(0xFF1E3A5F);
  static const Color darkBlue100 = Color(0xFF2D4A70);
  static const Color darkOrange50 = Color(0xFF4A2E1A);
  static const Color darkOrange100 = Color(0xFF5E3D2A);

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