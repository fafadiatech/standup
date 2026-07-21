import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/time_log_model.dart';
import '../../../data/mock/mock_data.dart';

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

  const TaskState({
    required this.tasks,
    required this.searchQuery,
    required this.activeFilter,
    required this.isOnline,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    String? searchQuery,
    String? activeFilter,
    bool? isOnline,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isOnline: isOnline ?? this.isOnline,
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
  TaskNotifier()
      : super(
          TaskState(
            tasks: List.from(MockData.tasks),
            searchQuery: '',
            activeFilter: 'All',
            isOnline: true,
          ),
        );

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
      case 'High Priority':
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
    final tasks = state.tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(status: status);
    }).toList();
    state = state.copyWith(tasks: tasks);
  }

  void addTask(TaskModel task) {
    state = state.copyWith(tasks: [...state.tasks, task]);
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
final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier();
});
