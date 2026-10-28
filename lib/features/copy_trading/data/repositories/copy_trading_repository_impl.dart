import '../../domain/entities/copy_trading_entities.dart';
import '../../domain/repositories/copy_trading_repository.dart';
import '../datasources/copy_trading_intent_store.dart';
import '../datasources/copy_trading_remote_data_source.dart';
import '../models/copy_trading_models.dart';

final class CopyTradingRepositoryImpl implements CopyTradingRepository {
  const CopyTradingRepositoryImpl(this._remote, this._intentStore);

  final CopyTradingRemoteDataSource _remote;
  final CopyTradingIntentStore _intentStore;

  @override
  Future<CopyTradingDashboard> bootstrap() async =>
      CopyTradingDashboardModel.fromJson(await _remote.bootstrap()).toEntity();

  @override
  Future<List<CopyTradingBrokerMarket>> brokers() async =>
      (await _remote.brokers())
          .map(CopyTradingBrokerMarketModel.fromJson)
          .where((item) => item.brokerMarketUuid.isNotEmpty)
          .map((item) => item.toEntity())
          .toList(growable: false);

  @override
  Future<CopyTradingOnboardingIntent> openBrokerAccount(
    CopyTradingBrokerMarket broker,
  ) async {
    if (broker.brokerMarketUuid.isEmpty) {
      throw StateError('Broker market identifier is unavailable.');
    }
    final json = await _remote.openBrokerAccount(broker.brokerMarketUuid);
    await _intentStore.write(broker.brokerMarketUuid, json);
    return CopyTradingOnboardingIntentModel.fromJson(json).toEntity();
  }

  @override
  Future<CopyTradingOnboardingIntent?> pendingIntent(String marketId) async {
    final json = await _intentStore.read(marketId);
    return json == null
        ? null
        : CopyTradingOnboardingIntentModel.fromJson(json).toEntity();
  }

  @override
  Future<CopyTradingAccount> submitBrokerAccount({
    required String marketId,
    required String accountNumber,
  }) async {
    final intent = await _intentStore.read(marketId);
    final intentUuid = intent?['onboarding_intent_uuid']?.toString();
    if (intentUuid == null || intentUuid.isEmpty) {
      throw StateError(
        'Open this broker through the TradeX partner action before submitting the account.',
      );
    }
    final json = await _remote.submitBrokerAccount(
      intentUuid: intentUuid,
      accountNumber: accountNumber,
    );
    await _intentStore.delete(marketId);
    return CopyTradingAccountModel.fromJson(json).toEntity();
  }

  @override
  Future<CopyTradingAccount> resubmitBrokerAccount({
    required String accountId,
    required String accountNumber,
  }) async => CopyTradingAccountModel.fromJson(
    await _remote.resubmitBrokerAccount(
      accountId: accountId,
      accountNumber: accountNumber,
    ),
  ).toEntity();

  @override
  Future<CopyTradingActivation> activation(String accountId) async =>
      CopyTradingActivationModel.fromJson(await _remote.activation(accountId))
          .toEntity();

  @override
  Future<CopyTradingLogoBytes> brokerLogo(String url) =>
      _remote.brokerLogo(url);
}
