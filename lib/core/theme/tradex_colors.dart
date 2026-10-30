import 'package:flutter/material.dart';

abstract final class TradeXColors {
  static const Color background = Color(0xFF050706);
  static const Color backgroundSoft = Color(0xFF080B0A);

  static const Color surface = Color(0xFF0D1110);
  static const Color surfaceRaised = Color(0xFF111614);
  static const Color surfaceMuted = Color(0xFF151A18);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFFFC83D);
  static const Color goldSoft = Color(0xFF9E7920);
  static const Color goldDeep = Color(0xFF6F5010);

  // Brand-focused accents. Use these for interactive UI, not for P&L semantics.
  static const Color goldPale = Color(0xFFFFE7A0);
  static const Color goldOutline = Color(0xFF6B5427);
  static const Color onGold = Color(0xFF171106);

  static const Color primaryText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF9CA3AF);
  static const Color tertiaryText = Color(0xFF6B7280);

  static const Color border = Color(0xFF27302D);
  static const Color borderStrong = Color(0xFF3B443F);

  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
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
