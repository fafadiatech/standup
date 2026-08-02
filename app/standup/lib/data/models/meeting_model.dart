class MeetingModel {
  final String id;
  final String teamName;
  final String recurrence;
  final String time;
  final String? location;
  final String? meetingLink;
  final String? description;

  const MeetingModel({
    required this.id,
    required this.teamName,
    required this.recurrence,
    required this.time,
    this.location,
    this.meetingLink,
    this.description,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id:          json['id'] as String,
      teamName:    json['team_name'] as String,
      recurrence:  json['recurrence'] as String,
      time:        json['meeting_time'] as String? ?? '',
      location:    json['location'] as String?,
      meetingLink: json['meeting_link'] as String?,
      description: json['description'] as String?,
    );
  }
}
