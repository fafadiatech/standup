enum ProjectStatus { active, inactive, completed }

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final int taskCount;
  final int completedTaskCount;
  final int colorValue;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.taskCount,
    required this.completedTaskCount,
    required this.colorValue,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: _statusFromString(json['status'] as String? ?? 'active'),
      taskCount: (json['task_count'] as int?) ?? 0,
      completedTaskCount: (json['completed_task_count'] as int?) ?? 0,
      colorValue: (json['color_value'] as int?) ?? 0xFF1565C0,
    );
  }

  static ProjectStatus _statusFromString(String s) {
    switch (s) {
      case 'inactive':  return ProjectStatus.inactive;
      case 'completed': return ProjectStatus.completed;
      default:          return ProjectStatus.active;
    }
  }
}
