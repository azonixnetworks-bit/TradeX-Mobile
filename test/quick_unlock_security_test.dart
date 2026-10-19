import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/device_credential_service.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
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
}
