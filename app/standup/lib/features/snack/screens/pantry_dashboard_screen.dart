import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/snack_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/pantry_scaffold.dart';
import '../providers/snack_provider.dart';

class PantryDashboardScreen extends ConsumerWidget {
  const PantryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        body: ListView(
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
                      onPressed: () => _accept(ref, request.id),
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
                  onPressed: () => _complete(ref, request.id),
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
        ),
      ),
    );
  }

  void _accept(WidgetRef ref, String requestId) {
    final pantryUserId = ref.read(currentSessionUserProvider)?.id ?? '';
    ref.read(snackProvider.notifier).acceptRequest(requestId, pantryUserId);
  }

  void _complete(WidgetRef ref, String requestId) {
    final pantryUserId = ref.read(currentSessionUserProvider)?.id ?? '';
    ref.read(snackProvider.notifier).completeRequest(requestId, pantryUserId);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String requestId) async {
    final reasonController = TextEditingController();
    final accepted = await showDialog<bool>(
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
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (accepted != true || reasonController.text.trim().isEmpty) return;
    final pantryUserId = ref.read(currentSessionUserProvider)?.id ?? '';
    ref.read(snackProvider.notifier).rejectRequest(
          requestId: requestId,
          pantryUserId: pantryUserId,
          reason: reasonController.text.trim(),
        );
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
