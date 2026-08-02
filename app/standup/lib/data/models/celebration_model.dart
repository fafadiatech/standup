class CelebrationModel {
  final String id;
  final String name;
  final String? designation;
  final int day;
  final String month;
  final String dayMonth;

  /// Only populated for work anniversaries (years since joining).
  final int? years;

  const CelebrationModel({
    required this.id,
    required this.name,
    this.designation,
    required this.day,
    required this.month,
    required this.dayMonth,
    this.years,
  });

  factory CelebrationModel.fromJson(Map<String, dynamic> json) {
    return CelebrationModel(
      id:          json['id'] as String,
      name:        json['name'] as String,
      designation: json['designation'] as String?,
      day:         json['day'] as int,
      month:       json['month'] as String,
      dayMonth:    json['day_month'] as String,
      years:       json['years'] as int?,
    );
  }
}
