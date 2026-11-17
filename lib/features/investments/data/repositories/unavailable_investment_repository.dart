import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

import 'dart:typed_data';

final class UnavailableInvestmentRepository implements InvestmentRepository {
  const UnavailableInvestmentRepository();

  @override
  Future<InvestmentDashboard> loadDashboard({bool refresh = false}) =>
      Future<InvestmentDashboard>.error(const InvestmentFeatureUnavailable());

  @override
  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  }) => Future<InvestmentDashboard>.error(const InvestmentFeatureUnavailable());

  @override
  Future<CustomerInvestment> createApplication({
    required double amount,
    required int periodYears,
    required int reviewIntervalMonths,
  }) => Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<void> submitDeposit({
    required String investmentId,
    required String transactionId,
    String? senderAddress,
  }) => Future.error(const InvestmentFeatureUnavailable());

  @override
  Future<Uint8List> downloadAgreement(String investmentId) =>
      Future.error(const InvestmentFeatureUnavailable());
}
