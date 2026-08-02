import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/celebration_model.dart';

class WorkAnniversariesSection extends StatelessWidget {
  final List<CelebrationModel> anniversaries;

  const WorkAnniversariesSection({super.key, required this.anniversaries});

  @override
  Widget build(BuildContext context) {
    if (anniversaries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Anniversaries', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...anniversaries.map((a) => _AnniversaryTile(anniversary: a)),
      ],
    );
  }
}

class _AnniversaryTile extends StatelessWidget {
  final CelebrationModel anniversary;

  const _AnniversaryTile({required this.anniversary});

  static const Color _accentColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(anniversary.name);
    final years = anniversary.years ?? 0;
    final yearLabel = years == 1 ? '1 year' : '$years years';

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
                backgroundColor: _accentColor.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const Positioned(
                bottom: -2,
                right: -4,
                child: Text('🎉', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anniversary.name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (anniversary.designation != null &&
                    anniversary.designation!.isNotEmpty)
                  Text(
                    anniversary.designation!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  anniversary.dayMonth,
                  style: const TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                yearLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
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
