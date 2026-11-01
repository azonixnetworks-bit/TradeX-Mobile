import '../../../../core/profile/pending_financial_form_store.dart';
import '../../domain/repositories/withdrawal_draft_store.dart';

class WithdrawalDraftStoreImpl implements WithdrawalDraftStore {
  WithdrawalDraftStoreImpl([PendingFinancialFormStore? store])
    : _store = store ?? PendingFinancialFormStore();

  final PendingFinancialFormStore _store;

  @override
  Future<PendingFinancialFormDraft?> readWithdrawal() =>
      _store.readWithdrawal();

  @override
  Future<void> writeWithdrawal(PendingFinancialFormDraft value) =>
      _store.writeWithdrawal(value);

  @override
  Future<void> clearWithdrawal() => _store.clearWithdrawal();
}
