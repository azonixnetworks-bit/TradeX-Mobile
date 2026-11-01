import '../entities/investment_entities.dart';
import '../repositories/investment_repository.dart';

final class LoadInvestmentDashboard {
  const LoadInvestmentDashboard(this._repository);
  final InvestmentRepository _repository;
  Future<InvestmentDashboard> call({bool refresh = false}) =>
      _repository.loadDashboard(refresh: refresh);
}
