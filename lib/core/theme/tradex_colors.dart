import 'package:flutter/material.dart';

abstract final class TradeXColors {
  // Legacy compile-time tokens retained for widgets that have not yet moved to
  // TradeXPalette. These mirror the clean graphite dark theme.
  static const Color background = Color(0xFF080D13);
  static const Color backgroundSoft = Color(0xFF0D141D);

  static const Color surface = Color(0xFF111923);
  static const Color surfaceRaised = Color(0xFF17222E);
  static const Color surfaceMuted = Color(0xFF0D141D);

  static const Color gold = Color(0xFFD7B24A);
  static const Color goldBright = Color(0xFFE9C96D);
  static const Color goldSoft = Color(0xFF302815);
  static const Color goldDeep = Color(0xFF76550D);

  static const Color primaryText = Color(0xFFF5F7FA);
  static const Color secondaryText = Color(0xFFADB7C5);
  static const Color tertiaryText = Color(0xFF8793A4);

  static const Color border = Color(0xFF24303F);
  static const Color borderStrong = Color(0xFF38485C);

  static const Color success = Color(0xFF4AD6A3);
  static const Color error = Color(0xFFFF7B7B);
  static const Color warning = Color(0xFFE8C16A);
}

/// Reusable luxury finishes. Keep gradients limited to hero surfaces,
/// selected states and primary CTAs rather than every card.
abstract final class TradeXGradients {
  static const LinearGradient primaryGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B7327),
      TradeXColors.gold,
      TradeXColors.goldBright,
      TradeXColors.gold,
    ],
    stops: [0.0, 0.33, 0.62, 1.0],
  );

  static const LinearGradient darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TradeXColors.surfaceRaised, TradeXColors.surface],
  );

  static const LinearGradient selectedCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2515), TradeXColors.surfaceRaised],
  );
}
