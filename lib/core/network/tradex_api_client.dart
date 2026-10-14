import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../auth/secure_session_store.dart';
import '../config/tradex_api_config.dart';
import '../device/device_identity.dart';
import 'api_exception.dart';

class TradeXApiClient {
  TradeXApiClient({
    required SecureSessionStore sessionStore,
    required DeviceIdentity deviceIdentity,
    http.Client? httpClient,
  }) : _sessionStore = sessionStore,
       _deviceIdentity = deviceIdentity,
       _http = httpClient ?? http.Client();

  final SecureSessionStore _sessionStore;
  final DeviceIdentity _deviceIdentity;
  final http.Client _http;

  Future<AuthSession>? _refreshInFlight;

  Future<Map<String, dynamic>> publicPost(
    String path,
    Map<String, dynamic> body,
  ) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      authenticated: false,
      retryAfterRefresh: false,
    );
  }

  Future<Map<String, dynamic>> getJson(String path) {
    return _send(
      method: 'GET',
      path: path,
      authenticated: true,
      retryAfterRefresh: true,
    );
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      authenticated: true,
      retryAfterRefresh: true,
    );
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authenticated,
    required bool retryAfterRefresh,
  }) async {
    AuthSession? session;

    if (authenticated) {
      session = await _sessionStore.readSession();

      if (session == null) {
        throw const ApiException(
          message:
              'Your TradeX session has ended. '
              'Please sign in again.',
          statusCode: 401,
          code: 'SESSION_MISSING',
        );
      }

      if (session.accessTokenExpired) {
        session = await refreshSession();
      }
    }

    final uri = Uri.parse('${TradeXApiConfig.baseUrl}$path');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };

    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _http
              .get(uri, headers: headers)
              .timeout(TradeXApiConfig.requestTimeout);
          break;

        case 'POST':
          response = await _http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const <String, dynamic>{}),
              )
              .timeout(TradeXApiConfig.requestTimeout);
          break;

        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const ApiException(
        message:
            'TradeX server took too long to respond. '
            'Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Unable to connect to TradeX. '
            'Check your internet connection.',
      );
    }

    if (authenticated && response.statusCode == 401 && retryAfterRefresh) {
      try {
        await refreshSession(force: true);
      } on ApiException catch (error) {
        if (error.shouldClearSession) {
          await _sessionStore.clearSession();
        }

        rethrow;
      }

      return _send(
        method: method,
        path: path,
        body: body,
        authenticated: true,
        retryAfterRefresh: false,
      );
    }

    return _decodeResponse(response);
  }

  Future<AuthSession> refreshSession({bool force = false}) async {
    final existing = _refreshInFlight;

    if (existing != null) {
      return existing;
    }

    final operation = _performRefresh(force: force);

    _refreshInFlight = operation;

    try {
      return await operation;
    } finally {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<AuthSession> _performRefresh({required bool force}) async {
    final current = await _sessionStore.readSession();

    if (current == null) {
      throw const ApiException(
        message:
            'Your TradeX session has ended. '
            'Please sign in again.',
        statusCode: 401,
        code: 'SESSION_MISSING',
      );
    }

    if (!force && !current.accessTokenExpired) {
      return current;
    }

    if (current.refreshTokenExpired) {
      await _sessionStore.clearSession();

      throw const ApiException(
        message:
            'Your TradeX session expired. '
            'Please sign in again.',
        statusCode: 401,
        code: 'REFRESH_TOKEN_EXPIRED',
      );
    }

    final device = await _deviceIdentity.load();

    final uri = Uri.parse(
      '${TradeXApiConfig.baseUrl}'
      '/api/v1/auth/refresh',
    );

    late http.Response response;

    try {
      response = await _http
          .post(
            uri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'refresh_token': current.refreshToken,
              'installation_id': device.installationId,
            }),
          )
          .timeout(TradeXApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException(message: 'TradeX session refresh timed out.');
    } catch (_) {
      throw const ApiException(
        message: 'Unable to refresh your TradeX session.',
      );
    }

    Map<String, dynamic> decoded;

    try {
      decoded = _decodeResponse(response);
    } on ApiException catch (error) {
      if (error.shouldClearSession) {
        await _sessionStore.clearSession();
      }

      rethrow;
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);

    final accessSeconds = (data['expires_in'] as num).toInt();

    final refreshSeconds = (data['refresh_expires_in'] as num).toInt();

    final now = DateTime.now();

    final refreshed = current.copyWith(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      accessExpiresAt: now.add(Duration(seconds: accessSeconds)),
      refreshExpiresAt: now.add(Duration(seconds: refreshSeconds)),
      sessionUuid: data['session_uuid'] as String,
    );

    await _sessionStore.writeSession(refreshed);

    return refreshed;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> payload = <String, dynamic>{};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Invalid/non JSON response handled below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    String message = 'TradeX request failed. Please try again.';

    String? code;

    final error = payload['error'];

    if (error is Map) {
      final errorMap = Map<String, dynamic>.from(error);

      final errorMessage = errorMap['message'];

      final errorCode = errorMap['code'];

      if (errorMessage is String && errorMessage.isNotEmpty) {
        message = errorMessage;
      }

      if (errorCode is String && errorCode.isNotEmpty) {
        code = errorCode;
      }
    }

    final topMessage = payload['message'];

    if (error is! Map && topMessage is String && topMessage.isNotEmpty) {
      message = topMessage;
    }

    final validationErrors = _extractValidationErrors(payload['errors']);

    if (validationErrors.isNotEmpty) {
      final firstMessages = validationErrors.values.first;

      if (firstMessages.isNotEmpty) {
        message = firstMessages.first;
      }
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      code: code,
      validationErrors: validationErrors.isEmpty ? null : validationErrors,
    );
  }

  Map<String, List<String>> _extractValidationErrors(Object? rawErrors) {
    if (rawErrors is! Map) {
      return const {};
    }

    final result = <String, List<String>>{};

    for (final entry in rawErrors.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is List) {
        result[key] = value.map((item) => item.toString()).toList();
      } else if (value != null) {
        result[key] = [value.toString()];
      }
    }

    return result;
  }
}
