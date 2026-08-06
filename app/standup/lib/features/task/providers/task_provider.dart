import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/time_log_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';

// ---------------------------------------------------------------------------
// Online/Offline status
// ---------------------------------------------------------------------------
final isOnlineProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Task state
// ---------------------------------------------------------------------------
class TaskState {
  final List<TaskModel> tasks;
  final String searchQuery;
  final String activeFilter;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const TaskState({
    required this.tasks,
    required this.searchQuery,
    required this.activeFilter,
    required this.isOnline,
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    String? searchQuery,
    String? activeFilter,
    bool? isOnline,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

bool _isOverdue(TaskModel t) {
  if (t.status == TaskStatus.overdue) return true;
  if (t.status == TaskStatus.completed) return false;
  return t.dueDate.isBefore(DateTime.now()) && !_isToday(t.dueDate);
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._service)
      : super(const TaskState(
          tasks: [],
          searchQuery: '',
          activeFilter: 'All',
          isOnline: true,
          isLoading: true,
        )) {
    loadTasks();
  }

  final TaskService _service;

  // --- Load from API ---

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _service.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Filtering helpers ---

  List<TaskModel> get _filteredTasks {
    List<TaskModel> tasks = state.tasks;

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      tasks = tasks.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.relatedDocument.toLowerCase().contains(q);
      }).toList();
    }

    switch (state.activeFilter) {
      case 'Today':
        tasks = tasks.where((t) => _isToday(t.dueDate)).toList();
      case 'High':
        tasks = tasks
            .where((t) =>
                t.priority == TaskPriority.high ||
                t.priority == TaskPriority.urgent)
            .toList();
      case 'In Progress':
        tasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
      case 'Completed':
        tasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
      default:
        break;
    }

    return tasks;
  }

  List<TaskModel> get overdueTasks =>
      _filteredTasks.where(_isOverdue).toList();

  List<TaskModel> get todayTasks => _filteredTasks.where((t) {
        return _isToday(t.dueDate) && !_isOverdue(t) && t.status != TaskStatus.completed;
      }).toList();

  List<TaskModel> get upcomingTasks => _filteredTasks.where((t) {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        return t.dueDate.isAfter(tomorrow.subtract(const Duration(seconds: 1))) &&
            t.status != TaskStatus.completed &&
            !_isOverdue(t);
      }).toList();

  List<TaskModel> get completedTasks =>
      _filteredTasks.where((t) => t.status == TaskStatus.completed).toList();

  // --- Mutation methods ---

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void toggleChecklist(String taskId, String itemId) {
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      final checklist = task.checklist.map((item) {
        if (item.id != itemId) return item;
        return item.copyWith(isCompleted: !item.isCompleted);
      }).toList();
      return task.copyWith(checklist: checklist);
    }).toList();
    state = state.copyWith(tasks: tasks);
  }

  void addTimeLog(String taskId, TimeLogModel log) {
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(timeLogs: [...task.timeLogs, log]);
    }).toList();
    state = state.copyWith(tasks: tasks);
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    // Optimistic local update
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(status: status);
    }).toList();
    state = state.copyWith(tasks: tasks);
    // Persist to server — ignore errors silently so UI stays responsive
    _service.updateTaskStatus(taskId, status).catchError((_) {});
  }

  Future<void> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    required String relatedDocument,
  }) async {
    // Optimistic insert with a temporary local ID
    final tempId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final tempTask = TaskModel(
      id: tempId,
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.todo,
      dueDate: dueDate,
      relatedDocument: relatedDocument,
      checklist: const [],
      attachments: const [],
      comments: const [],
      timeLogs: const [],
      hasPendingApproval: false,
      hasActiveTimer: false,
      isSynced: false,
    );
    state = state.copyWith(tasks: [...state.tasks, tempTask]);

    try {
      final serverId = await _service.createTask(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        relatedDocument: relatedDocument,
      );
      // Replace temp task with server-confirmed entry
      final updated = state.tasks.map((t) {
        if (t.id != tempId) return t;
        return t.copyWith(id: serverId, isSynced: true);
      }).toList();
      state = state.copyWith(tasks: updated);
    } catch (e) {
      // Roll back optimistic insert
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != tempId).toList(),
      );
      rethrow;
    }
  }

  void addComment(String taskId, CommentModel comment) {
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(comments: [...task.comments, comment]);
    }).toList();
    state = state.copyWith(tasks: tasks);
  }

  void snoozeTask(String taskId) {
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(dueDate: task.dueDate.add(const Duration(days: 1)));
    }).toList();
    state = state.copyWith(tasks: tasks);
  }

  TaskModel? getTaskById(String id) {
    try {
      return state.tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final _taskServiceProvider = Provider<TaskService>(
  (ref) => TaskService(AuthService()),
);

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(ref.read(_taskServiceProvider));
});
