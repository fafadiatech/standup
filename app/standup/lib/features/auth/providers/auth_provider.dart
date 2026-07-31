import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.isLoggedIn,
    required this.user,
    this.errorMessage,
  });
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService)
      : super(const AuthState(isLoggedIn: false, user: null));

  final AuthService _authService;

  /// Authenticates the user against the Frappe backend.
  /// Returns `true` on success; on failure the error message is stored in
  /// [AuthState.errorMessage] and `false` is returned.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.login(email: email, password: password);
      state = AuthState(isLoggedIn: true, user: user);
      return true;
    } catch (e) {
      state = AuthState(
        isLoggedIn: false,
        user: null,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Invalidates the token on the server and clears local storage.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isLoggedIn: false, user: null);
  }

  /// Called on app startup to silently restore a previous session.
  /// If stored credentials are still valid the user bypasses the login screen.
  Future<void> tryRestoreSession() async {
    final user = await _authService.tryRestoreSession();
    if (user != null) {
      state = AuthState(isLoggedIn: true, user: user);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(_authServiceProvider));
});

final currentSessionUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
