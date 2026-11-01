enum QuickUnlockPinOutcome { success, failed, locked, unavailable }

abstract interface class QuickUnlockService {
  Future<String> biometricLabel();
  Future<bool> authenticate(String reason);
  Future<QuickUnlockPinOutcome> verifyPin(String pin);
  Future<bool> hasShownSetupPrompt();
  Future<void> markSetupPromptShown();
}

abstract final class QuickUnlockServiceRegistry {
  static QuickUnlockService? _current;
  static QuickUnlockService get current =>
      _current ?? (throw StateError('Quick unlock service is not configured.'));
  static void configure(QuickUnlockService service) => _current = service;
}
