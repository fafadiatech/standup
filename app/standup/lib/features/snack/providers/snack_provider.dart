import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/pantry_catalog_item.dart';
import '../../../data/models/snack_request_model.dart';

class SnackState {
  final List<SnackRequestModel> requests;

  const SnackState({required this.requests});
}

class SnackNotifier extends StateNotifier<SnackState> {
  SnackNotifier() : super(SnackState(requests: [...MockData.snackRequests]));

  void createRequest({
    required String requestedByUserId,
    required String requesterName,
    required List<SnackRequestLineItem> items,
    String? notes,
    SnackRequestLocation? location,
  }) {
    if (items.isEmpty) return;

    final request = SnackRequestModel(
      id: 'snk-${DateTime.now().millisecondsSinceEpoch}',
      requestedByUserId: requestedByUserId,
      requesterName: requesterName,
      items: items,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      location: location,
      requestedAt: DateTime.now(),
      status: SnackRequestStatus.pending,
    );

    state = SnackState(requests: [request, ...state.requests]);
  }

  void acceptRequest(String requestId, String pantryUserId) {
    _updateRequestStatus(
      requestId: requestId,
      pantryUserId: pantryUserId,
      status: SnackRequestStatus.accepted,
    );
  }

  void rejectRequest({
    required String requestId,
    required String pantryUserId,
    required String reason,
  }) {
    state = SnackState(
      requests: state.requests.map((request) {
        if (request.id != requestId) return request;
        return request.copyWith(
          status: SnackRequestStatus.rejected,
          handledByPantryUserId: pantryUserId,
          handledAt: DateTime.now(),
          rejectionReason: reason.trim(),
        );
      }).toList(),
    );
  }

  void completeRequest(String requestId, String pantryUserId) {
    _updateRequestStatus(
      requestId: requestId,
      pantryUserId: pantryUserId,
      status: SnackRequestStatus.completed,
    );
  }

  void _updateRequestStatus({
    required String requestId,
    required String pantryUserId,
    required SnackRequestStatus status,
  }) {
    state = SnackState(
      requests: state.requests.map((request) {
        if (request.id != requestId) return request;
        return request.copyWith(
          status: status,
          handledByPantryUserId: pantryUserId,
          handledAt: DateTime.now(),
        );
      }).toList(),
    );
  }
}

final snackProvider = StateNotifierProvider<SnackNotifier, SnackState>((ref) {
  return SnackNotifier();
});

final pantryCatalogProvider = Provider<List<PantryCatalogItem>>((ref) {
  return MockData.pantryCatalog;
});

final snackCatalogProvider = Provider<List<PantryCatalogItem>>((ref) {
  return ref
      .watch(pantryCatalogProvider)
      .where((item) => item.type == SnackItemType.snack)
      .toList();
});

final drinkCatalogProvider = Provider<List<PantryCatalogItem>>((ref) {
  return ref
      .watch(pantryCatalogProvider)
      .where((item) => item.type == SnackItemType.drink)
      .toList();
});

final pantryPendingRequestsProvider = Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(snackProvider)
      .requests
      .where((request) => request.status == SnackRequestStatus.pending)
      .toList();
});

final pantryAcceptedRequestsProvider = Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(snackProvider)
      .requests
      .where((request) => request.status == SnackRequestStatus.accepted)
      .toList();
});

final pantryCompletedOrRejectedRequestsProvider =
    Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(snackProvider)
      .requests
      .where((request) =>
          request.status == SnackRequestStatus.completed ||
          request.status == SnackRequestStatus.rejected)
      .toList();
});

final employeeSnackRequestsProvider =
    Provider.family<List<SnackRequestModel>, String>((ref, userId) {
  return ref
      .watch(snackProvider)
      .requests
      .where((request) => request.requestedByUserId == userId)
      .toList();
});
