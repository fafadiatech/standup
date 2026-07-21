import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/meeting_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/mock/mock_data.dart';
import '../../auth/providers/auth_provider.dart';

final currentUserProvider = Provider<UserModel>((ref) {
  return ref.watch(currentSessionUserProvider) ?? MockData.currentUser;
});

final achievementsProvider = Provider<List<AchievementModel>>((ref) {
  return MockData.achievements;
});

final holidaysProvider = Provider<List<HolidayModel>>((ref) {
  return MockData.upcomingHolidays;
});

final weeklyMeetingsProvider = Provider<List<MeetingModel>>((ref) {
  return MockData.weeklyMeetings;
});

final upcomingEventsProvider = Provider<List<EventModel>>((ref) {
  return MockData.upcomingEvents;
});
