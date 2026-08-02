import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/leave_service.dart';
import '../../../data/models/leave_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class LeaveState {
  final LeaveSummary? summary;
  final List<LeaveRecord> history;
  final List<String> leaveTypes;
  final bool isLoading;
  final String? error;

  const LeaveState({
    this.summary,
    this.history = const [],
    this.leaveTypes = const [],
    this.isLoading = false,
    this.error,
  });

  LeaveState copyWith({
    LeaveSummary? summary,
    List<LeaveRecord>? history,
    List<String>? leaveTypes,
    bool? isLoading,
    String? error,
  }) =>
      LeaveState(
        summary: summary ?? this.summary,
        history: history ?? this.history,
        leaveTypes: leaveTypes ?? this.leaveTypes,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LeaveNotifier extends StateNotifier<LeaveState> {
  LeaveNotifier(this._service)
      : super(const LeaveState(isLoading: true)) {
    _load();
  }

  final LeaveService _service;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _service.getLeaveHistory(),
        _service.getLeaveBalance(),
        _service.getLeaveTypes(),
      ]);

      final history = results[0] as List<LeaveRecord>;
      final balances = results[1] as List<LeaveBalance>;
      final leaveTypes = results[2] as List<String>;

      final total = history.length;
      final pending =
          history.where((r) => r.status == LeaveStatus.pending).length;
      final approved =
          history.where((r) => r.status == LeaveStatus.approved).length;
      final rejected =
          history.where((r) => r.status == LeaveStatus.rejected).length;

      state = LeaveState(
        summary: LeaveSummary(
          total: total,
          approved: approved,
          pending: pending,
          rejected: rejected,
          balances: balances,
        ),
        history: history,
        leaveTypes: leaveTypes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refreshes all leave data from the server.
  Future<void> refresh() => _load();

  /// Submits a leave application. Returns `true` on success.
  /// On failure, returns `false` and stores the error in [LeaveState.error].
  Future<bool> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      await _service.applyLeave(
        leaveType: leaveType,
        fromDate: startDate,
        toDate: endDate,
        reason: reason,
      );
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _leaveServiceProvider = Provider<LeaveService>(
  (ref) => LeaveService(AuthService()),
);

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>(
  (ref) => LeaveNotifier(ref.read(_leaveServiceProvider)),
);
