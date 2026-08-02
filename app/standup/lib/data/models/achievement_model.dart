class AchievementModel {
  final String id;
  final String badgeEmoji;
  final String badgeTitle;
  final String description;
  final String personName;
  final String personInitials;
  final String achievedDate;

  const AchievementModel({
    required this.id,
    required this.badgeEmoji,
    required this.badgeTitle,
    required this.description,
    required this.personName,
    required this.personInitials,
    required this.achievedDate,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final name = (json['employee_name'] as String?) ?? '';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return AchievementModel(
      id: (json['id'] as String?) ?? '',
      badgeEmoji: (json['badge_emoji'] as String?) ?? '',
      badgeTitle: (json['badge_title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      personName: name,
      personInitials: initials,
      achievedDate: (json['achieved_date'] as String?) ?? '',
    );
  }
}
