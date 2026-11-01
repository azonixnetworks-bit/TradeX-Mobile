import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/profile/pending_financial_form_store.dart';
import '../../domain/services/session_security_state.dart';

class SessionSecurityStateImpl implements SessionSecurityState {
  const SessionSecurityStateImpl();

  @override
  int get backgroundLockSeconds =>
      AppPreferences.instance.quickUnlockBackgroundLockSeconds;

  @override
  DateTime? get lastBackgroundedAt =>
      AppPreferences.instance.lastBackgroundedAt;

  @override
  Future<void> markBackgrounded(DateTime value) =>
      AppPreferences.instance.markBackgrounded(value);

  @override
  Future<void> clearBackgroundedAt() =>
      AppPreferences.instance.clearBackgroundedAt();

  @override
  Future<void> setBackgroundLockSeconds(int seconds) =>
      AppPreferences.instance.setQuickUnlockBackgroundLockSeconds(seconds);

  @override
  Future<void> resetDashboardTab() =>
      AppPreferences.instance.setDashboardTab(0);

  @override
  Future<void> clearPendingWithdrawal() =>
      PendingFinancialFormStore().clearWithdrawal();
}
