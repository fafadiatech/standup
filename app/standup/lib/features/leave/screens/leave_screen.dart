import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../providers/leave_provider.dart';
import '../widgets/leave_stat_card.dart';
import '../widgets/leave_history_item.dart';
import 'apply_leave_screen.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveProvider);
    final summary = state.summary;
    final history = state.history;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Leave',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
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
            // 2x2 stat grid
            Row(
              children: [
                Expanded(
                  child: LeaveStatCard(
                    count: summary.total.toString().padLeft(2, '0'),
                    label: 'TOTAL',
                    icon: Icons.layers_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LeaveStatCard(
                    count: summary.paid.toString().padLeft(2, '0'),
                    label: 'PAID',
                    icon: Icons.savings_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LeaveStatCard(
                    count: summary.unpaid.toString().padLeft(2, '0'),
                    label: 'UNPAID',
                    icon: Icons.money_off_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LeaveStatCard(
                    count: summary.pending.toString().padLeft(2, '0'),
                    label: 'PENDING',
                    icon: Icons.access_time_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ApplyLeaveScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply for leave',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Leave history header
            const Text(
              'Leave history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No leave history yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (_, i) => LeaveHistoryItem(record: history[i]),
              ),
          ],
        ),
      ),
    );
  }
}
