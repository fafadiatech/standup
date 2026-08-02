import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pantry_service.dart';
import '../../../data/models/pantry_catalog_item.dart';
import '../../../data/models/snack_request_model.dart';

// ─── Employee snack state ─────────────────────────────────────────────────────

class SnackState {
  final List<PantryCatalogItem> catalog;
  final List<SnackRequestModel> requests;
  final bool isLoading;
  final String? error;

  const SnackState({
    this.catalog = const [],
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  SnackState copyWith({
    List<PantryCatalogItem>? catalog,
    List<SnackRequestModel>? requests,
    bool? isLoading,
    String? error,
  }) =>
      SnackState(
        catalog: catalog ?? this.catalog,
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SnackNotifier extends StateNotifier<SnackState> {
  SnackNotifier(this._service) : super(const SnackState(isLoading: true)) {
    _load();
  }

  final PantryService _service;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _service.getPantryCatalog(),
        _service.getMySnackRequests(),
      ]);
      state = SnackState(
        catalog: results[0] as List<PantryCatalogItem>,
        requests: results[1] as List<SnackRequestModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  /// Creates a new snack request and refreshes the list on success.
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> createRequest({
    required List<SnackRequestLineItem> items,
    SnackRequestLocation? location,
    String? notes,
  }) async {
    try {
      await _service.createSnackRequest(
        items: items,
        location: location,
        notes: notes,
      );
      await _load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ─── Pantry management state ──────────────────────────────────────────────────

class PantryManagementState {
  final List<SnackRequestModel> requests;
  final bool isLoading;
  final String? error;

  const PantryManagementState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  PantryManagementState copyWith({
    List<SnackRequestModel>? requests,
    bool? isLoading,
    String? error,
  }) =>
      PantryManagementState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PantryManagementNotifier
    extends StateNotifier<PantryManagementState> {
  PantryManagementNotifier(this._service)
      : super(const PantryManagementState(isLoading: true)) {
    _load();
  }

  final PantryService _service;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final requests = await _service.getAllSnackRequests();
      state = PantryManagementState(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> acceptRequest(String requestId) async {
    await _service.acceptSnackRequest(requestId);
    await _load();
  }

  Future<void> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    await _service.rejectSnackRequest(requestId, reason);
    await _load();
  }

  Future<void> completeRequest(String requestId) async {
    await _service.completeSnackRequest(requestId);
    await _load();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _pantryServiceProvider = Provider<PantryService>(
  (ref) => PantryService(AuthService()),
);

final snackProvider = StateNotifierProvider<SnackNotifier, SnackState>(
  (ref) => SnackNotifier(ref.read(_pantryServiceProvider)),
);

final pantryManagementProvider = StateNotifierProvider<
    PantryManagementNotifier, PantryManagementState>(
  (ref) => PantryManagementNotifier(ref.read(_pantryServiceProvider)),
);

// ─── Derived providers (employee view) ───────────────────────────────────────

final pantryCatalogProvider = Provider<List<PantryCatalogItem>>((ref) {
  return ref.watch(snackProvider).catalog;
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

/// Returns the current employee's requests. The [userId] parameter is kept for
/// API compatibility but the list is already server-filtered.
final employeeSnackRequestsProvider =
    Provider.family<List<SnackRequestModel>, String>((ref, userId) {
  return ref.watch(snackProvider).requests;
});

// ─── Derived providers (pantry staff view) ────────────────────────────────────

final pantryPendingRequestsProvider = Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(pantryManagementProvider)
      .requests
      .where((r) => r.status == SnackRequestStatus.pending)
      .toList();
});

final pantryAcceptedRequestsProvider = Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(pantryManagementProvider)
      .requests
      .where((r) => r.status == SnackRequestStatus.accepted)
      .toList();
});

final pantryCompletedOrRejectedRequestsProvider =
    Provider<List<SnackRequestModel>>((ref) {
  return ref
      .watch(pantryManagementProvider)
      .requests
      .where((r) =>
          r.status == SnackRequestStatus.completed ||
          r.status == SnackRequestStatus.rejected)
      .toList();
});
