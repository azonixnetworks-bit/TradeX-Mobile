import '../repositories/auth_repositories.dart';

class RestoreSession {
  const RestoreSession(this.repository);
  final AuthRepositoryContract repository;
  Future<Object?> call() => repository.restoreRememberedSession();
}
