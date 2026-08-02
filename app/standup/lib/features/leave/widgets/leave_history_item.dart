import 'package:flutter/material.dart';
import '../../../data/models/leave_model.dart';
import '../../../core/theme/app_colors.dart';
import 'leave_date_badge.dart';
import 'leave_status_chip.dart';

class LeaveHistoryItem extends StatelessWidget {
  final LeaveRecord record;

  const LeaveHistoryItem({super.key, required this.record});

  String get _typeLabel => record.leaveType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LeaveDateBadge(date: record.startDate),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                LeaveStatusChip(status: record.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
