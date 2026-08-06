import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/task_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_section.dart';

class TaskScreen extends ConsumerWidget {
  final String? projectId;

  const TaskScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    // If a project is selected, filter all task groups to that project.
    List<TaskModel> byProject(List<TaskModel> tasks) {
      if (projectId == null) return tasks;
      return tasks.where((t) => t.projectId == projectId).toList();
    }

    final overdue = byProject(notifier.overdueTasks);
    final today = byProject(notifier.todayTasks);
    final upcoming = byProject(notifier.upcomingTasks);
    final completed = byProject(notifier.completedTasks);

    final hasAny = overdue.isNotEmpty ||
        today.isNotEmpty ||
        upcoming.isNotEmpty ||
        completed.isNotEmpty;

    // Resolve project name for the AppBar title
    String title = 'Tasks';
    if (projectId != null) {
      final project =
          ref.read(projectProvider.notifier).getById(projectId!);
      if (project != null) title = project.name;
    }

    Widget body;
    if (taskState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (taskState.error != null && !hasAny) {
      body = _ErrorState(
        message: taskState.error!,
        onRetry: notifier.loadTasks,
      );
    } else if (hasAny) {
      body = ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          TaskSection(
            title: 'Overdue',
            tasks: overdue,
            titleColor: const Color(0xFFEF4444),
          ),
          TaskSection(
            title: 'Today',
            tasks: today,
            titleColor: AppColors.primary,
          ),
          TaskSection(
            title: 'Upcoming',
            tasks: upcoming,
            titleColor: const Color(0xFFF97316),
          ),
          TaskSection(
            title: 'Completed',
            tasks: completed,
            titleColor: const Color(0xFF22C55E),
          ),
        ],
      );
    } else {
      body = const _EmptyState();
    }

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          // Show back button when viewing a specific project
          leading: projectId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          actions: const [],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const TaskFilterBar(),
                Expanded(child: body),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => context.push('/task/create'),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Could not load tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
