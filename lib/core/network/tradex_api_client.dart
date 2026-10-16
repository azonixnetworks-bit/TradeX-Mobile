import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../auth/secure_session_store.dart';
import '../config/tradex_api_config.dart';
import '../device/device_identity.dart';
import 'api_exception.dart';
import 'app_messenger.dart';

class TradeXApiClient {
  TradeXApiClient(this._sessionStore, this._deviceIdentity, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: TradeXApiConfig.baseUrl,
              connectTimeout: TradeXApiConfig.requestTimeout,
              sendTimeout: TradeXApiConfig.requestTimeout,
              receiveTimeout: TradeXApiConfig.requestTimeout,
              responseType: ResponseType.json,
              validateStatus: (_) => true,
            ),
          );

  final SecureSessionStore _sessionStore;
  final DeviceIdentity _deviceIdentity;
  final Dio _dio;

  Future<AuthSession>? _refreshInFlight;

  Future<Map<String, dynamic>> publicPost(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    method: 'POST',
    path: path,
    body: body,
    authenticated: false,
    retryAfterRefresh: false,
  );

  Future<Map<String, dynamic>> getJson(String path) => _send(
    method: 'GET',
    path: path,
    authenticated: true,
    retryAfterRefresh: true,
  );

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    method: 'POST',
    path: path,
    body: body,
    authenticated: true,
    retryAfterRefresh: true,
  );

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
          message: 'Your TradeX session has ended. Please sign in again.',
          statusCode: 401,
          code: 'SESSION_MISSING',
        );
      }

      if (session.accessTokenExpired) {
        session = await refreshSession();
      }
    }

    final response = await _request(
      method: method,
      path: path,
      body: body,
      accessToken: session?.accessToken,
    );

    if (authenticated && response.statusCode == 401 && retryAfterRefresh) {
      try {
        await refreshSession(force: true);
      } on ApiException catch (error) {
        if (error.shouldClearSession) await _sessionStore.clearSession();
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

  Future<Response<dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );
    } on DioException catch (error) {
      if (_isNoInternetError(error)) {
        AppMessenger.showNoInternetConnection();
        throw const ApiException(
          message:
              'No internet connection. Connect your internet and try again.',
          code: 'NO_INTERNET',
        );
      }

      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const ApiException(
          message: 'TradeX server took too long to respond. Please try again.',
          code: 'REQUEST_TIMEOUT',
        );
      }

      throw const ApiException(
        message: 'Unable to connect to TradeX. Please try again.',
      );
    }
  }

  bool _isNoInternetError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.error is SocketException;
  }

  Future<AuthSession> refreshSession({bool force = false}) async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final operation = _performRefresh(force: force);
    _refreshInFlight = operation;

    try {
      return await operation;
    } finally {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    }
  }

  Future<AuthSession> _performRefresh({required bool force}) async {
    final current = await _sessionStore.readSession();

    if (current == null) {
      throw const ApiException(
        message: 'Your TradeX session has ended. Please sign in again.',
        statusCode: 401,
        code: 'SESSION_MISSING',
      );
    }

    if (!force && !current.accessTokenExpired) return current;

    if (current.refreshTokenExpired) {
      await _sessionStore.clearSession();
      throw const ApiException(
        message: 'Your TradeX session expired. Please sign in again.',
        statusCode: 401,
        code: 'REFRESH_TOKEN_EXPIRED',
      );
    }

    final device = await _deviceIdentity.load();
    final response = await _request(
      method: 'POST',
      path: '/api/v1/auth/refresh',
      body: <String, dynamic>{
        'refresh_token': current.refreshToken,
        'installation_id': device.installationId,
      },
    );

    Map<String, dynamic> decoded;
    try {
      decoded = _decodeResponse(response);
    } on ApiException catch (error) {
      if (error.shouldClearSession) await _sessionStore.clearSession();
      rethrow;
    }

    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final now = DateTime.now();
    final refreshed = current.copyWith(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      accessExpiresAt: now.add(
        Duration(seconds: (data['expires_in'] as num).toInt()),
      ),
      refreshExpiresAt: now.add(
        Duration(seconds: (data['refresh_expires_in'] as num).toInt()),
      ),
      sessionUuid: data['session_uuid'] as String,
    );

    await _sessionStore.writeSession(refreshed);
    return refreshed;
  }

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    final payload = _payloadFrom(response.data);
    final statusCode = response.statusCode ?? 500;

    if (statusCode >= 200 && statusCode < 300) return payload;

    var message = 'TradeX request failed. Please try again.';
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
    if (validationErrors.isNotEmpty &&
        validationErrors.values.first.isNotEmpty) {
      message = validationErrors.values.first.first;
    }

    throw ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      validationErrors: validationErrors.isEmpty ? null : validationErrors,
    );
  }

  Map<String, dynamic> _payloadFrom(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Map<String, List<String>> _extractValidationErrors(Object? rawErrors) {
    if (rawErrors is! Map) return const {};

    final result = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      final value = entry.value;
      result[entry.key.toString()] = value is List
          ? value.map((item) => item.toString()).toList()
          : value == null
          ? <String>[]
          : <String>[value.toString()];
    }
    return result;
  }
}
