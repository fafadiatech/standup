import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/leave_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Handles all leave-related HTTP calls against the ERPNext backend.
class LeaveService {
  LeaveService(this._authService);

  final AuthService _authService;

  /// Returns all active leave type names sorted alphabetically.
  ///
  /// Throws a [String] error message on failure.
  Future<List<String>> getLeaveTypes() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getLeaveTypes}',
    );

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      return (payload['leave_types'] as List<dynamic>).cast<String>();
    }

    throw _extractError(body, fallback: 'Failed to load leave types.');
  }

  /// Returns the employee's leave balance for the current calendar year.
  ///
  /// Throws a [String] error message on failure.
  Future<List<LeaveBalance>> getLeaveBalance() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getLeaveBalance}',
    );

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['balances'] as List<dynamic>;
      return list
          .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, fallback: 'Failed to load leave balance.');
  }

  /// Returns the most recent 50 leave applications for the current employee.
  ///
  /// Throws a [String] error message on failure.
  Future<List<LeaveRecord>> getLeaveHistory() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getLeaveHistory}',
    );

    final response = await http
        .get(uri, headers: _headers(authHeader))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['records'] as List<dynamic>;
      return list
          .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, fallback: 'Failed to load leave history.');
  }

  /// Submits a new leave application.
  ///
  /// Returns the server-assigned application ID on success.
  /// Throws a [String] error message on failure.
  Future<String> applyLeave({
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    String? reason,
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.applyLeave}',
    );

    final body = <String, String>{
      'leave_type': leaveType,
      'from_date': _fmtDate(fromDate),
      'to_date': _fmtDate(toDate),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    final response = await http
        .post(
          uri,
          headers: {..._headers(authHeader), 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = responseBody['message'] as Map<String, dynamic>;
      return payload['id'] as String;
    }

    throw _extractError(responseBody, fallback: 'Failed to submit leave application.');
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _headers(String authHeader) => {
        'Host': ApiConstants.frappeSiteName,
        'Authorization': authHeader,
      };

  String _fmtDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
