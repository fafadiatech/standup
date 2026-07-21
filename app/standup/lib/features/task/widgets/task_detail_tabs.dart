import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TaskDetailTabs extends StatelessWidget implements PreferredSizeWidget {
  const TaskDetailTabs({super.key});

  static const List<String> tabs = [
    'Overview',
    'Checklist',
    'Attachments',
    'Comments',
    'Time Logs',
  ];

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
    );
  }
}
