import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/celebration_model.dart';

class BirthdaysSection extends StatelessWidget {
  final List<CelebrationModel> birthdays;

  const BirthdaysSection({super.key, required this.birthdays});

  @override
  Widget build(BuildContext context) {
    if (birthdays.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthdays This Month', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...birthdays.map((b) => _CelebrationTile(
              celebration: b,
              accentColor: const Color(0xFFE91E8C),
              icon: '🎂',
            )),
      ],
    );
  }
}

class _CelebrationTile extends StatelessWidget {
  final CelebrationModel celebration;
  final Color accentColor;
  final String icon;

  const _CelebrationTile({
    required this.celebration,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(celebration.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -4,
                child: Text(icon, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  celebration.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (celebration.designation != null &&
                    celebration.designation!.isNotEmpty)
                  Text(
                    celebration.designation!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              celebration.dayMonth,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
