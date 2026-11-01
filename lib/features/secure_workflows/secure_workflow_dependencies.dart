import 'data/services/secure_workflow_platform_impl.dart';
import 'domain/services/secure_workflow_platform.dart';

abstract final class SecureWorkflowDependencies {
  static void configure() {
    SecureWorkflowPlatformRegistry.configure(
      const SecureWorkflowPlatformImpl(),
    );
  }
}
