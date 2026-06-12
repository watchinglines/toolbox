// lib/design_system/theme.dart - 主题
import 'package:flutter/material.dart';

import 'tokens.dart';

class ToolBoxTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: TBColors.primary,
        secondary: TBColors.secondary,
        surface: TBColors.surfaceLight,
        error: TBColors.error,
        onSurface: TBColors.onSurfaceLight,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      useMaterial3: true,
      fontFamily: 'PingFang SC', // 中文字体
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        secondary: Color(0xFF34D399),
        surface: TBColors.surfaceDark,
        error: Color(0xFFF87171),
        onSurface: TBColors.onSurfaceDark,
      ),
      scaffoldBackgroundColor: const Color(0xFF020617),
      useMaterial3: true,
    );
  }
}
