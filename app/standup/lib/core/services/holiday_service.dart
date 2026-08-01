import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/holiday_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Fetches holiday data from the ERPNext "Holiday List" doctype.
class HolidayService {
  HolidayService(this._authService);

  final AuthService _authService;

  /// Returns all holidays from [listName] (default: "Public Holidays"),
  /// sorted ascending by date.
  ///
  /// Throws a [String] error message on failure.
  Future<List<HolidayModel>> getHolidays({
    String listName = 'Public Holidays',
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) {
      throw 'Not authenticated.';
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getHolidays}'
      '?list_name=${Uri.encodeComponent(listName)}',
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Host': ApiConstants.frappeSiteName,
            'Authorization': authHeader,
          },
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      // Frappe wraps whitelist return values under the 'message' key.
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['holidays'] as List<dynamic>;
      return list
          .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
          return (first['message'] as String?) ?? 'Failed to load holidays.';
        }
      } catch (_) {}
    }
    final exception = body['exception'] as String?;
    if (exception != null) {
      final parts = exception.split(': ');
      if (parts.length > 1) return parts.sublist(1).join(': ').trim();
    }
    return 'Failed to load holidays.';
  }
}
