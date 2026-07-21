import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/time_log_model.dart';

class TimerState {
  final String? activeTaskId;
  final Duration elapsed;
  final bool isRunning;
  final String? notes;
  final DateTime? startedAt;

  const TimerState({
    this.activeTaskId,
    required this.elapsed,
    required this.isRunning,
    this.notes,
    this.startedAt,
  });

  TimerState copyWith({
    Object? activeTaskId = _sentinel,
    Duration? elapsed,
    bool? isRunning,
    Object? notes = _sentinel,
    Object? startedAt = _sentinel,
  }) {
    return TimerState(
      activeTaskId:
          activeTaskId == _sentinel ? this.activeTaskId : activeTaskId as String?,
      elapsed: elapsed ?? this.elapsed,
      isRunning: isRunning ?? this.isRunning,
      notes: notes == _sentinel ? this.notes : notes as String?,
      startedAt:
          startedAt == _sentinel ? this.startedAt : startedAt as DateTime?,
    );
  }
}

const _sentinel = Object();

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;

  TimerNotifier()
      : super(const TimerState(
          elapsed: Duration.zero,
          isRunning: false,
        ));

  void startTimer(String taskId) {
    // Stop existing timer if running on a different task
    if (state.isRunning && state.activeTaskId != taskId) {
      _stopTicker();
    }

    final now = DateTime.now();
    state = state.copyWith(
      activeTaskId: taskId,
      elapsed: Duration.zero,
      isRunning: true,
      startedAt: now,
    );
    _startTicker();
  }

  void pauseTimer() {
    _stopTicker();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (state.activeTaskId == null) return;
    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  /// Stops the timer and returns a TimeLogModel to be added to the task.
  TimeLogModel? stopTimer() {
    if (state.activeTaskId == null) return null;

    _stopTicker();

    final endTime = DateTime.now();
    final startTime =
        state.startedAt ?? endTime.subtract(state.elapsed);
    final hours = state.elapsed.inSeconds / 3600.0;

    final log = TimeLogModel(
      id: 'tl-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime(endTime.year, endTime.month, endTime.day),
      startTime: startTime,
      endTime: endTime,
      hours: double.parse(hours.toStringAsFixed(2)),
      notes: state.notes,
      synced: false,
    );

    state = TimerState(
      elapsed: Duration.zero,
      isRunning: false,
    );

    return log;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});
