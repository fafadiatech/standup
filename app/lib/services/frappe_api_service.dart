// lib/services/frappe_api_service.dart
//
// Central Dio client for all communication with the Frappe/ERPNext backend.
//
// Authentication scheme
// ─────────────────────
// Frappe's token-based auth (enabled for mobile) works as follows:
//   1. POST /api/method/standup.api.auth.mobile_login → api_key + api_secret
//   2. Store both values in flutter_secure_storage (AES-256 on Android,
//      Keychain on iOS).
//   3. Every subsequent request adds the header:
//        Authorization: token <api_key>:<api_secret>
//   This bypasses CSRF checks, which are not applicable to mobile clients.
//
// Error handling
// ──────────────
// Frappe returns errors as:
//   { "exc_type": "...", "exception": "...", "_server_messages": "..." }
// FrappeException wraps these into structured Dart exceptions.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

/// Swap for your production domain or load from --dart-define / .env
const String _kBaseUrl = 'http://localhost:8000';

const String _kKeyApiKey    = 'frappe_api_key';
const String _kKeyApiSecret = 'frappe_api_secret';

// ─── Exception ───────────────────────────────────────────────────────────────

class FrappeException implements Exception {
  final String    excType;
  final String    message;
  final int?      statusCode;
  final dynamic   raw;

  const FrappeException({
    required this.excType,
    required this.message,
    this.statusCode,
    this.raw,
  });

  @override
  String toString() => 'FrappeException[$excType]: $message';
}

// ─── Auth Credential Model ───────────────────────────────────────────────────

class FrappeCredentials {
  final String apiKey;
  final String apiSecret;

  const FrappeCredentials({required this.apiKey, required this.apiSecret});

  /// The value for the Authorization header.
  String get headerValue => 'token $apiKey:$apiSecret';
}

// ─── Service ─────────────────────────────────────────────────────────────────

class FrappeApiService {
  FrappeApiService._({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio     = dio,
        _storage = storage;

  final Dio                  _dio;
  final FlutterSecureStorage _storage;
  final Logger               _log = Logger();

  // ── Factory / Singleton ──────────────────────────────────────────────────

  static FrappeApiService? _instance;

  static FrappeApiService get instance {
    _instance ??= FrappeApiService._(
      dio:     _buildDio(),
      storage: const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    );
    return _instance!;
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl:        _kBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept':       'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
    ));
    return dio;
  }

  // ── Credential Storage ───────────────────────────────────────────────────

  Future<void> saveCredentials(FrappeCredentials creds) async {
    await Future.wait([
      _storage.write(key: _kKeyApiKey,    value: creds.apiKey),
      _storage.write(key: _kKeyApiSecret, value: creds.apiSecret),
    ]);
    // Inject the new token into Dio's default headers immediately.
    _dio.options.headers['Authorization'] = creds.headerValue;
  }

  Future<FrappeCredentials?> loadCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _kKeyApiKey),
      _storage.read(key: _kKeyApiSecret),
    ]);
    final key    = results[0];
    final secret = results[1];
    if (key == null || secret == null) return null;
    return FrappeCredentials(apiKey: key, apiSecret: secret);
  }

  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _kKeyApiKey),
      _storage.delete(key: _kKeyApiSecret),
    ]);
    _dio.options.headers.remove('Authorization');
  }

  // ── Auth API ─────────────────────────────────────────────────────────────

  /// Login and persist credentials. Returns the user profile map.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final resp = await _post(
      '/api/method/standup.api.auth.mobile_login',
      data: {'usr': username, 'pwd': password},
    );

    final creds = FrappeCredentials(
      apiKey:    resp['api_key']    as String,
      apiSecret: resp['api_secret'] as String,
    );
    await saveCredentials(creds);

    return resp['user'] as Map<String, dynamic>;
  }

  /// Fetch the current user's profile (also works as a token liveness check).
  Future<Map<String, dynamic>> me() async {
    final resp = await _get('/api/method/standup.api.auth.me');
    return resp['user'] as Map<String, dynamic>;
  }

  /// Logout: invalidates server-side token and clears local storage.
  Future<void> logout() async {
    try {
      await _post('/api/method/standup.api.auth.logout', data: {});
    } finally {
      await clearCredentials();
    }
  }

  /// Rotate the token pair.
  Future<FrappeCredentials> refreshToken() async {
    final resp = await _post(
      '/api/method/standup.api.auth.refresh_token',
      data: {},
    );
    final creds = FrappeCredentials(
      apiKey:    resp['api_key']    as String,
      apiSecret: resp['api_secret'] as String,
    );
    await saveCredentials(creds);
    return creds;
  }

  // ── Generic DocType CRUD ─────────────────────────────────────────────────

  /// Fetch a list of documents.
  /// [filters] follows the Frappe filter syntax:
  ///   e.g. [["StandupEntry", "owner", "=", "user@example.com"]]
  Future<List<Map<String, dynamic>>> getList(
    String doctype, {
    List<String>?  fields,
    List<dynamic>? filters,
    int            limit = 20,
    int            start = 0,
    String?        orderBy,
  }) async {
    final resp = await _get(
      '/api/resource/$doctype',
      queryParameters: {
        if (fields  != null) 'fields':  jsonEncode(fields),
        if (filters != null) 'filters': jsonEncode(filters),
        'limit_page_length': limit,
        'limit_start':       start,
        if (orderBy != null) 'order_by': orderBy,
      },
    );
    return (resp['data'] as List).cast<Map<String, dynamic>>();
  }

  /// Fetch a single document.
  Future<Map<String, dynamic>> getDoc(String doctype, String name) async {
    final resp = await _get('/api/resource/$doctype/$name');
    return resp['data'] as Map<String, dynamic>;
  }

  /// Create a document.
  Future<Map<String, dynamic>> createDoc(
    String doctype,
    Map<String, dynamic> data,
  ) async {
    final resp = await _post(
      '/api/resource/$doctype',
      data: {'doctype': doctype, ...data},
    );
    return resp['data'] as Map<String, dynamic>;
  }

  /// Update a document.
  Future<Map<String, dynamic>> updateDoc(
    String doctype,
    String name,
    Map<String, dynamic> data,
  ) async {
    final resp = await _put('/api/resource/$doctype/$name', data: data);
    return resp['data'] as Map<String, dynamic>;
  }

  /// Delete a document.
  Future<void> deleteDoc(String doctype, String name) async {
    await _delete('/api/resource/$doctype/$name');
  }

  // ── Low-level HTTP helpers ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
    return _unwrap(resp);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(path, data: data);
    return _unwrap(resp);
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final resp = await _dio.put<Map<String, dynamic>>(path, data: data);
    return _unwrap(resp);
  }

  Future<void> _delete(String path) async {
    final resp = await _dio.delete<Map<String, dynamic>>(path);
    _unwrap(resp);
  }

  /// Extract the `message` key Frappe wraps all responses in,
  /// or throw a [FrappeException] on error.
  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> resp) {
    final body = resp.data;
    if (body == null) {
      throw const FrappeException(
        excType: 'EmptyResponse',
        message: 'Server returned an empty body.',
      );
    }
    // Frappe wraps successful whitelist responses under "message".
    // Resource API responses use "data". Return the whole body so
    // callers can pick the right key themselves.
    return body;
  }
}

// ─── Auth Interceptor ────────────────────────────────────────────────────────

/// Reads the persisted token from secure storage and injects the
/// Authorization header on every request if credentials are available.
/// This runs once per request, so it naturally handles token refreshes
/// if [FrappeApiService.saveCredentials] was called between requests.
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions          options,
    RequestInterceptorHandler handler,
  ) async {
    // If the Authorization header is already set (e.g. by saveCredentials)
    // skip the storage read to avoid the async overhead on every call.
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    final results = await Future.wait([
      _storage.read(key: _kKeyApiKey),
      _storage.read(key: _kKeyApiSecret),
    ]);
    final key    = results[0];
    final secret = results[1];

    if (key != null && secret != null) {
      options.headers['Authorization'] = 'token $key:$secret';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final body       = err.response?.data;

    if (body is Map<String, dynamic>) {
      final excType = body['exc_type']  as String? ?? 'UnknownError';
      // _server_messages is a JSON-encoded list inside a string.
      String message = body['exception'] as String? ?? err.message ?? 'Unknown error';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: FrappeException(
            excType:    excType,
            message:    message,
            statusCode: statusCode,
            raw:        body,
          ),
          response: err.response,
          type:     err.type,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
