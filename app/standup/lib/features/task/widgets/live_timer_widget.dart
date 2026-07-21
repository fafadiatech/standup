import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';

class LiveTimerWidget extends ConsumerWidget {
  final String taskId;

  const LiveTimerWidget({super.key, required this.taskId});

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final taskNotifier = ref.read(taskProvider.notifier);

    final isThisTask = timerState.activeTaskId == taskId;
    final isOtherTask =
        timerState.activeTaskId != null && timerState.activeTaskId != taskId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isThisTask
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisTask ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: isThisTask ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Time Tracker',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isThisTask
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOtherTask)
            const _OtherTaskMessage()
          else ...[
            Text(
              _formatDuration(isThisTask ? timerState.elapsed : Duration.zero),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isThisTask ? AppColors.primary : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            if (!isThisTask)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => timerNotifier.startTimer(taskId),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: timerState.isRunning
                          ? timerNotifier.pauseTimer
                          : timerNotifier.resumeTimer,
                      icon: Icon(
                        timerState.isRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(timerState.isRunning ? 'Pause' : 'Resume'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final log = timerNotifier.stopTimer();
                        if (log != null) {
                          taskNotifier.addTimeLog(taskId, log);
                        }
                      },
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _OtherTaskMessage extends StatelessWidget {
  const _OtherTaskMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Color(0xFFF97316)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Timer is active on another task.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
