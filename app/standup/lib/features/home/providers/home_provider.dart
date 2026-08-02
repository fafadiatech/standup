import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/meeting_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/celebration_model.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/mock/mock_data.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/holiday_service.dart';
import '../../../core/services/home_service.dart';
import '../../auth/providers/auth_provider.dart';

final currentUserProvider = Provider<UserModel>((ref) {
  return ref.watch(currentSessionUserProvider) ?? MockData.currentUser;
});

final achievementsProvider = Provider<List<AchievementModel>>((ref) {
  return MockData.achievements;
});

final _holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService(AuthService());
});

final _homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService(AuthService());
});

final holidaysProvider = FutureProvider<List<HolidayModel>>((ref) {
  final service = ref.read(_holidayServiceProvider);
  return service.getHolidays();
});

final weeklyMeetingsProvider = FutureProvider<List<MeetingModel>>((ref) {
  final service = ref.read(_homeServiceProvider);
  return service.getWeeklyMeetings();
});

final upcomingEventsProvider = FutureProvider<List<EventModel>>((ref) {
  final service = ref.read(_homeServiceProvider);
  return service.getUpcomingEvents();
});

final birthdaysProvider = FutureProvider<List<CelebrationModel>>((ref) {
  final service = ref.read(_homeServiceProvider);
  return service.getBirthdays();
});

final workAnniversariesProvider = FutureProvider<List<CelebrationModel>>((ref) {
  final service = ref.read(_homeServiceProvider);
  return service.getWorkAnniversaries();
});
