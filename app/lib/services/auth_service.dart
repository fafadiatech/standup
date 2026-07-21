// lib/services/auth_service.dart
//
// Riverpod-backed auth state. Reads persisted credentials on startup
// to restore the session without requiring re-login.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'frappe_api_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus            status;
  final Map<String, dynamic>? user;
  final String?               error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user   = null,
        error  = null;

  AuthState copyWith({
    AuthStatus?            status,
    Map<String, dynamic>?  user,
    String?                error,
  }) => AuthState(
    status: status ?? this.status,
    user:   user   ?? this.user,
    error:  error  ?? this.error,
  );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  FrappeApiService get _api => FrappeApiService.instance;

  @override
  Future<AuthState> build() async {
    // On first build, check if credentials exist and are valid.
    final creds = await _api.loadCredentials();
    if (creds == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    try {
      final user = await _api.me();
      return AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _api.clearCredentials();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _api.login(username: username, password: password);
      return AuthState(status: AuthStatus.authenticated, user: user);
    });
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
