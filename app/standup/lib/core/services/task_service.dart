import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/task_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class TaskService {
  TaskService(this._authService);

  final AuthService _authService;

  /// Returns all Standup Task records for the current employee.
  ///
  /// Throws a [String] error message on failure.
  Future<List<TaskModel>> getTasks() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getTasks}');

    final response = await http
        .get(uri, headers: {
          'Host': ApiConstants.frappeSiteName,
          'Authorization': authHeader,
        })
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      final list = payload['tasks'] as List<dynamic>;
      return list
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw _extractError(body, 'Failed to load tasks.');
  }

  /// Creates a new task on the server and returns the server-assigned task ID.
  ///
  /// Throws a [String] error message on failure.
  Future<String> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    required String relatedDocument,
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createTask}');

    final response = await http
        .post(
          uri,
          headers: {
            'Host': ApiConstants.frappeSiteName,
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'title': title,
            'description': description,
            'priority': _priorityToString(priority),
            'due_date': '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
            'related_document': relatedDocument,
          },
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = body['message'] as Map<String, dynamic>;
      return payload['id'] as String;
    }

    throw _extractError(body, 'Failed to create task.');
  }

  static String _priorityToString(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent: return 'urgent';
      case TaskPriority.high:   return 'high';
      case TaskPriority.low:    return 'low';
      case TaskPriority.medium: return 'medium';
    }
  }

  /// Updates the status of a task on the server (fire-and-forget safe).
  ///
  /// Throws a [String] error message on failure.
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.updateTaskStatus}',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Host': ApiConstants.frappeSiteName,
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'task_id': taskId,
            'status': _statusToString(status),
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw _extractError(body, 'Failed to update task status.');
    }
  }

  /// Returns all Activity Type names from ERPNext, sorted alphabetically.
  ///
  /// Throws a [String] error message on failure.
  Future<List<String>> getActivityTypes() async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getActivityTypes}',
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
      return (payload['activity_types'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    }

    throw _extractError(body, 'Failed to load activity types.');
  }

  /// Logs time for a task by creating or appending to an ERPNext Timesheet.
  ///
  /// Both timer-based and manual entries use this method.
  /// Returns the server-assigned Timesheet ID on success.
  /// Throws a [String] error message on failure.
  Future<String> logTime({
    required String taskId,
    required DateTime fromTime,
    required DateTime toTime,
    required double hours,
    String? activityType,
    String? notes,
  }) async {
    final authHeader = await _authService.authHeader();
    if (authHeader == null) throw 'Not authenticated.';

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logTime}');

    String fmtDateTime(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    final body = <String, String>{
      'task_id': taskId,
      'from_time': fmtDateTime(fromTime),
      'to_time': fmtDateTime(toTime),
      'hours': hours.toStringAsFixed(2),
      if (activityType != null && activityType.isNotEmpty) 'activity_type': activityType,
      if (notes != null && notes.isNotEmpty) 'description': notes,
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Host': ApiConstants.frappeSiteName,
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final payload = responseBody['message'] as Map<String, dynamic>;
      return payload['id'] as String;
    }

    throw _extractError(responseBody, 'Failed to log time.');
  }

  static String _statusToString(TaskStatus s) {
    switch (s) {
      case TaskStatus.inProgress: return 'in_progress';
      case TaskStatus.paused:     return 'paused';
      case TaskStatus.completed:  return 'completed';
      case TaskStatus.overdue:    return 'overdue';
      case TaskStatus.todo:       return 'todo';
    }
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
