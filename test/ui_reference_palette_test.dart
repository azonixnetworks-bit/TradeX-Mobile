import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_palette.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';

void main() {
  test('reference-aligned light palette retains semantic contrast', () {
    final palette = TradeXPalette.light;
    expect(palette.background, const Color(0xFFFAF9FB));
    expect(palette.surface, const Color(0xFFFFFFFF));
    expect(palette.surfaceMuted, const Color(0xFFF5F3F6));
    expect(palette.goldSoft, const Color(0xFFFFF2D6));
    expect(palette.primaryText, isNot(palette.background));
    expect(palette.border, isNot(palette.background));
  });

  testWidgets('light and dark themes expose their correct palettes',
      (tester) async {
    for (final theme in [TradeXTheme.light, TradeXTheme.dark]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            final palette = TradeXPalette.of(context);
            expect(
              palette.background,
              theme.brightness == Brightness.light
                  ? TradeXPalette.light.background
                  : TradeXPalette.dark.background,
            );
            return const SizedBox.shrink();
          },
        ),
      ));
    }
  });
}
