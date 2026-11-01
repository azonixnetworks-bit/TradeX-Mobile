abstract final class SecureWorkflowPolicy {
  static bool isSixDigitTotp(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim());
}
