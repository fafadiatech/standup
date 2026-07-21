import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/task_provider.dart';

Color _priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.urgent:
      return const Color(0xFFEF4444);
    case TaskPriority.high:
      return const Color(0xFFF97316);
    case TaskPriority.medium:
      return const Color(0xFF1565C0);
    case TaskPriority.low:
      return const Color(0xFF9CA3AF);
  }
}

String _priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.urgent:
      return 'Urgent';
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

Color _statusColor(TaskStatus s) {
  switch (s) {
    case TaskStatus.overdue:
      return const Color(0xFFEF4444);
    case TaskStatus.inProgress:
      return const Color(0xFF1565C0);
    case TaskStatus.paused:
      return const Color(0xFFF97316);
    case TaskStatus.completed:
      return const Color(0xFF22C55E);
    case TaskStatus.todo:
      return const Color(0xFF9CA3AF);
  }
}

String _statusLabel(TaskStatus s) {
  switch (s) {
    case TaskStatus.overdue:
      return 'Overdue';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.paused:
      return 'Paused';
    case TaskStatus.completed:
      return 'Completed';
    case TaskStatus.todo:
      return 'To Do';
  }
}

class TaskCard extends ConsumerWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);
    final dueDateStr =
        DateFormat('EEE, dd MMM', 'en_US').format(task.dueDate);

    return Dismissible(
      key: ValueKey(task.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF22C55E),
        icon: Icons.check_circle_outline,
        label: 'Complete',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFFF59E0B),
        icon: Icons.snooze,
        label: 'Snooze 1d',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          notifier.updateTaskStatus(task.id, TaskStatus.completed);
        } else {
          notifier.snoozeTask(task.id);
        }
        return false; // Don't actually dismiss; provider rebuilds list
      },
      child: GestureDetector(
        onTap: () => context.push('/task/${task.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: title + priority chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PriorityChip(priority: task.priority),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: due date + related document
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Due: $dueDateStr',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.relatedDocument,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 3: status badge + indicators + action button
                Row(
                  children: [
                    _StatusBadge(status: task.status),
                    const SizedBox(width: 8),
                    _IndicatorRow(task: task),
                    const Spacer(),
                    _ActionButton(task: task),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final TaskModel task;

  const _IndicatorRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (task.comments.isNotEmpty) ...[
          const Icon(Icons.chat_bubble_outline,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text('${task.comments.length}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
        ],
        if (task.attachments.isNotEmpty) ...[
          const Icon(Icons.attach_file,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text('${task.attachments.length}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
        ],
        if (task.hasPendingApproval)
          const Icon(Icons.pending_actions,
              size: 14, color: Color(0xFFF97316)),
        if (task.hasActiveTimer) ...[
          const SizedBox(width: 4),
          const Icon(Icons.timer, size: 14, color: AppColors.primary),
        ],
      ],
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final TaskModel task;

  const _ActionButton({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);

    switch (task.status) {
      case TaskStatus.todo:
        return OutlinedButton(
          onPressed: () {
            notifier.updateTaskStatus(task.id, TaskStatus.inProgress);
            context.push('/task/${task.id}');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('Start'),
        );
      case TaskStatus.inProgress:
        return ElevatedButton(
          onPressed: () => context.push('/task/${task.id}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          child: const Text('Continue'),
        );
      case TaskStatus.paused:
        return OutlinedButton(
          onPressed: () {
            notifier.updateTaskStatus(task.id, TaskStatus.inProgress);
            context.push('/task/${task.id}');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF97316),
            side: const BorderSide(color: Color(0xFFF97316)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('Resume'),
        );
      case TaskStatus.overdue:
        return OutlinedButton(
          onPressed: () {
            notifier.updateTaskStatus(task.id, TaskStatus.inProgress);
            context.push('/task/${task.id}');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('Start'),
        );
      case TaskStatus.completed:
        return const SizedBox.shrink();
    }
  }
}
