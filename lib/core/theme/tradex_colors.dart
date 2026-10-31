import 'package:flutter/material.dart';

abstract final class TradeXColors {
  // Legacy compile-time tokens retained for widgets that have not yet moved to
  // TradeXPalette. These mirror the clean graphite dark theme.
  static const Color background = Color(0xFF0B1017);
  static const Color backgroundSoft = Color(0xFF111923);

  static const Color surface = Color(0xFF151D27);
  static const Color surfaceRaised = Color(0xFF1B2633);
  static const Color surfaceMuted = Color(0xFF111923);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFE4BD61);
  static const Color goldSoft = Color(0xFF342C19);
  static const Color goldDeep = Color(0xFF8A6412);

  static const Color primaryText = Color(0xFFF4F6F8);
  static const Color secondaryText = Color(0xFFA9B3C2);
  static const Color tertiaryText = Color(0xFF8895A7);

  static const Color border = Color(0xFF293342);
  static const Color borderStrong = Color(0xFF3C4B5F);

  static const Color success = Color(0xFF49D6A2);
  static const Color error = Color(0xFFFF7575);
  static const Color warning = Color(0xFFE6BF66);
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
      TradeXColors.goldPale,
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
