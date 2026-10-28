/// A single application action with one input and one output.
///
/// Feature domain layers implement this contract without depending on Flutter
/// or infrastructure details.
abstract interface class UseCase<Output, Input> {
  Future<Output> call(Input input);
}

/// Input for use cases that do not require parameters.
final class NoParams {
  const NoParams();
}
