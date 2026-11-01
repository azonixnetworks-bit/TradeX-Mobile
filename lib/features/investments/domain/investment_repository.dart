import 'investment_entities.dart';

abstract interface class InvestmentRepository {
  Future<InvestmentDashboard> loadDashboard({bool refresh = false});

  Future<InvestmentDashboard> loadInvestment(
    String investmentId, {
    bool refresh = false,
  });
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
