import '../../core/network/tradex_api_client.dart';
import '../../core/offline/offline_cache_store.dart';
import 'data/datasources/funded_advisor_local_data_source.dart';
import 'data/datasources/funded_advisor_logo_store.dart';
import 'data/datasources/funded_advisor_remote_data_source.dart';
import 'data/repositories/funded_advisor_repository_impl.dart';
import 'domain/usecases/funded_advisor_use_cases.dart';

final class FundedAdvisorDependencies {
  FundedAdvisorDependencies(
    TradeXApiClient apiClient, {
    OfflineCacheStore? offlineCacheStore,
  }) : useCases = FundedAdvisorUseCases(
         FundedAdvisorRepositoryImpl(
           ApiFundedAdvisorRemoteDataSource(apiClient),
           DiskFundedAdvisorLocalDataSource(
             apiClient,
             offlineCacheStore ?? OfflineCacheStore(),
           ),
           DiskFundedAdvisorLogoStore(apiClient),
         ),
       );

  final FundedAdvisorUseCases useCases;
}
