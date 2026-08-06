import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/project_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ProjectService {
  ProjectService(this._authService);

  final AuthService _authService;

  /// Returns all active projects for the current employee.
  ///
  /// Throws a [String] error message on failure.
  Future<List<ProjectModel>> getProjects() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getProjects}');

    final response = await http
        .get(uri, headers: {
          'Host': ApiConstants.frappeSiteName,
          'Authorization': authHeader,
        })
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['projects'] as List<dynamic>;
      return list
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load projects.');
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
