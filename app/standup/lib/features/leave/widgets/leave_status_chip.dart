import 'package:flutter/material.dart';
import '../../../data/models/leave_model.dart';
import '../../../core/theme/app_colors.dart';

class LeaveStatusChip extends StatelessWidget {
  final LeaveStatus status;

  const LeaveStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LeaveStatus.pending => ('PENDING', AppColors.warning),
      LeaveStatus.approved => ('APPROVED', AppColors.success),
      LeaveStatus.rejected => ('REJECTED', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
