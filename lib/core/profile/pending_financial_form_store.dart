import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/secure_session_store.dart';

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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 1,
    'method': method,
    'account_holder': accountHolder,
    'bank_name': bankName,
    'bank_branch': bankBranch,
    'account_number': accountNumber,
    'account_number_confirmation': accountNumberConfirmation,
    'awaiting_totp': awaitingTotp,
    'updated_at': updatedAt.toIso8601String(),
    'session_uuid': sessionUuid,
  };

  factory PendingFinancialFormDraft.fromJson(Map<String, dynamic> json) {
    final updatedAt = DateTime.tryParse(json['updated_at']?.toString() ?? '');
    final sessionUuid = json['session_uuid']?.toString() ?? '';
    final method = json['method']?.toString() ?? '';
    if (json['version'] != 1 ||
        method.isEmpty ||
        updatedAt == null ||
        sessionUuid.isEmpty) {
      throw const FormatException('Invalid pending financial form draft.');
    }
    return PendingFinancialFormDraft(
      method: method,
      accountHolder: json['account_holder']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      bankBranch: json['bank_branch']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountNumberConfirmation:
          json['account_number_confirmation']?.toString() ?? '',
      awaitingTotp: json['awaiting_totp'] == true,
      updatedAt: updatedAt,
      sessionUuid: sessionUuid,
    );
  }
}

class PendingFinancialFormStore {
  PendingFinancialFormStore({
    FlutterSecureStorage? storage,
    DateTime Function()? clock,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _clock = clock ?? DateTime.now;

  static const _withdrawalKey = 'tradex.profile.withdrawal_draft.v1';
  static const _maximumAge = Duration(minutes: 15);

  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  Future<PendingFinancialFormDraft?> readWithdrawal() async {
    final raw = await _storage.read(key: _withdrawalKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      final draft = PendingFinancialFormDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final session = await SecureSessionStore(storage: _storage).readSession();
      final expired = _clock().difference(draft.updatedAt) > _maximumAge;
      if (session == null ||
          session.sessionUuid != draft.sessionUuid ||
          expired) {
        await clearWithdrawal();
        return null;
      }
      return draft;
    } catch (_) {
      await clearWithdrawal();
      return null;
    }
  }

  Future<void> writeWithdrawal(PendingFinancialFormDraft draft) async {
    final session = await SecureSessionStore(storage: _storage).readSession();
    if (session == null) return;
    final protectedDraft = draft.copyWith(
      sessionUuid: session.sessionUuid,
      updatedAt: _clock(),
    );
    await _storage.write(
      key: _withdrawalKey,
      value: jsonEncode(protectedDraft.toJson()),
    );
  }

  Future<void> clearWithdrawal() => _storage.delete(key: _withdrawalKey);
}
