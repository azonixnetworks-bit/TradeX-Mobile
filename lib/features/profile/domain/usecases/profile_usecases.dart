import '../repositories/withdrawal_draft_store.dart';

class ClearWithdrawalDraft {
  const ClearWithdrawalDraft(this.store);
  final WithdrawalDraftStore store;
  Future<void> call() => store.clearWithdrawal();
}
