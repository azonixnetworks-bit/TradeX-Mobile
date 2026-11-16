import '../../core/network/tradex_api_client.dart';
import 'data/repositories/affiliate_repository_impl.dart';
import 'data/repositories/secure_referral_qr_cache.dart';
import 'domain/repositories/affiliate_repository.dart';
import 'domain/repositories/referral_qr_cache.dart';

final class AffiliateDependencies {
  AffiliateDependencies(TradeXApiClient apiClient)
    : repository = AffiliateRepositoryImpl(apiClient),
      referralQrCache = SecureReferralQrCache();
  final AffiliateRepository repository;
  final ReferralQrCache referralQrCache;
}
