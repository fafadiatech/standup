class TimeLogModel {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double hours;
  final String? notes;
  final bool synced;

  const TimeLogModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hours,
    this.notes,
    required this.synced,
  });
}
