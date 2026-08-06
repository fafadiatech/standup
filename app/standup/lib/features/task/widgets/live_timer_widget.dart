import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_button_styles.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';

class LiveTimerWidget extends ConsumerStatefulWidget {
  final String taskId;

  const LiveTimerWidget({super.key, required this.taskId});

  @override
  ConsumerState<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends ConsumerState<LiveTimerWidget> {
  String? _selectedActivityType;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final taskNotifier = ref.read(taskProvider.notifier);
    final activityTypesAsync = ref.watch(activityTypesProvider);

    final isThisTask = timerState.activeTaskId == widget.taskId;
    final isOtherTask =
        timerState.activeTaskId != null && timerState.activeTaskId != widget.taskId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isThisTask
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisTask
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isThisTask ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOtherTask)
            const _OtherTaskMessage()
          else ...[
            // ── Activity type dropdown (only when timer is not yet started) ─
            if (!isThisTask)
              activityTypesAsync.when(
                loading: () => const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (types) {
                  if (types.isEmpty) return const SizedBox.shrink();
                  // Ensure selection is valid after the list loads.
                  if (_selectedActivityType == null ||
                      !types.contains(_selectedActivityType)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedActivityType = types.first);
                      }
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedActivityType ?? types.first,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        items: types
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedActivityType = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

            // ── Elapsed time display ──────────────────────────────────────
            Center(
              child: Text(
                _formatDuration(
                    isThisTask ? timerState.elapsed : Duration.zero),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color:
                      isThisTask ? AppColors.primary : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Controls ─────────────────────────────────────────────────
            if (!isThisTask)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    timerNotifier.startTimer(
                      widget.taskId,
                      activityType: _selectedActivityType,
                    );
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Timer'),
                  style: AppButtonStyles.compactPrimary,
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
                        timerState.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 16,
                      ),
                      label:
                          Text(timerState.isRunning ? 'Pause' : 'Resume'),
                      style: AppButtonStyles.compactOutlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final log = timerNotifier.stopTimer();
                        if (log != null) {
                          taskNotifier.addTimeLog(widget.taskId, log);
                        }
                      },
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Stop'),
                      style: AppButtonStyles.compactDestructive,
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
        const Expanded(
          child: Text(
            'Timer is active on another task.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
