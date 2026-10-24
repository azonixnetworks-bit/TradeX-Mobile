import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../auth/auth_session.dart';
import '../auth/secure_session_store.dart';
import '../config/tradex_api_config.dart';
import '../device/device_identity.dart';
import '../offline/offline_cache_store.dart';
import 'api_exception.dart';
import 'app_messenger.dart';

class TradeXApiClient {
  TradeXApiClient(
    this._sessionStore,
    this._deviceIdentity, {
    Dio? dio,
    OfflineCacheStore? offlineStore,
  }) : _dio = dio ?? _createPinnedDio(),
       _offlineStore = offlineStore ?? OfflineCacheStore();

  final SecureSessionStore _sessionStore;
  final DeviceIdentity _deviceIdentity;
  final Dio _dio;
  final OfflineCacheStore _offlineStore;

  Future<AuthSession>? _refreshInFlight;
  Future<void>? _offlineSyncInFlight;

  Future<bool> checkReachability() async {
    try {
      await _dio.get<dynamic>(
        '/api/v1/bootstrap',
        options: Options(
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<String?> currentAccountStorageKey() async {
    final session = await _sessionStore.readSession();
    return session == null ? null : _accountKey(session);
  }

  Future<void> clearOfflineData() async {
    final session = await _sessionStore.readSession();
    if (session != null) {
      await _offlineStore.clearAccount(_accountKey(session));
    }
  }

  Future<void> syncOfflineMutations() async {
    final existing = _offlineSyncInFlight;
    if (existing != null) return existing;
    final operation = _performOfflineMutationSync();
    _offlineSyncInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_offlineSyncInFlight, operation)) {
        _offlineSyncInFlight = null;
      }
    }
  }

  Future<void> _performOfflineMutationSync() async {
    final session = await _sessionStore.readSession();
    if (session == null) return;
    final accountKey = _accountKey(session);
    final queued = await _offlineStore.queued(accountKey);
    for (final mutation in queued) {
      try {
        await _send(
          method: mutation.method,
          path: mutation.path,
          body: mutation.body,
          authenticated: true,
          retryAfterRefresh: true,
          allowOfflineQueue: false,
        );
        await _offlineStore.removeQueued(accountKey, mutation.key);
      } on ApiException catch (error) {
        if (_isTransportFailure(error)) break;
        if ((error.statusCode ?? 500) >= 400 &&
            (error.statusCode ?? 500) < 500 &&
            error.statusCode != 408 &&
            error.statusCode != 429) {
          await _offlineStore.removeQueued(accountKey, mutation.key);
          continue;
        }
        break;
      }
    }
  }

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

  /// Returns an account-scoped disk copy immediately when one exists.
  ///
  /// This is intentionally different from the normal network-first GET. It is
  /// used by data-heavy screens that must open instantly and remain available
  /// offline. A manual refresh can still call [getJson] to fetch the server.
  Future<Map<String, dynamic>> getJsonCacheFirst(String path) async {
    final session = await _sessionStore.readSession();
    if (session != null && _isCacheable(path)) {
      final entry = await _offlineStore.get(
        accountKey: _accountKey(session),
        requestKey: path,
      );
      if (entry != null) {
        return <String, dynamic>{
          ...entry.payload,
          '_offline_cache': <String, dynamic>{
            'cached_at': entry.cachedAt.toIso8601String(),
            'expires_at': entry.expiresAt.toIso8601String(),
            'is_stale': entry.isExpired,
            'cache_first': true,
          },
        };
      }
    }

    final response = await getJson(path);
    if (session != null && _isCacheable(path)) {
      await _offlineStore.put(
        accountKey: _accountKey(session),
        requestKey: path,
        payload: response,
        maxAge: _cacheDuration(path),
      );
    }
    return response;
  }

  Future<void> cacheJson(String path, Map<String, dynamic> payload) async {
    final session = await _sessionStore.readSession();
    if (session == null || !_isCacheable(path)) return;
    await _offlineStore.put(
      accountKey: _accountKey(session),
      requestKey: path,
      payload: payload,
      maxAge: _cacheDuration(path),
    );
  }

  Future<Uint8List> getBytes(String path) async {
    AuthSession? session = await _sessionStore.readSession();
    if (session == null) {
      throw const ApiException(
        message: 'Your TradeX session has ended. Please sign in again.',
        statusCode: 401,
        code: 'SESSION_MISSING',
      );
    }

    if (session.accessTokenExpired) session = await refreshSession();

    var response = await _request(
      method: 'GET',
      path: path,
      accessToken: session.accessToken,
      responseType: ResponseType.bytes,
    );

    if (response.statusCode == 401) {
      session = await refreshSession(force: true);
      response = await _request(
        method: 'GET',
        path: path,
        accessToken: session.accessToken,
        responseType: ResponseType.bytes,
      );
    }

    final statusCode = response.statusCode ?? 500;
    if (statusCode < 200 || statusCode >= 300 || response.data is! List<int>) {
      throw const ApiException(
        message: 'Trade idea chart is unavailable right now.',
      );
    }

    return Uint8List.fromList(response.data as List<int>);
  }

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

  Future<Map<String, dynamic>> postJsonWithHeaders(
    String path,
    Map<String, dynamic> body,
    Map<String, String> headers,
  ) => _send(
    method: 'POST',
    path: path,
    body: body,
    authenticated: true,
    retryAfterRefresh: true,
    headers: headers,
  );

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, dynamic> fields,
    Map<String, String> filePaths,
  ) async {
    var session = await _sessionStore.readSession();
    if (session == null) {
      throw const ApiException(
        message: 'Your TradeX session has ended. Please sign in again.',
        statusCode: 401,
        code: 'SESSION_MISSING',
      );
    }
    if (session.accessTokenExpired) session = await refreshSession();

    Future<Response<dynamic>> send(AuthSession active) async {
      final data = FormData.fromMap(fields);
      for (final entry in filePaths.entries) {
        data.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value,
              filename: entry.value.split(RegExp(r'[\\/]')).last,
            ),
          ),
        );
      }
      try {
        return await _dio.post<dynamic>(
          path,
          data: data,
          options: Options(
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer ${active.accessToken}',
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
        throw const ApiException(
          message: 'Unable to upload the selected files. Please try again.',
        );
      }
    }

    var response = await send(session);
    if (response.statusCode == 401) {
      session = await refreshSession(force: true);
      response = await send(session);
    }
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    method: 'PUT',
    path: path,
    body: body,
    authenticated: true,
    retryAfterRefresh: true,
  );

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    method: 'PATCH',
    path: path,
    body: body,
    authenticated: true,
    retryAfterRefresh: true,
  );

  Future<Map<String, dynamic>> deleteJson(String path) => _send(
    method: 'DELETE',
    path: path,
    authenticated: true,
    retryAfterRefresh: true,
  );

  static Dio _createPinnedDio() {
    final baseUrl = TradeXApiConfig.baseUrl;
    final host = Uri.parse(baseUrl).host;
    final pins = TradeXApiConfig.certificatePinsFor(host);
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: TradeXApiConfig.requestTimeout,
        sendTimeout: TradeXApiConfig.requestTimeout,
        receiveTimeout: TradeXApiConfig.requestTimeout,
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ),
    );

    if (pins.isNotEmpty) {
      client.httpClientAdapter = IOHttpClientAdapter(
        validateCertificate: (certificate, certificateHost, _) {
          if (certificate == null || certificateHost != host) return false;
          return pins.contains(sha256.convert(certificate.der).toString());
        },
      );
    }

    return client;
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authenticated,
    required bool retryAfterRefresh,
    Map<String, String>? headers,
    bool allowOfflineQueue = true,
  }) async {
    AuthSession? session;
    try {
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
        headers: headers,
      );

      if (authenticated && response.statusCode == 401 && retryAfterRefresh) {
        try {
          await refreshSession(force: true);
        } on ApiException catch (error) {
          if (error.shouldClearSession) await _sessionStore.clearSession();
          rethrow;
        }

        return await _send(
          method: method,
          path: path,
          body: body,
          authenticated: true,
          retryAfterRefresh: false,
          headers: headers,
          allowOfflineQueue: allowOfflineQueue,
        );
      }

      final decoded = _decodeResponse(response);
      if (method == 'GET' && session != null && _isCacheable(path)) {
        unawaited(
          _offlineStore
              .put(
                accountKey: _accountKey(session),
                requestKey: path,
                payload: decoded,
                maxAge: _cacheDuration(path),
              )
              .catchError((_) {}),
        );
      }
      return decoded;
    } on ApiException catch (error) {
      if (session == null || !_isTransportFailure(error)) rethrow;
      final accountKey = _accountKey(session);
      if (method == 'GET' && _isCacheable(path)) {
        final entry = await _offlineStore.get(
          accountKey: accountKey,
          requestKey: path,
        );
        if (entry != null) {
          return <String, dynamic>{
            ...entry.payload,
            '_offline_cache': <String, dynamic>{
              'cached_at': entry.cachedAt.toIso8601String(),
              'expires_at': entry.expiresAt.toIso8601String(),
              'is_stale': entry.isExpired,
            },
          };
        }
      }
      if (allowOfflineQueue && _isSafeOfflineMutation(method, path)) {
        await _offlineStore.enqueue(
          accountKey: accountKey,
          method: method,
          path: path,
          body: body,
        );
        return <String, dynamic>{
          'success': true,
          'data': const <String, dynamic>{'queued_offline': true},
          '_offline_queued': true,
        };
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? accessToken,
    ResponseType? responseType,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.request<dynamic>(
        path,
        data: body,
        options: Options(
          method: method,
          responseType: responseType,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            ...?headers,
          },
        ),
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.badCertificate) {
        throw const ApiException(
          message: 'TradeX could not verify the server security certificate. Please update the app or contact support.',
          code: 'CERTIFICATE_PIN_MISMATCH',
        );
      }

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
        code: 'CONNECTION_ERROR',
      );
    }
  }

  bool _isNoInternetError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.error is SocketException;
  }

  bool _isTransportFailure(ApiException error) =>
      error.code == 'NO_INTERNET' ||
      error.code == 'REQUEST_TIMEOUT' ||
      error.code == 'CONNECTION_ERROR';

  String _accountKey(AuthSession session) {
    final user = session.user;
    for (final key in const ['uuid', 'id', 'email', 'referral_code']) {
      final value = user[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return '$key:$value';
    }
    return 'session:${session.sessionUuid}';
  }

  bool _isCacheable(String value) {
    final path = Uri.parse(value).path;
    return path == '/api/v1/languages' ||
        path == '/api/v1/products' ||
        path.startsWith('/api/v1/dashboard') ||
        path.startsWith('/api/v1/economic-news') ||
        path.startsWith('/api/v1/screener') ||
        path.startsWith('/api/v1/education/') ||
        path.startsWith('/api/v1/trade-journal') ||
        path.startsWith('/api/v1/trading-routine') ||
        path.startsWith('/api/v1/legal/');
  }

  Duration _cacheDuration(String value) {
    final path = Uri.parse(value).path;
    if (path.startsWith('/api/v1/economic-news') ||
        path.startsWith('/api/v1/screener') ||
        path.startsWith('/api/v1/dashboard')) {
      return const Duration(minutes: 5);
    }
    if (path.startsWith('/api/v1/education/')) {
      return const Duration(hours: 12);
    }
    if (path.startsWith('/api/v1/trade-journal') ||
        path.startsWith('/api/v1/trading-routine')) {
      return const Duration(hours: 24);
    }
    return const Duration(days: 7);
  }

  bool _isSafeOfflineMutation(String method, String value) {
    final path = Uri.parse(value).path;
    if (method == 'PATCH' &&
        RegExp(r'^/api/v1/education/lessons/[^/]+/progress$').hasMatch(path)) {
      return true;
    }
    if ((method == 'PUT' || method == 'DELETE') &&
        RegExp(r'^/api/v1/education/lessons/[^/]+/bookmark$').hasMatch(path)) {
      return true;
    }
    if (method == 'PATCH' &&
        RegExp(r'^/api/v1/trade-journal/[^/]+$').hasMatch(path)) {
      return true;
    }
    return method == 'PUT' && path == '/api/v1/trading-routine/preferences';
  }

  Future<AuthSession> refreshSession({
    bool force = false,
    String? quickUnlockTotpCode,
  }) async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final operation = _performRefresh(
      force: force,
      quickUnlockTotpCode: quickUnlockTotpCode,
    );
    _refreshInFlight = operation;

    try {
      return await operation;
    } finally {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    }
  }

  Future<AuthSession> _performRefresh({
    required bool force,
    String? quickUnlockTotpCode,
  }) async {
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
        if (quickUnlockTotpCode?.trim().isNotEmpty == true)
          'quick_unlock_totp_code': quickUnlockTotpCode!.trim(),
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
