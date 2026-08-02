import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_button_styles.dart';
import '../../../data/models/snack_request_model.dart';
import '../../../shared/widgets/pantry_scaffold.dart';
import '../providers/snack_provider.dart';

class PantryDashboardScreen extends ConsumerWidget {
  const PantryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pantryManagementProvider);
    final pending = ref.watch(pantryPendingRequestsProvider);
    final accepted = ref.watch(pantryAcceptedRequestsProvider);
    final history = ref.watch(pantryCompletedOrRejectedRequestsProvider);

    return PantryScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Orders'),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(pantryManagementProvider.notifier).refresh(),
          child: _buildBody(context, ref, state, pending, accepted, history),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PantryManagementState state,
    List<SnackRequestModel> pending,
    List<SnackRequestModel> accepted,
    List<SnackRequestModel> history,
  ) {
    if (state.isLoading && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Section(
          title: 'Pending Requests',
          requests: pending,
          emptyText: 'No pending requests',
          actionBuilder: (request) => Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref, request.id),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _accept(context, ref, request.id),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Accepted',
          requests: accepted,
          emptyText: 'No accepted requests',
          actionBuilder: (request) => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _complete(context, ref, request.id),
              style: AppButtonStyles.success,
              child: const Text('Mark Complete'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'History',
          requests: history,
          emptyText: 'No history yet',
          actionBuilder: (_) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await ref.read(pantryManagementProvider.notifier).acceptRequest(requestId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await ref.read(pantryManagementProvider.notifier).completeRequest(requestId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String requestId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: 'Reason'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: AppButtonStyles.compactDestructive,
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      await ref.read(pantryManagementProvider.notifier).rejectRequest(
            requestId: requestId,
            reason: reasonController.text.trim(),
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<SnackRequestModel> requests;
  final String emptyText;
  final Widget Function(SnackRequestModel request) actionBuilder;

  const _Section({
    required this.title,
    required this.requests,
    required this.emptyText,
    required this.actionBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            Text(emptyText, style: const TextStyle(color: AppColors.textSecondary))
          else
            ...requests.map(
              (request) => Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.itemsSummary,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (request.location != null)
                      Text(
                        request.location!.label,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    if (request.notes != null && request.notes!.isNotEmpty)
                      Text(
                        request.notes!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    if (request.rejectionReason != null &&
                        request.rejectionReason!.isNotEmpty)
                      Text(
                        'Reason: ${request.rejectionReason!}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    const SizedBox(height: 10),
                    actionBuilder(request),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
