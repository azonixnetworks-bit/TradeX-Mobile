import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/auth/models/password_recovery_session.dart';
import 'package:tradex_mobile/features/auth/models/registration_session.dart';

void main() {
  test('registration session parses the Laravel registration contract', () {
    final session = RegistrationSession.fromJson(
      <String, dynamic>{
        'registration_id': '11111111-1111-4111-8111-111111111111',
        'registration_token':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'expires_at': '2026-10-14T10:00:00+00:00',
      },
    );

    expect(
      session.id,
      '11111111-1111-4111-8111-111111111111',
    );
    expect(session.token.length, 64);
  });

  test('TOTP setup parses the Laravel provisioning contract', () {
    final setup = RegistrationTotpSetup.fromJson(
      <String, dynamic>{
        'secret': 'ABCDEFGHIJKLMNOP',
        'otpauth_uri':
            'otpauth://totp/TradeX%20OS:test@example.com?secret=ABCDEFGHIJKLMNOP',
        'issuer': 'TradeX OS',
        'account_name': 'test@example.com',
        'digits': 6,
        'period_seconds': 30,
      },
    );

    expect(setup.issuer, 'TradeX OS');
    expect(setup.digits, 6);
    expect(setup.periodSeconds, 30);
  });

  test('password recovery session parses the Laravel recovery contract', () {
    final session = PasswordRecoverySession.fromJson(
      <String, dynamic>{
        'recovery_id': '22222222-2222-4222-8222-222222222222',
        'recovery_token':
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      },
    );

    expect(
      session.id,
      '22222222-2222-4222-8222-222222222222',
    );
    expect(session.token.length, 64);
  });
}
