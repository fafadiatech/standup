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
}
