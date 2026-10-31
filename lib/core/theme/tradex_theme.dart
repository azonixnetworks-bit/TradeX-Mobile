import 'package:flutter/material.dart';

import 'tradex_palette.dart';

abstract final class TradeXTheme {
  static ThemeData get light => _build(TradeXPalette.light, false);
  static ThemeData get dark => _build(TradeXPalette.dark, true);

  static ThemeData _build(TradeXPalette p, bool isDark) {
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final scheme = isDark
        ? ColorScheme.dark(
            primary: p.gold,
            onPrimary: p.primaryButtonText,
            secondary: p.goldText,
            onSecondary: p.primaryButtonText,
            surface: p.surface,
            onSurface: p.primaryText,
            error: p.error,
            onError: p.primaryButtonText,
          )
        : ColorScheme.light(
            primary: p.goldText,
            onPrimary: Colors.white,
            secondary: p.gold,
            onSecondary: p.primaryButtonText,
            surface: p.surface,
            onSurface: p.primaryText,
            error: p.error,
            onError: Colors.white,
          );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      iconTheme: IconThemeData(color: p.secondaryText, size: 21),
      primaryIconTheme: IconThemeData(color: p.goldText),
      textTheme: base.textTheme
          .apply(bodyColor: p.primaryText, displayColor: p.primaryText)
          .copyWith(
            bodySmall: TextStyle(
              color: p.secondaryText,
              fontSize: 12,
              height: 1.35,
            ),
            bodyMedium: TextStyle(
              color: p.primaryText,
              fontSize: 14,
              height: 1.42,
            ),
            titleSmall: TextStyle(
              color: p.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: TextStyle(
              color: p.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              color: p.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: TextStyle(
              color: p.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: p.tertiaryText),
        labelStyle: TextStyle(color: p.secondaryText),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: p.goldText, width: 1.5),
        ),
        errorBorder: outline.copyWith(borderSide: BorderSide(color: p.error)),
        focusedErrorBorder: outline.copyWith(
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.gold,
          foregroundColor: p.primaryButtonText,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.tertiaryText,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.gold,
          foregroundColor: p.primaryButtonText,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.goldText,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.goldText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.goldText),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: p.primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceRaised,
        contentTextStyle: TextStyle(color: p.primaryText),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.navBackground,
        selectedItemColor: p.goldText,
        unselectedItemColor: p.secondaryText,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.navBackground,
        indicatorColor: p.goldSoft,
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.goldText,
        unselectedLabelColor: p.secondaryText,
        indicatorColor: p.goldText,
        dividerColor: p.border,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.gold,
        foregroundColor: p.primaryButtonText,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.goldText),
      splashColor: p.gold.withValues(alpha: .08),
      highlightColor: Colors.transparent,
    );
  }
}
