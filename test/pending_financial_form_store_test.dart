import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/auth_session.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/profile/pending_financial_form_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final now = DateTime.utc(2026, 10, 20, 6);

  Future<void> writeSession(String sessionUuid) =>
      SecureSessionStore(storage: storage).writeSession(
        AuthSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          accessExpiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          sessionUuid: sessionUuid,
          user: const {'id': 7},
        ),
      );

  PendingFinancialFormDraft draft() => PendingFinancialFormDraft(
    method: 'localBank',
    accountHolder: 'Test Customer',
    bankName: 'Bank of Ceylon',
    bankBranch: 'Gampaha Branch',
    accountNumber: '1234567890',
    accountNumberConfirmation: '1234567890',
    awaitingTotp: true,
    updatedAt: now,
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('restores the active-session bank draft and TOTP step', () async {
    await writeSession('session-a');
    final store = PendingFinancialFormStore(storage: storage, clock: () => now);

    await store.writeWithdrawal(draft());
    final restored = await store.readWithdrawal();

    expect(restored, isNotNull);
    expect(restored!.sessionUuid, 'session-a');
    expect(restored.bankName, 'Bank of Ceylon');
    expect(restored.accountNumber, '1234567890');
    expect(restored.awaitingTotp, isTrue);
  });

  test('expired bank drafts are removed', () async {
    await writeSession('session-a');
    await PendingFinancialFormStore(
      storage: storage,
      clock: () => now,
    ).writeWithdrawal(draft());

    final restored = await PendingFinancialFormStore(
      storage: storage,
      clock: () => now.add(const Duration(minutes: 16)),
    ).readWithdrawal();

    expect(restored, isNull);
  });

  test('draft from another authenticated session is never restored', () async {
    await writeSession('session-a');
    final store = PendingFinancialFormStore(storage: storage, clock: () => now);
    await store.writeWithdrawal(draft());
    await writeSession('session-b');

    expect(await store.readWithdrawal(), isNull);
  });
}
