import '../../core/auth/secure_session_store.dart';
import '../../core/device/device_identity.dart';
import '../../core/network/tradex_api_client.dart';
import 'data/auth_repository.dart';
import 'data/password_recovery_repository.dart';
import 'data/registration_repository.dart';
import 'data/services/quick_unlock_service_impl.dart';
import 'data/services/session_security_state_impl.dart';
import 'domain/repositories/auth_repositories.dart';
import 'domain/services/quick_unlock_service.dart';
import 'domain/services/session_security_state.dart';

class AuthDependencies {
  AuthDependencies(
    TradeXApiClient apiClient,
    SecureSessionStore sessionStore,
    DeviceIdentity deviceIdentity,
  ) : authRepository = AuthRepository(apiClient, sessionStore, deviceIdentity),
      registrationRepository = RegistrationRepository(apiClient),
      passwordRecoveryRepository = PasswordRecoveryRepository(apiClient),
      quickUnlockService = QuickUnlockServiceImpl(sessionStore),
      securityState = const SessionSecurityStateImpl();

  final AuthRepositoryContract authRepository;
  final RegistrationRepositoryContract registrationRepository;
  final PasswordRecoveryRepositoryContract passwordRecoveryRepository;
  final QuickUnlockService quickUnlockService;
  final SessionSecurityState securityState;
}
