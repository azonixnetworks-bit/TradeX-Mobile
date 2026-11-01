import 'package:local_auth/local_auth.dart';

import '../../../../core/auth/secure_session_store.dart';
import '../../domain/services/quick_unlock_service.dart';

class QuickUnlockServiceImpl implements QuickUnlockService {
  QuickUnlockServiceImpl(this._store, [LocalAuthentication? localAuth])
    : _localAuth = localAuth ?? LocalAuthentication();

  final SecureSessionStore _store;
  final LocalAuthentication _localAuth;

  @override
  Future<String> biometricLabel() async {
    final available = await _localAuth.getAvailableBiometrics();
    if (available.contains(BiometricType.face)) return 'Face ID';
    if (available.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (available.contains(BiometricType.strong)) return 'Biometrics';
    return 'Biometrics';
  }

  @override
  Future<bool> authenticate(String reason) async {
    final available =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    if (!available) return false;
    return _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  @override
  Future<QuickUnlockPinOutcome> verifyPin(String pin) async {
    final result = await _store.verifyQuickUnlockPin(pin);
    return switch (result) {
      QuickUnlockPinResult.success => QuickUnlockPinOutcome.success,
      QuickUnlockPinResult.failed => QuickUnlockPinOutcome.failed,
      QuickUnlockPinResult.locked => QuickUnlockPinOutcome.locked,
      QuickUnlockPinResult.unavailable => QuickUnlockPinOutcome.unavailable,
    };
  }

  @override
  Future<bool> hasShownSetupPrompt() => _store.hasShownQuickUnlockSetupPrompt();

  @override
  Future<void> markSetupPromptShown() =>
      _store.markQuickUnlockSetupPromptShown();
}
