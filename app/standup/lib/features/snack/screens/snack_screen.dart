import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/snack_request_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/snack_provider.dart';

class SnackScreen extends ConsumerWidget {
  const SnackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentSessionUserProvider);
    final requests = ref.watch(
      employeeSnackRequestsProvider(user?.id ?? ''),
    );

    return AppScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Pantry Requests'),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: requests.isEmpty
            ? const Center(
                child: Text(
                  'No requests yet. Tap + to request snacks or drinks.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemBuilder: (_, i) => _SnackRequestCard(request: requests[i]),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: requests.length,
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppStrings.routeSnackApply),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _SnackRequestCard extends StatelessWidget {
  final SnackRequestModel request;

  const _SnackRequestCard({required this.request});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  request.itemsSummary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.totalQuantity} item${request.totalQuantity == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (request.location != null) ...[
            const SizedBox(height: 4),
            Text(
              request.location!.label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.notes!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${request.rejectionReason!}',
              style: const TextStyle(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SnackRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SnackRequestStatus.pending => ('Pending', const Color(0xFFB45309)),
      SnackRequestStatus.accepted => ('Accepted', const Color(0xFF1D4ED8)),
      SnackRequestStatus.rejected => ('Rejected', const Color(0xFFB91C1C)),
      SnackRequestStatus.completed => ('Completed', const Color(0xFF15803D)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
