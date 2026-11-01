import '../../core/domain/api_gateway.dart';
import 'data/repositories/withdrawal_draft_store_impl.dart';
import 'domain/repositories/withdrawal_draft_store.dart';

class ProfileDependencies {
  ProfileDependencies(
    this.gateway, {
    WithdrawalDraftStore? withdrawalDraftStore,
  }) : withdrawalDraftStore =
           withdrawalDraftStore ?? WithdrawalDraftStoreImpl();

  final ApiGateway gateway;
  final WithdrawalDraftStore withdrawalDraftStore;
}

abstract final class ProfileDependenciesRegistry {
  static ProfileDependencies? _current;
  static ProfileDependencies get current =>
      _current ??
      (throw StateError('Profile dependencies are not configured.'));
  static void configure(ProfileDependencies value) => _current = value;
}
