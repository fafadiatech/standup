import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/meeting_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/celebration_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Fetches Weekly Meetings and Upcoming Events from the backend.
class HomeService {
  HomeService(this._authService);

  final AuthService _authService;

  /// Returns all active Weekly Meeting records, ordered by team name.
  ///
  /// Throws a [String] error message on failure.
  Future<List<MeetingModel>> getWeeklyMeetings() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getWeeklyMeetings}',
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
      final list = payload['meetings'] as List<dynamic>;
      return list
          .map((e) => MeetingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load weekly meetings.');
  }

  /// Returns active Upcoming Events on or after today, ordered by date.
  ///
  /// Throws a [String] error message on failure.
  Future<List<EventModel>> getUpcomingEvents() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getUpcomingEvents}',
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
      final list = payload['events'] as List<dynamic>;
      return list
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load upcoming events.');
  }

  /// Returns active employees with a birthday in the current month.
  ///
  /// Throws a [String] error message on failure.
  Future<List<CelebrationModel>> getBirthdays() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getBirthdays}',
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
      final list = payload['birthdays'] as List<dynamic>;
      return list
          .map((e) => CelebrationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load birthdays.');
  }

  /// Returns active employees with a work anniversary in the current month.
  ///
  /// Throws a [String] error message on failure.
  Future<List<CelebrationModel>> getWorkAnniversaries() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getWorkAnniversaries}',
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
      final list = payload['anniversaries'] as List<dynamic>;
      return list
          .map((e) => CelebrationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load work anniversaries.');
  }

  String _extractError(Map<String, dynamic> body, String fallback) {
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
