import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/task_provider.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_section.dart';

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);
    // Watch the state to rebuild when tasks change
    ref.watch(taskProvider);

    final overdue = notifier.overdueTasks;
    final today = notifier.todayTasks;
    final upcoming = notifier.upcomingTasks;
    final completed = notifier.completedTasks;

    final hasAny = overdue.isNotEmpty ||
        today.isNotEmpty ||
        upcoming.isNotEmpty ||
        completed.isNotEmpty;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Tasks',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: SyncStatusBadge(),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Search + filter chips
                const TaskFilterBar(),
                // Task list
                Expanded(
                  child: hasAny
                      ? ListView(
                          padding: const EdgeInsets.only(bottom: 80),
                          children: [
                            TaskSection(
                              title: 'OVERDUE',
                              tasks: overdue,
                              titleColor: const Color(0xFFEF4444),
                            ),
                            TaskSection(
                              title: 'TODAY',
                              tasks: today,
                              titleColor: AppColors.primary,
                            ),
                            TaskSection(
                              title: 'UPCOMING',
                              tasks: upcoming,
                              titleColor: const Color(0xFFF97316),
                            ),
                            TaskSection(
                              title: 'COMPLETED',
                              tasks: completed,
                              titleColor: const Color(0xFF22C55E),
                            ),
                          ],
                        )
                      : const _EmptyState(),
                ),
              ],
            ),
            // FAB positioned over list
            Positioned(
              bottom: 12,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => context.push('/task/create'),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_box_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create a new task',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
