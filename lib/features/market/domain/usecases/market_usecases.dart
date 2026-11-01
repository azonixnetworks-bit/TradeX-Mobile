import '../entities/crypto_market_entities.dart';
import '../repositories/crypto_market_repository.dart';

final class LoadCryptoMarket {
  const LoadCryptoMarket(this._repository);
  final CryptoMarketRepositoryContract _repository;
  Future<CryptoMarketSnapshot> call({
    required String segment,
    int page = 1,
    String search = '',
  }) => _repository.load(segment: segment, page: page, search: search);
}
