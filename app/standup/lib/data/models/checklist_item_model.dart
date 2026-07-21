class ChecklistItem {
  final String id;
  final String label;
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.label,
    required this.isCompleted,
  });

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
