import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_design_system.dart';
import 'package:tradex_mobile/core/theme/tradex_palette.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';

void main() {
  group('TradeX professional design system', () {
    for (final theme in <ThemeData>[TradeXTheme.light, TradeXTheme.dark]) {
      test('${theme.brightness.name} theme exposes the semantic palette', () {
        final palette = theme.extension<TradeXPalette>();

        expect(palette, isNotNull);
        expect(theme.useMaterial3, isTrue);
        expect(theme.scaffoldBackgroundColor, palette!.background);
        expect(theme.colorScheme.surface, palette.surface);
        expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      });

      test('${theme.brightness.name} controls share product geometry', () {
        final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
        final buttonShape = theme.filledButtonTheme.style!.shape!.resolve({});
        final inputBorder = theme.inputDecorationTheme.enabledBorder!;

        expect(cardShape.borderRadius, TradeXRadii.card);
        expect(
          (buttonShape! as RoundedRectangleBorder).borderRadius,
          TradeXRadii.control,
        );
        expect(
          (inputBorder as OutlineInputBorder).borderRadius,
          TradeXRadii.control,
        );
      });
    }

    test('spacing and motion tokens remain touch-friendly', () {
      expect(TradeXSpacing.lg, greaterThanOrEqualTo(20));
      expect(TradeXRadii.control.topLeft.x, greaterThanOrEqualTo(16));
      expect(
        TradeXMotion.standard,
        lessThan(const Duration(milliseconds: 300)),
      );
    });
  });
}
