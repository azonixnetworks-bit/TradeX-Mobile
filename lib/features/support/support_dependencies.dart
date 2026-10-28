import '../../core/network/tradex_api_client.dart';
import 'data/datasources/support_remote_data_source.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/usecases/support_use_cases.dart';

/// Composition root for the Support feature.
///
/// Infrastructure dependencies are assembled here so presentation remains
/// independent from API and data-layer implementations.
final class SupportDependencies {
  SupportDependencies(TradeXApiClient apiClient)
    : useCases = SupportUseCases(
        SupportRepositoryImpl(ApiSupportRemoteDataSource(apiClient)),
      );

  final SupportUseCases useCases;
}
