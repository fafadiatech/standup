import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/employee_of_month_card.dart';
import '../widgets/leaderboard_row.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeOfMonth = ref.watch(employeeOfMonthProvider);
    final leaderboard = ref.watch(leaderboardProvider);

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: const [
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Text('🏆', style: TextStyle(fontSize: 22)),
            ],
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: NotificationBell(),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Employee of the month
            EmployeeOfMonthCard(employee: employeeOfMonth),
            const SizedBox(height: 28),

            // Column headers
            const Row(
              children: [
                SizedBox(width: 36), // rank + gap
                Expanded(
                  child: Text(
                    'Employee name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'Energy point',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(color: AppColors.divider),

            // Ranked list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) => LeaderboardRow(entry: leaderboard[i]),
            ),
          ],
        ),
      ),
    );
  }
}
