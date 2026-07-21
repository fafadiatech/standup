import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/mock/mock_data.dart';

class AuthState {
  final bool isLoggedIn;
  final UserModel? user;

  const AuthState({required this.isLoggedIn, required this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false, user: null));

  bool login({
    required String email,
    required String password,
  }) {
    final matched = MockData.users.where(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );

    if (matched.isEmpty || password != 'password123') {
      return false;
    }

    state = AuthState(isLoggedIn: true, user: matched.first);
    return true;
  }

  void logout() {
    state = const AuthState(isLoggedIn: false, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentSessionUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
