class PendingFinancialFormDraft {
  const PendingFinancialFormDraft({
    required this.method,
    required this.accountHolder,
    required this.bankName,
    required this.bankBranch,
    required this.accountNumber,
    required this.accountNumberConfirmation,
    required this.awaitingTotp,
    required this.updatedAt,
    this.sessionUuid = '',
  });

  final String method;
  final String accountHolder;
  final String bankName;
  final String bankBranch;
  final String accountNumber;
  final String accountNumberConfirmation;
  final bool awaitingTotp;
  final DateTime updatedAt;
  final String sessionUuid;

  PendingFinancialFormDraft copyWith({
    bool? awaitingTotp,
    DateTime? updatedAt,
    String? sessionUuid,
  }) => PendingFinancialFormDraft(
    method: method,
    accountHolder: accountHolder,
    bankName: bankName,
    bankBranch: bankBranch,
    accountNumber: accountNumber,
    accountNumberConfirmation: accountNumberConfirmation,
    awaitingTotp: awaitingTotp ?? this.awaitingTotp,
    updatedAt: updatedAt ?? this.updatedAt,
    sessionUuid: sessionUuid ?? this.sessionUuid,
  );
}
