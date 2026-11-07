import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/presentation/welcome_screen.dart';

void main() {
  testWidgets('professional welcome screen fits a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: WelcomeScreen(
          onGetStarted: () => started = true,
          onSignIn: () {},
          onSkip: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn. Trade.\nGrow with TradeX.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Get Started'));
    expect(started, isTrue);
  });
}
