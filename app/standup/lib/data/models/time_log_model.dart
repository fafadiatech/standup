class TimeLogModel {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double hours;
  final String? activityType;
  final String? notes;
  final bool synced;

  const TimeLogModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hours,
    this.activityType,
    this.notes,
    required this.synced,
  });

  TimeLogModel copyWith({
    String? id,
    bool? synced,
  }) {
    return TimeLogModel(
      id: id ?? this.id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      activityType: activityType,
      notes: notes,
      synced: synced ?? this.synced,
    );
  }
}
