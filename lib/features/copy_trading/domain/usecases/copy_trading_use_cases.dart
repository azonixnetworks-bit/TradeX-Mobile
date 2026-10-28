import '../../../../core/usecases/use_case.dart';
import '../entities/copy_trading_entities.dart';
import '../repositories/copy_trading_repository.dart';

final class CopyTradingUseCases {
  CopyTradingUseCases(CopyTradingRepository repository)
    : getDashboard = GetCopyTradingDashboard(repository),
      getBrokers = GetCopyTradingBrokers(repository),
      openBrokerAccount = OpenCopyTradingBrokerAccount(repository),
      getPendingIntent = GetCopyTradingPendingIntent(repository),
      submitBrokerAccount = SubmitCopyTradingBrokerAccount(repository),
      resubmitBrokerAccount = ResubmitCopyTradingBrokerAccount(repository),
      getActivation = GetCopyTradingActivation(repository),
      loadBrokerLogo = LoadCopyTradingBrokerLogo(repository);

  final GetCopyTradingDashboard getDashboard;
  final GetCopyTradingBrokers getBrokers;
  final OpenCopyTradingBrokerAccount openBrokerAccount;
  final GetCopyTradingPendingIntent getPendingIntent;
  final SubmitCopyTradingBrokerAccount submitBrokerAccount;
  final ResubmitCopyTradingBrokerAccount resubmitBrokerAccount;
  final GetCopyTradingActivation getActivation;
  final LoadCopyTradingBrokerLogo loadBrokerLogo;
}

final class GetCopyTradingDashboard
    implements UseCase<CopyTradingDashboard, NoParams> {
  const GetCopyTradingDashboard(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingDashboard> call(NoParams input) => _repository.bootstrap();
}

final class GetCopyTradingBrokers
    implements UseCase<List<CopyTradingBrokerMarket>, NoParams> {
  const GetCopyTradingBrokers(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<List<CopyTradingBrokerMarket>> call(NoParams input) =>
      _repository.brokers();
}

final class OpenCopyTradingBrokerAccount
    implements UseCase<CopyTradingOnboardingIntent, CopyTradingBrokerMarket> {
  const OpenCopyTradingBrokerAccount(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingOnboardingIntent> call(CopyTradingBrokerMarket input) =>
      _repository.openBrokerAccount(input);
}

final class GetCopyTradingPendingIntent
    implements UseCase<CopyTradingOnboardingIntent?, String> {
  const GetCopyTradingPendingIntent(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingOnboardingIntent?> call(String input) =>
      _repository.pendingIntent(input);
}

final class SubmitCopyTradingBrokerAccount
    implements UseCase<CopyTradingAccount, SubmitCopyTradingAccountParams> {
  const SubmitCopyTradingBrokerAccount(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingAccount> call(SubmitCopyTradingAccountParams input) =>
      _repository.submitBrokerAccount(
        marketId: input.marketId,
        accountNumber: input.accountNumber,
      );
}

final class ResubmitCopyTradingBrokerAccount
    implements UseCase<CopyTradingAccount, ResubmitCopyTradingAccountParams> {
  const ResubmitCopyTradingBrokerAccount(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingAccount> call(ResubmitCopyTradingAccountParams input) =>
      _repository.resubmitBrokerAccount(
        accountId: input.accountId,
        accountNumber: input.accountNumber,
      );
}

final class GetCopyTradingActivation
    implements UseCase<CopyTradingActivation, String> {
  const GetCopyTradingActivation(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingActivation> call(String input) =>
      _repository.activation(input);
}

final class LoadCopyTradingBrokerLogo
    implements UseCase<CopyTradingLogoBytes, String> {
  const LoadCopyTradingBrokerLogo(this._repository);
  final CopyTradingRepository _repository;

  @override
  Future<CopyTradingLogoBytes> call(String input) =>
      _repository.brokerLogo(input);
}

class SubmitCopyTradingAccountParams {
  const SubmitCopyTradingAccountParams({
    required this.marketId,
    required this.accountNumber,
  });
  final String marketId;
  final String accountNumber;
}

class ResubmitCopyTradingAccountParams {
  const ResubmitCopyTradingAccountParams({
    required this.accountId,
    required this.accountNumber,
  });
  final String accountId;
  final String accountNumber;
}
