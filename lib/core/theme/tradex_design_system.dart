import 'package:flutter/material.dart';

import 'tradex_palette.dart';

/// Shared visual tokens for the TradeX product surface.
///
/// Keeping these values in one place prevents feature screens from drifting
/// into slightly different spacing, corner radius and motion conventions.
abstract final class TradeXSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(md);
}

abstract final class TradeXRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

abstract final class TradeXMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration deliberate = Duration(milliseconds: 360);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}

abstract final class TradeXElevation {
  static List<BoxShadow> surface({
    required Brightness brightness,
    required TradeXPalette palette,
  }) {
    final dark = brightness == Brightness.dark;
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? .24 : .07),
        blurRadius: dark ? 24 : 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: palette.gold.withValues(alpha: dark ? .025 : .018),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> floating({
    required Brightness brightness,
    required TradeXPalette palette,
  }) {
    final dark = brightness == Brightness.dark;
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? .42 : .13),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: palette.gold.withValues(alpha: dark ? .06 : .04),
        blurRadius: 24,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

extension TradeXThemeContext on BuildContext {
  TradeXPalette get palette => TradeXPalette.of(this);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
