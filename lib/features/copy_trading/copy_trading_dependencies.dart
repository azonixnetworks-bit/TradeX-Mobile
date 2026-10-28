import '../../core/network/tradex_api_client.dart';
import 'data/datasources/copy_trading_intent_store.dart';
import 'data/datasources/copy_trading_remote_data_source.dart';
import 'data/repositories/copy_trading_repository_impl.dart';
import 'domain/usecases/copy_trading_use_cases.dart';

final class CopyTradingDependencies {
  CopyTradingDependencies(
    TradeXApiClient apiClient, {
    CopyTradingIntentStore? intentStore,
  }) : useCases = CopyTradingUseCases(
         CopyTradingRepositoryImpl(
           ApiCopyTradingRemoteDataSource(apiClient),
           intentStore ?? SecureCopyTradingIntentStore(apiClient),
         ),
       );

  final CopyTradingUseCases useCases;
}
