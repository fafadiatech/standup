import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/time_log_model.dart';
import '../providers/task_provider.dart';

class ManualTimeEntryScreen extends ConsumerStatefulWidget {
  final String taskId;

  const ManualTimeEntryScreen({super.key, required this.taskId});

  @override
  ConsumerState<ManualTimeEntryScreen> createState() =>
      _ManualTimeEntryScreenState();
}

class _ManualTimeEntryScreenState extends ConsumerState<ManualTimeEntryScreen> {
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _computedHours {
    final start = _startTime.hour * 60 + _startTime.minute;
    final end = _endTime.hour * 60 + _endTime.minute;
    final diff = end - start;
    return diff > 0 ? diff / 60.0 : 0.0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  void _save() {
    if (_computedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final startDt = DateTime(
        _date.year, _date.month, _date.day, _startTime.hour, _startTime.minute);
    final endDt = DateTime(
        _date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);

    final log = TimeLogModel(
      id: 'tl-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: startDt,
      endTime: endDt,
      hours: double.parse(_computedHours.toStringAsFixed(2)),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      synced: false,
    );

    ref.read(taskProvider.notifier).addTimeLog(widget.taskId, log);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, dd MMM yyyy', 'en_US').format(_date);
    final startStr = _startTime.format(context);
    final endStr = _endTime.format(context);
    final hours = _computedHours;
    final hoursStr = hours > 0
        ? '${hours.toStringAsFixed(2)} hours'
        : '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Log Time',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel(label: 'Date'),
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            value: dateStr,
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Start Time'),
          _PickerTile(
            icon: Icons.access_time_outlined,
            value: startStr,
            onTap: _pickStartTime,
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'End Time'),
          _PickerTile(
            icon: Icons.access_time_filled_outlined,
            value: endStr,
            onTap: _pickEndTime,
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Hours (computed)'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              hoursStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hours > 0 ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Notes (optional)'),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: _inputDecoration('Add notes about this work session…'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save Time Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
