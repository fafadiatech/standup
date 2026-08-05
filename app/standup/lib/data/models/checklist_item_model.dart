class ChecklistItem {
  final String id;
  final String label;
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.label,
    required this.isCompleted,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      isCompleted: (json['is_completed'] as bool?) ?? false,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? label,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
