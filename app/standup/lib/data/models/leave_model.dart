enum LeaveStatus { pending, approved, rejected }

class LeaveBalance {
  final String leaveType;
  final double allocated;
  final double used;
  final double remaining;

  const LeaveBalance({
    required this.leaveType,
    required this.allocated,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        leaveType: json['leave_type'] as String,
        allocated: (json['allocated'] as num).toDouble(),
        used: (json['used'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
      );
}

class LeaveRecord {
  final String id;
  final String leaveType;
  final LeaveStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final double totalDays;

  const LeaveRecord({
    required this.id,
    required this.leaveType,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    final status = switch (statusStr) {
      'approved' => LeaveStatus.approved,
      'rejected' => LeaveStatus.rejected,
      _ => LeaveStatus.pending,
    };
    return LeaveRecord(
      id: json['id'] as String,
      leaveType: json['leave_type'] as String,
      status: status,
      startDate: DateTime.parse(json['from_date'] as String),
      endDate: DateTime.parse(json['to_date'] as String),
      totalDays: (json['total_days'] as num).toDouble(),
      reason: json['reason'] as String?,
    );
  }
}

class LeaveSummary {
  final int total;
  final int approved;
  final int pending;
  final int rejected;
  final List<LeaveBalance> balances;

  const LeaveSummary({
    required this.total,
    required this.approved,
    required this.pending,
    required this.rejected,
    this.balances = const [],
  });
}
