import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/task_provider.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  static const List<String> _filters = [
    'All',
    'Today',
    'High',
    'In Progress',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            onChanged: notifier.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search tasks…',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length + 1,
            separatorBuilder: (context, idx) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              if (index == _filters.length) {
                // Overflow chip for Completed
                final isActive = taskState.activeFilter == 'Completed';
                return FilterChip(
                  label: Text(isActive ? 'Completed' : '···'),
                  selected: isActive,
                  onSelected: (_) => notifier.setFilter('Completed'),
                  selectedColor: const Color(0xFF22C55E),
                  backgroundColor: AppColors.cardBackground,
                  labelStyle: TextStyle(
                    color: isActive ? AppColors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFF22C55E)
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                );
              }
              final filter = _filters[index];
              final isActive = taskState.activeFilter == filter;
              return FilterChip(
                label: Text(filter),
                selected: isActive,
                onSelected: (_) => notifier.setFilter(filter),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.cardBackground,
                labelStyle: TextStyle(
                  color: isActive ? AppColors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              );
            },
          ),
        ),
      ],
    );
  }
}
