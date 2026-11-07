import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tradex_design_system.dart';
import 'tradex_palette.dart';

abstract final class TradeXTheme {
  static ThemeData get light => _build(TradeXPalette.light, Brightness.light);
  static ThemeData get dark => _build(TradeXPalette.dark, Brightness.dark);

  static ThemeData _build(TradeXPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? p.gold : p.goldText,
      onPrimary: isDark ? p.primaryButtonText : Colors.white,
      secondary: p.gold,
      onSecondary: p.primaryButtonText,
      error: p.error,
      onError: isDark ? p.primaryButtonText : Colors.white,
      surface: p.surface,
      onSurface: p.primaryText,
      surfaceContainerHighest: p.surfaceRaised,
      outline: p.borderStrong,
      outlineVariant: p.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: p.primaryText,
      onInverseSurface: p.background,
      inversePrimary: p.gold,
    );
    final controlShape = RoundedRectangleBorder(
      borderRadius: TradeXRadii.control,
    );
    final outline = OutlineInputBorder(
      borderRadius: TradeXRadii.control,
      borderSide: BorderSide(color: p.border),
    );
    final textTheme = base.textTheme
        .apply(bodyColor: p.primaryText, displayColor: p.primaryText)
        .copyWith(
          displaySmall: TextStyle(
            color: p.primaryText,
            fontSize: 36,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
          headlineLarge: TextStyle(
            color: p.primaryText,
            fontSize: 30,
            height: 1.16,
            fontWeight: FontWeight.w700,
            letterSpacing: -.45,
          ),
          headlineMedium: TextStyle(
            color: p.primaryText,
            fontSize: 26,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
          headlineSmall: TextStyle(
            color: p.primaryText,
            fontSize: 22,
            height: 1.22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.18,
          ),
          titleLarge: TextStyle(
            color: p.primaryText,
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: p.primaryText,
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: p.primaryText,
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: p.primaryText,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: p.primaryText,
            fontSize: 14,
            height: 1.48,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: p.secondaryText,
            fontSize: 12,
            height: 1.42,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: p.primaryText,
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: .1,
          ),
          labelMedium: TextStyle(
            color: p.secondaryText,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: .16,
          ),
          labelSmall: TextStyle(
            color: p.tertiaryText,
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      disabledColor: p.tertiaryText.withValues(alpha: .55),
      splashColor: p.gold.withValues(alpha: .08),
      highlightColor: Colors.transparent,
      hoverColor: p.gold.withValues(alpha: .05),
      focusColor: p.gold.withValues(alpha: .12),
      iconTheme: IconThemeData(color: p.secondaryText, size: 21),
      primaryIconTheme: IconThemeData(color: p.goldText, size: 21),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: kToolbarHeight,
        titleSpacing: TradeXSpacing.lg,
        iconTheme: IconThemeData(color: p.primaryText, size: 22),
        actionsIconTheme: IconThemeData(color: p.secondaryText, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: TradeXRadii.card,
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TradeXSpacing.md,
          vertical: 15,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.tertiaryText),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.secondaryText),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: p.goldText,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: p.error),
        prefixIconColor: p.tertiaryText,
        suffixIconColor: p.secondaryText,
        border: outline,
        enabledBorder: outline,
        disabledBorder: outline.copyWith(
          borderSide: BorderSide(color: p.border.withValues(alpha: .6)),
        ),
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
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TradeXSpacing.lg,
            vertical: TradeXSpacing.sm,
          ),
          shape: controlShape,
          elevation: 0,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.gold,
          foregroundColor: p.primaryButtonText,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.tertiaryText,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TradeXSpacing.lg,
            vertical: TradeXSpacing.sm,
          ),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.goldText,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TradeXSpacing.lg,
            vertical: TradeXSpacing.sm,
          ),
          side: BorderSide(color: p.borderStrong),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.goldText,
          padding: const EdgeInsets.symmetric(
            horizontal: TradeXSpacing.sm,
            vertical: TradeXSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TradeXRadii.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.secondaryText,
          backgroundColor: Colors.transparent,
          highlightColor: p.goldSoft,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TradeXRadii.sm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: p.goldSoft,
        disabledColor: p.surfaceMuted.withValues(alpha: .55),
        side: BorderSide(color: p.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: TradeXSpacing.xs),
        labelStyle: textTheme.labelMedium?.copyWith(color: p.secondaryText),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: p.goldText),
        iconTheme: IconThemeData(color: p.secondaryText, size: 18),
        checkmarkColor: p.goldText,
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        minVerticalPadding: TradeXSpacing.sm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TradeXSpacing.md,
          vertical: TradeXSpacing.xxs,
        ),
        iconColor: p.secondaryText,
        textColor: p.primaryText,
        selectedColor: p.goldText,
        selectedTileColor: p.goldSoft,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: TradeXRadii.control),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: TradeXRadii.control,
          side: BorderSide(color: p.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: p.secondaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TradeXRadii.xl),
          side: BorderSide(color: p.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: TradeXRadii.sheet),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: p.goldText,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          TradeXSpacing.md,
          0,
          TradeXSpacing.md,
          TradeXSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: TradeXRadii.control,
          side: BorderSide(color: p.border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.navBackground,
        selectedItemColor: p.goldText,
        unselectedItemColor: p.secondaryText,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: p.navBackground,
        indicatorColor: p.goldSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? p.goldText : p.secondaryText,
            size: selected ? 23 : 21,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            color: selected ? p.goldText : p.secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.navBackground,
        indicatorColor: p.goldSoft,
        selectedIconTheme: IconThemeData(color: p.goldText),
        unselectedIconTheme: IconThemeData(color: p.secondaryText),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: p.goldText,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.goldText,
        unselectedLabelColor: p.secondaryText,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: p.goldText,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
        overlayColor: WidgetStatePropertyAll(p.gold.withValues(alpha: .06)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.gold,
        foregroundColor: p.primaryButtonText,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: TradeXRadii.control),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.goldText,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: p.surfaceMuted,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.gold;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(p.primaryButtonText),
        side: BorderSide(color: p.borderStrong, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TradeXRadii.xs / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.goldText
              : p.borderStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primaryButtonText
              : p.secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.gold : p.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : p.borderStrong,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(TradeXRadii.pill),
        thumbColor: WidgetStatePropertyAll(
          p.secondaryText.withValues(alpha: .34),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(TradeXRadii.xs),
          border: Border.all(color: p.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: p.primaryText),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
