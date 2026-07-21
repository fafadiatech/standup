import 'package:flutter/material.dart';
import '../../../data/models/leave_model.dart';
import '../../../core/theme/app_colors.dart';

class LeaveStatusChip extends StatelessWidget {
  final LeaveStatus status;

  const LeaveStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      LeaveStatus.pending => (
          'PENDING',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
      LeaveStatus.approved => (
          'APPROVED',
          const Color(0xFFDCFCE7),
          AppColors.success,
        ),
      LeaveStatus.rejected => (
          'REJECTED',
          const Color(0xFFFFE4E6),
          AppColors.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
