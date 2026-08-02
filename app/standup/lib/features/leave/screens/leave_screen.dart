import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../data/models/leave_model.dart';
import '../providers/leave_provider.dart';
import '../widgets/leave_stat_card.dart';
import '../widgets/leave_history_item.dart';
import 'apply_leave_screen.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveProvider);

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
        body: RefreshIndicator(
          onRefresh: () => ref.read(leaveProvider.notifier).refresh(),
          child: _buildBody(context, ref, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LeaveState state) {
    if (state.isLoading && state.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(leaveProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = state.summary!;
    final history = state.history;

    return ListView(
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
                count: summary.approved.toString().padLeft(2, '0'),
                label: 'APPROVED',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LeaveStatCard(
                count: summary.pending.toString().padLeft(2, '0'),
                label: 'PENDING',
                icon: Icons.access_time_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LeaveStatCard(
                count: summary.rejected.toString().padLeft(2, '0'),
                label: 'REJECTED',
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        ),

        // Leave balances
        if (summary.balances.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Leave Balance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.balances.map((b) => _LeaveBalanceRow(balance: b)),
        ],

        const SizedBox(height: 20),

        // Apply button
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
          ),
          child: const Text('Apply for leave'),
        ),
        const SizedBox(height: 28),

        // Leave history header
        const Text(
          'Leave history',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
    );
  }
}

class _LeaveBalanceRow extends StatelessWidget {
  final LeaveBalance balance;

  const _LeaveBalanceRow({required this.balance});

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remaining;
    final allocated = balance.allocated;
    final progress = allocated > 0 ? (remaining / allocated).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balance.leaveType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${remaining % 1 == 0 ? remaining.toInt() : remaining} / '
                '${allocated % 1 == 0 ? allocated.toInt() : allocated} days',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
