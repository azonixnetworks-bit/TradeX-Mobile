abstract interface class SessionSecurityState {
  int get backgroundLockSeconds;
  DateTime? get lastBackgroundedAt;
  Future<void> markBackgrounded(DateTime value);
  Future<void> clearBackgroundedAt();
  Future<void> setBackgroundLockSeconds(int seconds);
  Future<void> resetDashboardTab();
  Future<void> clearPendingWithdrawal();
}
