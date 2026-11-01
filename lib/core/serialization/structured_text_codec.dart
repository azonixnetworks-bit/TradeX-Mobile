import 'dart:convert';

Object? decodeStructuredText(String value) => jsonDecode(value);

String encodeStructuredText(Object? value) => jsonEncode(value);
