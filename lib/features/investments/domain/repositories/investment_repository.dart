import 'dart:typed_data';

import '../entities/investment_entities.dart';

abstract interface class InvestmentPreferencesRepository {
  Future<bool> hideValues();
  Future<void> setHideValues(bool value);
}

abstract interface class InvestmentRepository {
  Future<InvestmentDashboard> loadDashboard({bool refresh = false});

  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  });

  Future<CustomerInvestment> createApplication({
    required double amount,
    required int periodYears,
    required int reviewIntervalMonths,
  });

  Future<void> submitDeposit({
    required String investmentId,
    required String transactionId,
    String? senderAddress,
  });

  Future<Uint8List> downloadAgreement(String investmentId);
}

class InvestmentFeatureUnavailable implements Exception {
  const InvestmentFeatureUnavailable([
    this.message =
        'Investments mobile access is not available from the server yet.',
  ]);

  final String message;

  @override
  String toString() => message;
}
