import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/home_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/achievement_carousel.dart';
import '../widgets/holidays_banner.dart';
import '../widgets/weekly_meetings_section.dart';
import '../widgets/upcoming_events_section.dart';
import '../../../shared/widgets/app_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final achievements = ref.watch(achievementsProvider);
    final holidays = ref.watch(holidaysProvider);
    final meetings = ref.watch(weeklyMeetingsProvider);
    final events = ref.watch(upcomingEventsProvider);

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
                          title: AppStrings.leaveBalance,
                          titleSuffix: AppStrings.leaveBalanceSuffix,
                          value: '${user.leaveBalance} days',
                          subtitle: AppStrings.daysLeft,
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
                  AchievementCarousel(achievements: achievements),
                  const SizedBox(height: 16),
                  if (holidays.isNotEmpty)
                    HolidaysBanner(holiday: holidays.first),
                  const SizedBox(height: 24),
                  WeeklyMeetingsSection(meetings: meetings),
                  const SizedBox(height: 24),
                  UpcomingEventsSection(events: events),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

