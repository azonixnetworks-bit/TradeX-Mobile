import '../../core/network/tradex_api_client.dart';
import 'data/unavailable_investment_repository.dart';
import 'domain/investment_repository.dart';

final class InvestmentDependencies {
  InvestmentDependencies(TradeXApiClient apiClient)
    : repository = const UnavailableInvestmentRepository();

  final InvestmentRepository repository;
}
