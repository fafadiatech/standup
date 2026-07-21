import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/checklist_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/task_provider.dart';

class ChecklistWidget extends ConsumerWidget {
  final String taskId;
  final ChecklistItem item;

  const ChecklistWidget({
    super.key,
    required this.taskId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () =>
          ref.read(taskProvider.notifier).toggleChecklist(taskId, item.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.primary
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 13, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: item.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
