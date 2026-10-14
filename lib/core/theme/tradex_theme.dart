import 'package:flutter/material.dart';

import 'tradex_colors.dart';

abstract final class TradeXTheme {
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
