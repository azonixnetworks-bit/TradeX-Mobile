import '../entities/pending_financial_form_draft.dart';

abstract interface class WithdrawalDraftStore {
  Future<PendingFinancialFormDraft?> readWithdrawal();
  Future<void> writeWithdrawal(PendingFinancialFormDraft value);
  Future<void> clearWithdrawal();
}
