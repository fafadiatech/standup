class HolidayModel {
  final String id;
  final String name;
  final String date;

  const HolidayModel({
    required this.id,
    required this.name,
    required this.date,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}
