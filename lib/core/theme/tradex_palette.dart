import 'package:flutter/material.dart';

/// Semantic TradeX colors resolved from the active light or dark theme.
@immutable
class TradeXPalette extends ThemeExtension<TradeXPalette> {
  const TradeXPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.border,
    required this.borderStrong,
    required this.gold,
    required this.goldText,
    required this.goldSoft,
    required this.success,
    required this.error,
    required this.warning,
    required this.navBackground,
    required this.primaryButtonText,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color border;
  final Color borderStrong;
  final Color gold;
  final Color goldText;
  final Color goldSoft;
  final Color success;
  final Color error;
  final Color warning;
  final Color navBackground;
  final Color primaryButtonText;

  static const light = TradeXPalette(
    background: Color(0xFFFAF9FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF5F3F6),
    primaryText: Color(0xFF101828),
    secondaryText: Color(0xFF5D6878),
    tertiaryText: Color(0xFF7B8493),
    border: Color(0xFFE6E2E9),
    borderStrong: Color(0xFFDAD5DF),
    gold: Color(0xFFD7B24A),
    goldText: Color(0xFF76550D),
    goldSoft: Color(0xFFFFF2D6),
    success: Color(0xFF067A55),
    error: Color(0xFFB42318),
    warning: Color(0xFF946200),
    navBackground: Color(0xFFFFFFFF),
    primaryButtonText: Color(0xFF12100A),
  );

  static const dark = TradeXPalette(
    background: Color(0xFF080D13),
    surface: Color(0xFF111923),
    surfaceRaised: Color(0xFF17222E),
    surfaceMuted: Color(0xFF0D141D),
    primaryText: Color(0xFFF5F7FA),
    secondaryText: Color(0xFFADB7C5),
    tertiaryText: Color(0xFF8793A4),
    border: Color(0xFF24303F),
    borderStrong: Color(0xFF38485C),
    gold: Color(0xFFD7B24A),
    goldText: Color(0xFFE9C96D),
    goldSoft: Color(0xFF302815),
    success: Color(0xFF4AD6A3),
    error: Color(0xFFFF7B7B),
    warning: Color(0xFFE8C16A),
    navBackground: Color(0xFF0E151E),
    primaryButtonText: Color(0xFF12100A),
  );

  static TradeXPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TradeXPalette>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  TradeXPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? border,
    Color? borderStrong,
    Color? gold,
    Color? goldText,
    Color? goldSoft,
    Color? success,
    Color? error,
    Color? warning,
    Color? navBackground,
    Color? primaryButtonText,
  }) {
    return TradeXPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      goldSoft: goldSoft ?? this.goldSoft,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      navBackground: navBackground ?? this.navBackground,
      primaryButtonText: primaryButtonText ?? this.primaryButtonText,
    );
  }

  @override
  TradeXPalette lerp(TradeXPalette? other, double t) {
    if (other == null) return this;
    return TradeXPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      primaryButtonText: Color.lerp(
        primaryButtonText,
        other.primaryButtonText,
        t,
      )!,
    );
  }
}
