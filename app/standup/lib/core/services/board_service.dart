import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/leaderboard_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Fetches Board screen data (leaderboard & Employee of the Month) from the backend.
class BoardService {
  BoardService(this._authService);

  final AuthService _authService;

  /// Returns employees ranked by energy points, highest first.
  ///
  /// Throws a [String] error message on failure.
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getLeaderboard}?limit=$limit',
    );

    final response = await http
        .get(uri, headers: {
          'Host': ApiConstants.frappeSiteName,
          'Authorization': authHeader,
        })
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['leaderboard'] as List<dynamic>;
      return list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body);
  }

  /// Returns the current active Employee of the Month, or `null` if none.
  ///
  /// Throws a [String] error message on failure.
  Future<EmployeeOfMonth?> getEmployeeOfMonth() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getEmployeeOfMonth}',
    );

    final response = await http
        .get(uri, headers: {
          'Host': ApiConstants.frappeSiteName,
          'Authorization': authHeader,
        })
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final data = payload['employee_of_month'];
      if (data == null) return null;
      return EmployeeOfMonth.fromJson(data as Map<String, dynamic>);
    }

    throw _extractError(body);
  }

  String _extractError(Map<String, dynamic> body) {
    final serverMessages = body['_server_messages'] as String?;
    if (serverMessages != null) {
      try {
        final messages = jsonDecode(serverMessages) as List<dynamic>;
        if (messages.isNotEmpty) {
          final first = jsonDecode(messages.first as String) as Map;
          return (first['message'] as String?) ?? 'Failed to load board data.';
        }
      } catch (_) {}
    }
    final exception = body['exception'] as String?;
    if (exception != null) {
      final parts = exception.split(': ');
      if (parts.length > 1) return parts.sublist(1).join(': ').trim();
    }
    return 'Failed to load board data.';
  }
}
