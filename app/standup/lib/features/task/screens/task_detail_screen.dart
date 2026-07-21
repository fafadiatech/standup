import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/comment_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_detail_tabs.dart';
import '../widgets/checklist_widget.dart';
import '../widgets/attachment_tile.dart';
import '../widgets/comment_tile.dart';
import '../widgets/time_log_tile.dart';
import '../widgets/live_timer_widget.dart';

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

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskProvider);
    final task = ref.read(taskProvider.notifier).getTaskById(taskId);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: Text('Task not found')),
      );
    }

    return DefaultTabController(
      length: TaskDetailTabs.tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: const BackButton(color: AppColors.textPrimary),
          title: Text(
            task.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              onSelected: (value) {
                if (value == 'complete') {
                  ref
                      .read(taskProvider.notifier)
                      .updateTaskStatus(taskId, TaskStatus.completed);
                  context.pop();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'complete',
                  child: Text('Mark as Completed'),
                ),
              ],
            ),
          ],
          bottom: const TaskDetailTabs(),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(task: task),
            _ChecklistTab(task: task),
            _AttachmentsTab(task: task),
            _CommentsTab(task: task),
            _TimeLogsTab(task: task),
          ],
        ),
        bottomNavigationBar: _BottomActionBar(task: task),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  final TaskModel task;

  const _OverviewTab({required this.task});

  @override
  Widget build(BuildContext context) {
    final dueDateStr = DateFormat('EEE, dd MMM yyyy', 'en_US').format(task.dueDate);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          const Text(
            'Description',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            task.description,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Related Document
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.badgeBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  task.relatedDocument,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Priority + Status
          Row(
            children: [
              _DetailChip(
                label: _priorityLabel(task.priority),
                color: _priorityColor(task.priority),
              ),
              const SizedBox(width: 8),
              _DetailChip(
                label: _statusLabel(task.status),
                color: _statusColor(task.status),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Due date
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Due: $dueDateStr',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (task.hasPendingApproval) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions, size: 16, color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  Text(
                    'Pending approval',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist Tab
// ---------------------------------------------------------------------------
class _ChecklistTab extends ConsumerWidget {
  final TaskModel task;

  const _ChecklistTab({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskProvider);
    final updatedTask =
        ref.read(taskProvider.notifier).getTaskById(task.id) ?? task;

    if (updatedTask.checklist.isEmpty) {
      return const _TabEmptyState(
          icon: Icons.checklist, message: 'No checklist items');
    }

    final completed = updatedTask.checklist.where((i) => i.isCompleted).length;
    final total = updatedTask.checklist.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              '$completed / $total completed',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...updatedTask.checklist.map(
          (item) => ChecklistWidget(taskId: task.id, item: item),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attachments Tab
// ---------------------------------------------------------------------------
class _AttachmentsTab extends StatelessWidget {
  final TaskModel task;

  const _AttachmentsTab({required this.task});

  @override
  Widget build(BuildContext context) {
    if (task.attachments.isEmpty) {
      return const _TabEmptyState(
          icon: Icons.attach_file, message: 'No attachments');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          task.attachments.map((a) => AttachmentTile(attachment: a)).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments Tab
// ---------------------------------------------------------------------------
class _CommentsTab extends ConsumerStatefulWidget {
  final TaskModel task;

  const _CommentsTab({required this.task});

  @override
  ConsumerState<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends ConsumerState<_CommentsTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final comment = CommentModel(
      id: 'cmt-${DateTime.now().millisecondsSinceEpoch}',
      author: 'Sarah Connor',
      text: text,
      createdAt: DateTime.now(),
    );

    ref.read(taskProvider.notifier).addComment(widget.task.id, comment);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(taskProvider);
    final updatedTask =
        ref.read(taskProvider.notifier).getTaskById(widget.task.id) ??
            widget.task;

    return Column(
      children: [
        Expanded(
          child: updatedTask.comments.isEmpty
              ? const _TabEmptyState(
                  icon: Icons.chat_bubble_outline, message: 'No comments yet')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: updatedTask.comments
                      .map((c) => CommentTile(comment: c))
                      .toList(),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _sendComment(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendComment,
                icon: const Icon(Icons.send_rounded),
                color: AppColors.primary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Time Logs Tab
// ---------------------------------------------------------------------------
class _TimeLogsTab extends ConsumerWidget {
  final TaskModel task;

  const _TimeLogsTab({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskProvider);
    final updatedTask =
        ref.read(taskProvider.notifier).getTaskById(task.id) ?? task;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LiveTimerWidget(taskId: task.id),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/task/${task.id}/log-time'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Log Time Manually'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 16),
        if (updatedTask.timeLogs.isEmpty)
          const _TabEmptyState(
              icon: Icons.access_time, message: 'No time logs yet')
        else ...[
          const Text(
            'Time Logs',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...updatedTask.timeLogs
              .map((log) => TimeLogTile(log: log)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Action Bar
// ---------------------------------------------------------------------------
class _BottomActionBar extends ConsumerWidget {
  final TaskModel task;

  const _BottomActionBar({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskProvider);
    final updatedTask =
        ref.read(taskProvider.notifier).getTaskById(task.id) ?? task;
    final notifier = ref.read(taskProvider.notifier);

    if (updatedTask.status == TaskStatus.completed) {
      return Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
            SizedBox(width: 8),
            Text(
              'Completed',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF22C55E)),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        children: _buildActions(updatedTask, notifier, context),
      ),
    );
  }

  List<Widget> _buildActions(
      TaskModel task, TaskNotifier notifier, BuildContext context) {
    switch (task.status) {
      case TaskStatus.todo:
      case TaskStatus.overdue:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  notifier.updateTaskStatus(task.id, TaskStatus.inProgress),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Start',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ];
      case TaskStatus.inProgress:
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  notifier.updateTaskStatus(task.id, TaskStatus.paused),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                side: const BorderSide(color: Color(0xFFF97316)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Pause',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  notifier.updateTaskStatus(task.id, TaskStatus.completed),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Complete',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ];
      case TaskStatus.paused:
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  notifier.updateTaskStatus(task.id, TaskStatus.inProgress),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Resume',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  notifier.updateTaskStatus(task.id, TaskStatus.completed),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Complete',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ];
      case TaskStatus.completed:
        return [];
    }
  }
}

// ---------------------------------------------------------------------------
// Shared empty state widget
// ---------------------------------------------------------------------------
class _TabEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _TabEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
