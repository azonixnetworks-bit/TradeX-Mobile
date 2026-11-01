import 'repositories/learn_repository_impl.dart';

export '../domain/repositories/learn_repository.dart' show JsonMap;

class LearnRepository extends LearnRepositoryImpl {
  const LearnRepository(super.apiClient);
}
