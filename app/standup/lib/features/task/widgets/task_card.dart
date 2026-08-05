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

/// Returns the single badge to show on a card: Priority if urgent/high,
/// otherwise Status if inProgress/paused. Never both.
_MetaChip? _singleBadge(TaskModel task) {
  if (task.priority == TaskPriority.urgent ||
      task.priority == TaskPriority.high) {
    return _MetaChip(
      label: _priorityLabel(task.priority),
      color: _priorityColor(task.priority),
    );
  }
  if (task.status == TaskStatus.inProgress ||
      task.status == TaskStatus.paused) {
    return _MetaChip(
      label: _statusLabel(task.status),
      color: _statusColor(task.status),
    );
  }
  return null;
}

class TaskCard extends ConsumerWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);

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
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/task/${task.id}'),
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(task: task),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/task/${task.id}'),
                child: _TaskMetaBlock(task: task),
              ),
            ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMetaBlock extends StatelessWidget {
  final TaskModel task;

  const _TaskMetaBlock({required this.task});

  @override
  Widget build(BuildContext context) {
    final dueDateStr = DateFormat('d MMM', 'en_US').format(task.dueDate);
    final hasRelated = task.relatedDocument.isNotEmpty;
    final metaText = hasRelated ? '$dueDateStr • ${task.relatedDocument}' : dueDateStr;
    final badge = _singleBadge(task);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            metaText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge,
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      case TaskStatus.overdue:
        return _TaskActionIcon(
          tooltip: 'Start',
          icon: Icons.play_arrow_rounded,
          filled: false,
          onPressed: () {
            notifier.updateTaskStatus(task.id, TaskStatus.inProgress);
            context.push('/task/${task.id}');
          },
        );
      case TaskStatus.inProgress:
        return _TaskActionIcon(
          tooltip: 'Continue',
          icon: Icons.arrow_forward_rounded,
          filled: true,
          onPressed: () => context.push('/task/${task.id}'),
        );
      case TaskStatus.paused:
        return _TaskActionIcon(
          tooltip: 'Resume',
          icon: Icons.play_circle_rounded,
          filled: true,
          onPressed: () {
            notifier.updateTaskStatus(task.id, TaskStatus.inProgress);
            context.push('/task/${task.id}');
          },
        );
      case TaskStatus.completed:
        return const SizedBox.shrink();
    }
  }
}

class _TaskActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _TaskActionIcon({
    required this.tooltip,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: filled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          shape: CircleBorder(
            side: filled
                ? BorderSide.none
                : const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            splashColor: AppColors.primary.withValues(alpha: 0.2),
            highlightColor: AppColors.primary.withValues(alpha: 0.1),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                icon,
                size: 18,
                color: filled ? AppColors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
