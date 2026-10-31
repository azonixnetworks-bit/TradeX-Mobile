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
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0F2F5),
    primaryText: Color(0xFF17212E),
    secondaryText: Color(0xFF667085),
    tertiaryText: Color(0xFF767F8E),
    border: Color(0xFFE1E5EB),
    borderStrong: Color(0xFFD1D6DF),
    gold: Color(0xFFD4AF37),
    goldText: Color(0xFF8A6412),
    goldSoft: Color(0xFFF5EDD8),
    success: Color(0xFF087F5B),
    error: Color(0xFFB42318),
    warning: Color(0xFF9B6507),
    navBackground: Color(0xFFFFFFFF),
    primaryButtonText: Color(0xFF11151B),
  );

  static const dark = TradeXPalette(
    background: Color(0xFF0B1017),
    surface: Color(0xFF151D27),
    surfaceRaised: Color(0xFF1B2633),
    surfaceMuted: Color(0xFF111923),
    primaryText: Color(0xFFF4F6F8),
    secondaryText: Color(0xFFA9B3C2),
    tertiaryText: Color(0xFF8895A7),
    border: Color(0xFF293342),
    borderStrong: Color(0xFF3C4B5F),
    gold: Color(0xFFD4AF37),
    goldText: Color(0xFFE4BD61),
    goldSoft: Color(0xFF342C19),
    success: Color(0xFF49D6A2),
    error: Color(0xFFFF7575),
    warning: Color(0xFFE6BF66),
    navBackground: Color(0xFF0F1721),
    primaryButtonText: Color(0xFF11151B),
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
