enum LeaveStatus { pending, approved, rejected }

enum LeaveType { paid, unpaid, sick, casual }

class LeaveRecord {
  final String id;
  final String title;
  final LeaveType type;
  final LeaveStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  const LeaveRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.reason,
  });
}

class LeaveSummary {
  final int total;
  final int paid;
  final int unpaid;
  final int pending;

  const LeaveSummary({
    required this.total,
    required this.paid,
    required this.unpaid,
    required this.pending,
  });
}
