import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

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
}
