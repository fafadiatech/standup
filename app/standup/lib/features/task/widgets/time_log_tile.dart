import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/time_log_model.dart';
import '../../../core/theme/app_colors.dart';

class TimeLogTile extends StatelessWidget {
  final TimeLogModel log;

  const TimeLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM', 'en_US').format(log.date);
    final startStr = DateFormat('h:mm a').format(log.startTime);
    final endStr = DateFormat('h:mm a').format(log.endTime);
    final hoursStr = log.hours == log.hours.truncateToDouble()
        ? '${log.hours.toInt()}h'
        : '${log.hours.toStringAsFixed(1)}h';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                hoursStr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              _SyncedBadge(synced: log.synced),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$startStr – $endStr',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.notes!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncedBadge extends StatelessWidget {
  final bool synced;

  const _SyncedBadge({required this.synced});

  @override
  Widget build(BuildContext context) {
    final color = synced ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);
    final label = synced ? 'Synced' : 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
