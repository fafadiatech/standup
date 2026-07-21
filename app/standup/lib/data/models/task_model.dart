import 'checklist_item_model.dart';
import 'attachment_model.dart';
import 'comment_model.dart';
import 'time_log_model.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, paused, completed, overdue }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String relatedDocument;
  final List<ChecklistItem> checklist;
  final List<AttachmentModel> attachments;
  final List<CommentModel> comments;
  final List<TimeLogModel> timeLogs;
  final bool hasPendingApproval;
  final bool hasActiveTimer;
  final bool isSynced;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.relatedDocument,
    required this.checklist,
    required this.attachments,
    required this.comments,
    required this.timeLogs,
    required this.hasPendingApproval,
    required this.hasActiveTimer,
    required this.isSynced,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? relatedDocument,
    List<ChecklistItem>? checklist,
    List<AttachmentModel>? attachments,
    List<CommentModel>? comments,
    List<TimeLogModel>? timeLogs,
    bool? hasPendingApproval,
    bool? hasActiveTimer,
    bool? isSynced,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      relatedDocument: relatedDocument ?? this.relatedDocument,
      checklist: checklist ?? this.checklist,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      timeLogs: timeLogs ?? this.timeLogs,
      hasPendingApproval: hasPendingApproval ?? this.hasPendingApproval,
      hasActiveTimer: hasActiveTimer ?? this.hasActiveTimer,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
