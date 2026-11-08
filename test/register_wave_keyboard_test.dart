import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/presentation/register_screen.dart';

void main() {
  testWidgets('register background wave stays anchored when keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegisterScreen(
          onBack: () {},
          onSignIn: () {},
          onNext: ({
            required name,
            required email,
            required password,
            required passwordConfirmation,
          }) async {},
        ),
      ),
    );
    await tester.pump();

    final waveFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/security_ui/layered_cream_wave_footer.png',
      description: 'registration fixed bottom wave',
    );
    expect(waveFinder, findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isFalse,
    );

    final bottomBeforeKeyboard = tester.getBottomLeft(waveFinder).dy;

    // Simulate the device keyboard. The form gains scroll padding but the
    // decorative layer must not move up with the keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 310);
    await tester.pump();

    final bottomWithKeyboard = tester.getBottomLeft(waveFinder).dy;
    expect(bottomWithKeyboard, closeTo(bottomBeforeKeyboard, 0.1));
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
