import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/providers/navigation_provider.dart';
import '../../../shared/widgets/pantry_scaffold.dart';

class PantryProfileScreen extends ConsumerWidget {
  const PantryProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return PantryScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.avatarInitials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.role,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _AccountTile(
                icon: Icons.logout,
                label: 'Logout',
                iconColor: AppColors.error,
                labelColor: AppColors.error,
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  ref.read(pantryNavigationIndexProvider.notifier).state = 0;
                  context.go(AppStrings.routeLogin);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color labelColor;

  const _AccountTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
