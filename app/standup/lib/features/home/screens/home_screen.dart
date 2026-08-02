import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/task_model.dart';
import '../../task/providers/task_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/achievement_carousel.dart';
import '../widgets/holidays_banner.dart';
import '../widgets/weekly_meetings_section.dart';
import '../widgets/upcoming_events_section.dart';
import '../widgets/birthdays_section.dart';
import '../widgets/work_anniversaries_section.dart';
import '../../../shared/widgets/app_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final meetingsAsync = ref.watch(weeklyMeetingsProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysProvider);
    final anniversariesAsync = ref.watch(workAnniversariesProvider);
    final openTaskCount = ref
        .watch(taskProvider)
        .tasks
        .where((t) => t.status != TaskStatus.completed)
        .length;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 0,
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GreetingHeader(user: user),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: AppStrings.openTasks,
                          titleSuffix: AppStrings.openTasksSuffix,
                          value: '$openTaskCount',
                          subtitle: AppStrings.tasksRemaining,
                          backgroundColor: AppColors.cardBackground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: AppStrings.energyPoints,
                          titleSuffix: AppStrings.energyPointsSuffix,
                          value: '${user.energyPoints}',
                          subtitle: AppStrings.earnedSoFar,
                          backgroundColor: AppColors.cardBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  achievementsAsync.when(
                    data: (achievements) => achievements.isEmpty
                        ? const SizedBox.shrink()
                        : AchievementCarousel(achievements: achievements),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  meetingsAsync.when(
                    data: (meetings) => WeeklyMeetingsSection(meetings: meetings),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  eventsAsync.when(
                    data: (events) => UpcomingEventsSection(events: events),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  birthdaysAsync.when(
                    data: (birthdays) => BirthdaysSection(birthdays: birthdays),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  anniversariesAsync.when(
                    data: (anniversaries) =>
                        WorkAnniversariesSection(anniversaries: anniversaries),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  holidaysAsync.when(
                    data: (holidays) {
                      final today = DateTime.now();
                      final todayDate =
                          DateTime(today.year, today.month, today.day);
                      for (int i = 0; i < holidays.length; i++) {
                        final date = DateTime.tryParse(holidays[i].date);
                        if (date != null && !date.isBefore(todayDate)) {
                          return HolidaysBanner(
                            holiday: holidays[i],
                            holidayIndex: i,
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

