import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/leave_model.dart';
import '../../../data/mock/mock_data.dart';

class LeaveState {
  final LeaveSummary summary;
  final List<LeaveRecord> history;

  const LeaveState({required this.summary, required this.history});
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  LeaveNotifier()
      : super(LeaveState(
          summary: MockData.leaveSummary,
          history: MockData.leaveHistory,
        ));

  void addLeaveRequest(LeaveRecord record) {
    state = LeaveState(
      summary: LeaveSummary(
        total: state.summary.total + 1,
        paid: record.type == LeaveType.paid
            ? state.summary.paid + 1
            : state.summary.paid,
        unpaid: record.type == LeaveType.unpaid
            ? state.summary.unpaid + 1
            : state.summary.unpaid,
        pending: state.summary.pending + 1,
      ),
      history: [record, ...state.history],
    );
  }
}

final leaveProvider =
    StateNotifierProvider<LeaveNotifier, LeaveState>((ref) => LeaveNotifier());
