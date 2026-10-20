import 'package:flutter/material.dart';

import 'tradex_colors.dart';

abstract final class TradeXTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    const background = Color(0xFFF5F4EF);
    const surface = Color(0xFFFFFFFF);
    const text = Color(0xFF171A18);
    const border = Color(0xFFD9D6CC);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: TradeXColors.goldDeep,
        secondary: TradeXColors.gold,
        surface: surface,
        error: TradeXColors.error,
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      dividerColor: border,
      cardTheme: const CardThemeData(color: surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: TradeXColors.background,
      colorScheme: const ColorScheme.dark(
        primary: TradeXColors.gold,
        secondary: TradeXColors.goldBright,
        surface: TradeXColors.surface,
        error: TradeXColors.error,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: TradeXColors.primaryText,
        displayColor: TradeXColors.primaryText,
      ),
      dividerColor: TradeXColors.border,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
