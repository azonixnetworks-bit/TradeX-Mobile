import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/device_credential_service.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/features/auth/presentation/login_screen.dart';
import 'package:tradex_mobile/features/auth/presentation/quick_unlock_screen.dart';

void main() {
  test(
    'quick-login signature message is canonical and account-device bound',
    () {
      expect(
        DeviceCredentialService.canonicalMessage(
          challengeId: 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA',
          credentialId: 'BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB',
          installationId: 'CCCCCCCC-CCCC-4CCC-8CCC-CCCCCCCCCCCC',
          nonce: 'server-nonce',
        ),
        'tradex-quick-login-v1\n'
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa\n'
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb\n'
        'cccccccc-cccc-4ccc-8ccc-cccccccccccc\n'
        'server-nonce',
      );
    },
  );

  test('legacy local enrollment without credential id is rejected', () {
    expect(
      () => QuickUnlockConfig.fromJson(<String, dynamic>{
        'method': 'PIN',
        'email': 'trader@example.test',
        'pin_salt': 'salt',
        'pin_hash': 'hash',
      }),
      throwsFormatException,
    );
  });

  test(
    'legacy biometric enrollment migrates to independent capability flags',
    () {
      final config = QuickUnlockConfig.fromJson(<String, dynamic>{
        'method': 'BIOMETRIC',
        'email': 'trader@example.test',
        'credential_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      });

      expect(config.hasBiometric, isTrue);
      expect(config.hasPasscode, isFalse);
      expect(config.toJson()['biometric_enabled'], isTrue);
      expect(config.toJson()['version'], 2);
    },
  );

  test(
    'combined enrollment exposes fingerprint and passcode independently',
    () {
      final config = QuickUnlockConfig.fromJson(<String, dynamic>{
        'version': 2,
        'method': 'BOTH',
        'email': 'trader@example.test',
        'credential_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'biometric_enabled': true,
        'pin_salt': 'salt',
        'pin_hash': 'hash',
      });

      expect(config.hasBiometric, isTrue);
      expect(config.hasPasscode, isTrue);
    },
  );

  testWidgets('passcode quick login shows exactly one enter-passcode field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuickUnlockScreen(
          config: const QuickUnlockConfig(
            method: 'PIN',
            email: 'trader@example.test',
            credentialId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            pinSalt: 'salt',
            pinHash: 'hash',
          ),
          sessionStore: SecureSessionStore(),
          onUnlocked: () async {},
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enter passcode'), findsOneWidget);
    expect(find.textContaining('Confirm'), findsNothing);
  });

  testWidgets(
    'remembered passcode login hides password and authenticator fields',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onBack: () {},
            onForgotPassword: () {},
            onCreateAccount: () {},
            quickUnlockConfig: const QuickUnlockConfig(
              method: 'PIN',
              email: 'trader@example.test',
              credentialId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              pinSalt: 'salt',
              pinHash: 'hash',
            ),
            onQuickUnlock: () async {},
            onLogin: ({
              required email,
              required password,
              totpCode,
              recoveryCode,
              quickUnlockMethod,
              quickUnlockPin,
            }) async {},
          ),
        ),
      );

      expect(find.text('Email Address'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Authenticator Code (6 digits)'), findsNothing);
      expect(find.text('Enter passcode'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );

  testWidgets(
    'remembered fingerprint login prompts and unlocks automatically once',
    (tester) async {
      var biometricPrompts = 0;
      var quickUnlocks = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onBack: () {},
            onForgotPassword: () {},
            onCreateAccount: () {},
            quickUnlockConfig: const QuickUnlockConfig(
              method: 'BIOMETRIC',
              email: 'trader@example.test',
              credentialId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            ),
            authenticateBiometric: () async {
              biometricPrompts += 1;
              return true;
            },
            onQuickUnlock: () async {
              quickUnlocks += 1;
            },
            onLogin: ({
              required email,
              required password,
              totpCode,
              recoveryCode,
              quickUnlockMethod,
              quickUnlockPin,
            }) async {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(biometricPrompts, 1);
      expect(quickUnlocks, 1);

      await tester.pump(const Duration(seconds: 1));

      expect(biometricPrompts, 1);
      expect(quickUnlocks, 1);
    },
  );
}
