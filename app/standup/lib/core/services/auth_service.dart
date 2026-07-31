import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';
import '../constants/api_constants.dart';

/// Handles all authentication-related HTTP calls and secure token storage.
///
/// Authentication flow:
///   1. [login] posts credentials → receives api_key + api_secret.
///   2. Tokens are stored in [FlutterSecureStorage].
///   3. Every subsequent request must include
///      `Authorization: token <api_key>:<api_secret>`.
///   4. [logout] calls the server to invalidate the token pair, then
///      clears local storage.
///   5. On app restart, [tryRestoreSession] calls `/me` with stored
///      credentials; if valid, the session is silently restored.
class AuthService {
  AuthService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Authenticates [email] + [password] against the Frappe backend.
  /// Stores the returned token pair in secure storage and returns a
  /// [UserModel] built from the server profile.
  ///
  /// Throws a [String] error message on failure.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.mobileLogin}'),
          headers: {..._baseHeaders, 'Content-Type': 'application/json'},
          body: jsonEncode({'usr': email, 'pwd': password}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      // Frappe wraps whitelist return values under the 'message' key.
      final payload = body['message'] as Map<String, dynamic>;
      await _storeTokens(
        apiKey: payload['api_key'] as String,
        apiSecret: payload['api_secret'] as String,
      );
      return UserModel.fromJson(payload['user'] as Map<String, dynamic>);
    }

    throw _extractError(body);
  }

  /// Calls the server logout endpoint to invalidate the token pair, then
  /// removes credentials from secure storage.
  Future<void> logout() async {
    final header = await _authHeader();
    if (header != null) {
      try {
        await http
            .post(
              Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
              headers: {..._baseHeaders, 'Authorization': header},
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Best-effort server logout; always clear local storage.
      }
    }
    await _clearTokens();
  }

  /// Tries to restore a previous session using stored credentials.
  /// Returns the [UserModel] on success, or `null` if no valid session exists.
  Future<UserModel?> tryRestoreSession() async {
    final header = await _authHeader();
    if (header == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
            headers: {..._baseHeaders, 'Authorization': header},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final payload = body['message'] as Map<String, dynamic>;
        return UserModel.fromJson(payload['user'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Network unavailable or token invalid — fall through.
    }

    await _clearTokens();
    return null;
  }

  /// Returns the `Authorization` header value for authenticated requests,
  /// or `null` when no credentials are stored.
  Future<String?> authHeader() => _authHeader();

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Base headers sent with every request.
  /// The Host header tells Frappe's nginx proxy which site to route to.
  Map<String, String> get _baseHeaders => {
        'Host': ApiConstants.frappeSiteName,
      };

  Future<void> _storeTokens({
    required String apiKey,
    required String apiSecret,
  }) async {
    await Future.wait([
      _storage.write(key: ApiConstants.keyApiKey, value: apiKey),
      _storage.write(key: ApiConstants.keyApiSecret, value: apiSecret),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: ApiConstants.keyApiKey),
      _storage.delete(key: ApiConstants.keyApiSecret),
    ]);
  }

  Future<String?> _authHeader() async {
    final apiKey = await _storage.read(key: ApiConstants.keyApiKey);
    final apiSecret = await _storage.read(key: ApiConstants.keyApiSecret);
    if (apiKey == null || apiSecret == null) return null;
    return 'token $apiKey:$apiSecret';
  }

  /// Extracts a human-readable error message from a Frappe error response.
  String _extractError(Map<String, dynamic> body) {
    // Frappe sends server messages as a JSON-encoded string inside a list.
    final serverMessages = body['_server_messages'] as String?;
    if (serverMessages != null) {
      try {
        final messages = jsonDecode(serverMessages) as List<dynamic>;
        if (messages.isNotEmpty) {
          final first = jsonDecode(messages.first as String) as Map;
          return (first['message'] as String?) ?? 'Login failed.';
        }
      } catch (_) {}
    }
    // Fall back to the exception string if present.
    final exception = body['exception'] as String?;
    if (exception != null) {
      // Strip the Python class prefix, e.g. "frappe.exceptions.AuthenticationError: foo" → "foo"
      final parts = exception.split(': ');
      if (parts.length > 1) return parts.sublist(1).join(': ').trim();
    }
    return 'Invalid credentials. Please try again.';
  }
}
