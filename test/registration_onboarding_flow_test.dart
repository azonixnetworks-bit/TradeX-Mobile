import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/presentation/registration_details_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/registration_pending_dashboard_screen.dart';

void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('valid referral shows green confirmation after debounce', (tester) async {
    usePhone(tester);
    var validations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegistrationDetailsScreen(
          onBack: () {},
          onContinue: ({required countryCode, required phone, required referralCode}) async {},
          onCheckReferralCode: (code) async {
            validations++;
            return code == 'VALID2026';
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(2), 'valid2026');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();
    expect(validations, 1);
    expect(find.text('Valid referral code'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('referral field is optional and empty is not validated', (tester) async {
    usePhone(tester);
    var validations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegistrationDetailsScreen(
          onBack: () {},
          onContinue: ({required countryCode, required phone, required referralCode}) async {},
          onCheckReferralCode: (_) async {
            validations++;
            return false;
          },
        ),
      ),
    );

    expect(find.text('Referral Code (Optional)'), findsOneWidget);
    expect(find.text('Referral code is required.'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    expect(validations, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid referral is shown and cannot be treated as valid', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegistrationDetailsScreen(
          onBack: () {},
          onContinue: ({required countryCode, required phone, required referralCode}) async {
            fail('Invalid referral should not continue registration.');
          },
          onCheckReferralCode: (_) async => false,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(2), 'INVALID2026');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();
    expect(find.text('Referral code is invalid or unavailable.'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending dashboard shows verification dialog and keeps Later option', (tester) async {
    usePhone(tester);
    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegistrationPendingDashboardScreen(
          email: 'pending@example.test',
          onVerifyNow: () => verified = true,
          onExit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Complete Your Verification'), findsOneWidget);
    await tester.tap(find.text('Complete Later'));
    await tester.pumpAndSettle();
    expect(find.text('TradeX Dashboard'), findsOneWidget);
    expect(verified, false);
    // Let framework report the full render diagnostic if the dialog overflows.
  });
}
