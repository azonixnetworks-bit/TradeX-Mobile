import '../../core/network/tradex_api_client.dart';
import 'data/datasources/investment_preferences_data_source.dart';
import 'data/repositories/investment_preferences_repository_impl.dart';
import 'data/repositories/api_investment_repository.dart';
import 'domain/repositories/investment_repository.dart';

final class InvestmentDependencies {
  InvestmentDependencies(TradeXApiClient apiClient)
    : repository = ApiInvestmentRepository(apiClient),
      preferencesRepository = InvestmentPreferencesRepositoryImpl(
        SharedPreferencesInvestmentPreferencesDataSource(),
      );

  final InvestmentRepository repository;
  final InvestmentPreferencesRepository preferencesRepository;
}
