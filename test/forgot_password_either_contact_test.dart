import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/auth/presentation/forgot_password_screen.dart';

void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapSend(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Send Code'));
    await tester.tap(find.text('Send Code'));
    await tester.pump();
  }

  testWidgets('email alone sends recovery request', (tester) async {
    usePhone(tester);
    String? sentEmail;
    String? sentPhone;
    await tester.pumpWidget(MaterialApp(
      theme: TradeXTheme.light,
      home: ForgotPasswordScreen(
        onBack: () {},
        onSubmit: ({required email, required whatsappNumber}) async {
          sentEmail = email;
          sentPhone = whatsappNumber;
        },
      ),
    ));

    await tester.enterText(find.byType(TextFormField).first, 'hello@example.com');
    await tapSend(tester);
    expect(sentEmail, 'hello@example.com');
    expect(sentPhone, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('WhatsApp alone sends recovery request', (tester) async {
    usePhone(tester);
    String? sentEmail;
    String? sentPhone;
    await tester.pumpWidget(MaterialApp(
      theme: TradeXTheme.light,
      home: ForgotPasswordScreen(
        onBack: () {},
        onSubmit: ({required email, required whatsappNumber}) async {
          sentEmail = email;
          sentPhone = whatsappNumber;
        },
      ),
    ));

    await tester.enterText(find.byType(TextFormField).last, '+94771234567');
    await tapSend(tester);
    expect(sentEmail, '');
    expect(sentPhone, '+94771234567');
    expect(tester.takeException(), isNull);
  });

  testWidgets('both blank prevents recovery request', (tester) async {
    usePhone(tester);
    var submitted = false;
    await tester.pumpWidget(MaterialApp(
      theme: TradeXTheme.light,
      home: ForgotPasswordScreen(
        onBack: () {},
        onSubmit: ({required email, required whatsappNumber}) async {
          submitted = true;
        },
      ),
    ));

    await tapSend(tester);
    expect(submitted, false);
    expect(find.text('Enter your email or WhatsApp number.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid supplied WhatsApp blocks submission even with email', (tester) async {
    usePhone(tester);
    var submitted = false;
    await tester.pumpWidget(MaterialApp(
      theme: TradeXTheme.light,
      home: ForgotPasswordScreen(
        onBack: () {},
        onSubmit: ({required email, required whatsappNumber}) async {
          submitted = true;
        },
      ),
    ));

    await tester.enterText(find.byType(TextFormField).first, 'hello@example.com');
    await tester.enterText(find.byType(TextFormField).last, '0771234567');
    await tapSend(tester);
    expect(submitted, false);
    expect(find.text('Use international format, for example +94771234567.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
