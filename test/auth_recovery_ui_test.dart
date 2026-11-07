import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/registration_language_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/widgets/otp_verification_screen.dart';

void main() {
  void useNarrowPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('language selection preserves the selected language callback', (
    tester,
  ) async {
    useNarrowPhone(tester);
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: RegistrationLanguageScreen(
          onBack: () {},
          onContinue: (value) async => selected = value,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Tamil'));
    await tester.scrollUntilVisible(
      find.text('Continue'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(selected, 'ta');
    expect(tester.takeException(), isNull);
  });

  testWidgets('email verification keeps the real eight-digit code', (
    tester,
  ) async {
    useNarrowPhone(tester);
    String? verifiedCode;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: OtpVerificationScreen(
          title: 'Verify Your Email',
          subtitle: 'We sent a code to the registered email.',
          codeLength: 8,
          initialCooldownSeconds: 0,
          onVerify: (value) async => verifiedCode = value,
          onResend: () async {},
          onBack: () {},
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      await tester.enterText(fields.at(index), '${index + 1}${index + 1}');
    }
    await tester.ensureVisible(find.text('Verify Code'));
    await tester.tap(find.text('Verify Code'));
    await tester.pump();

    expect(verifiedCode, '11223344');
    expect(tester.takeException(), isNull);
  });

  testWidgets('email verification accepts a full pasted code', (tester) async {
    useNarrowPhone(tester);
    String? verifiedCode;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: OtpVerificationScreen(
          title: 'Verify Your Email',
          subtitle: 'We sent a code to the registered email.',
          codeLength: 8,
          initialCooldownSeconds: 0,
          onVerify: (value) async => verifiedCode = value,
          onResend: () async {},
          onBack: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '01234567');
    await tester.pump();
    expect(verifiedCode, isNull);

    await tester.ensureVisible(find.text('Verify Code'));
    await tester.tap(find.text('Verify Code'));
    await tester.pump();

    expect(verifiedCode, '01234567');
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password submits both registered recovery identifiers', (
    tester,
  ) async {
    useNarrowPhone(tester);
    String? submittedEmail;
    String? submittedMobile;
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.light,
        home: ForgotPasswordScreen(
          onBack: () {},
          onSubmit: ({required email, required whatsappNumber}) async {
            submittedEmail = email;
            submittedMobile = whatsappNumber;
          },
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'person@example.com');
    await tester.enterText(fields.at(1), '+94771234567');
    await tester.ensureVisible(find.text('Send Code'));
    await tester.tap(find.text('Send Code'));
    await tester.pump();

    expect(submittedEmail, 'person@example.com');
    expect(submittedMobile, '+94771234567');
    expect(tester.takeException(), isNull);
  });
}
