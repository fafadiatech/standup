import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/pantry_catalog_item.dart';
import '../../data/models/snack_request_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Handles all pantry-related HTTP calls against the ERPNext backend.
class PantryService {
  PantryService(this._authService);

  final AuthService _authService;

  /// Returns all active pantry catalog items ordered by type then name.
  ///
  /// Throws a [String] error message on failure.
  Future<List<PantryCatalogItem>> getPantryCatalog() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getPantryCatalog}',
    );

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['items'] as List<dynamic>;
      return list
          .map((e) => PantryCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, fallback: 'Failed to load pantry catalog.');
  }

  /// Returns the current employee's snack requests, newest first.
  ///
  /// Throws a [String] error message on failure.
  Future<List<SnackRequestModel>> getMySnackRequests() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getMySnackRequests}',
    );

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['requests'] as List<dynamic>;
      return list
          .map((e) => SnackRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, fallback: 'Failed to load snack requests.');
  }

  /// Returns all snack requests (pantry staff only), optionally filtered by status.
  ///
  /// Throws a [String] error message on failure.
  Future<List<SnackRequestModel>> getAllSnackRequests({String? status}) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final queryParams = status != null ? {'status': status} : <String, String>{};
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getAllSnackRequests}',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['requests'] as List<dynamic>;
      return list
          .map((e) => SnackRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, fallback: 'Failed to load all snack requests.');
  }

  /// Submits a new snack request for the current employee.
  ///
  /// Returns the server-assigned request ID on success.
  /// Throws a [String] error message on failure.
  Future<String> createSnackRequest({
    required List<SnackRequestLineItem> items,
    SnackRequestLocation? location,
    String? notes,
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.createSnackRequest}',
    );

    final bodyMap = <String, String>{
      'items': jsonEncode(items.map((i) => i.toJson()).toList()),
      if (location != null) 'location': location.label,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await http
        .post(
          uri,
          headers: {..._headers(authHeader), 'Content-Type': 'application/json'},
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 20));

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = responseBody['message'] as Map<String, dynamic>;
      return payload['id'] as String;
    }

    throw _extractError(responseBody, fallback: 'Failed to submit snack request.');
  }

  /// Pantry staff accepts a pending request.
  ///
  /// Throws a [String] error message on failure.
  Future<void> acceptSnackRequest(String requestId) async {
    await _postAction(
      endpoint: ApiConstants.acceptSnackRequest,
      body: {'request_id': requestId},
      fallbackError: 'Failed to accept request.',
    );
  }

  /// Pantry staff rejects a pending request with a reason.
  ///
  /// Throws a [String] error message on failure.
  Future<void> rejectSnackRequest(String requestId, String reason) async {
    await _postAction(
      endpoint: ApiConstants.rejectSnackRequest,
      body: {'request_id': requestId, 'rejection_reason': reason},
      fallbackError: 'Failed to reject request.',
    );
  }

  /// Pantry staff marks an accepted request as completed.
  ///
  /// Throws a [String] error message on failure.
  Future<void> completeSnackRequest(String requestId) async {
    await _postAction(
      endpoint: ApiConstants.completeSnackRequest,
      body: {'request_id': requestId},
      fallbackError: 'Failed to complete request.',
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _postAction({
    required String endpoint,
    required Map<String, String> body,
    required String fallbackError,
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final response = await http
        .post(
          uri,
          headers: {..._headers(authHeader), 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw _extractError(responseBody, fallback: fallbackError);
    }
  }

  Map<String, String> _headers(String authHeader) => {
        'Host': ApiConstants.frappeSiteName,
        'Authorization': authHeader,
      };

  String _extractError(Map<String, dynamic> body, {required String fallback}) {
    final serverMessages = body['_server_messages'] as String?;
    if (serverMessages != null) {
      try {
        final messages = jsonDecode(serverMessages) as List<dynamic>;
        if (messages.isNotEmpty) {
          final first = jsonDecode(messages.first as String) as Map;
          return (first['message'] as String?) ?? fallback;
        }
      } catch (_) {}
    }
    final exception = body['exception'] as String?;
    if (exception != null) {
      final parts = exception.split(': ');
      if (parts.length > 1) return parts.sublist(1).join(': ').trim();
    }
    return fallback;
  }
}
