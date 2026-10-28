import '../entities/copy_trading_entities.dart';

abstract interface class CopyTradingRepository {
  Future<CopyTradingDashboard> bootstrap();
  Future<List<CopyTradingBrokerMarket>> brokers();
  Future<CopyTradingOnboardingIntent> openBrokerAccount(
    CopyTradingBrokerMarket broker,
  );
  Future<CopyTradingOnboardingIntent?> pendingIntent(String marketId);
  Future<CopyTradingAccount> submitBrokerAccount({
    required String marketId,
    required String accountNumber,
  });
  Future<CopyTradingAccount> resubmitBrokerAccount({
    required String accountId,
    required String accountNumber,
  });
  Future<CopyTradingActivation> activation(String accountId);
  Future<CopyTradingLogoBytes> brokerLogo(String url);
}
