import '../repositories/learn_repository.dart';

final class LoadLearnOverview {
  const LoadLearnOverview(this._repository);
  final LearnRepository _repository;
  Future<JsonMap> call() => _repository.overview();
}
