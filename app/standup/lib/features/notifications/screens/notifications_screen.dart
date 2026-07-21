import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todayItems = notifications.where((n) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return d == todayDate;
    }).toList();

    final earlierItems = notifications.where((n) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      return d != todayDate;
    }).toList();

    final hasUnread = notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: notifier.markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const _EmptyState()
          : ListView(
              children: [
                if (todayItems.isNotEmpty) ...[
                  _SectionHeader(label: 'Today'),
                  ...todayItems.map(
                    (n) => NotificationTile(
                      notification: n,
                      onTap: () => notifier.markAsRead(n.id),
                      onDismiss: () => notifier.dismiss(n.id),
                    ),
                  ),
                ],
                if (earlierItems.isNotEmpty) ...[
                  _SectionHeader(label: 'Earlier'),
                  ...earlierItems.map(
                    (n) => NotificationTile(
                      notification: n,
                      onTap: () => notifier.markAsRead(n.id),
                      onDismiss: () => notifier.dismiss(n.id),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No notifications right now.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
