import 'dart:convert';

/// A validated message emitted by the embedded replay terminal.
class ReplayTerminalEvent {
  const ReplayTerminalEvent({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;

  static ReplayTerminalEvent? tryParse(String raw) {
    if (raw.length > 8192) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['type'] is! String ||
        decoded['payload'] is! Map<String, dynamic>) {
      return null;
    }

    return ReplayTerminalEvent(
      type: decoded['type'] as String,
      payload: decoded['payload'] as Map<String, dynamic>,
    );
  }

  static String encodeCommand(Map<String, Object?> command) =>
      jsonEncode(command);
}
