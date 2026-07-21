// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const ProviderScope(child: StandupApp()));
}

class StandupApp extends ConsumerWidget {
  const StandupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    final router = GoRouter(
      refreshListenable: _AuthStateNotifier(ref),
      redirect: (context, state) {
        final auth = authAsync.valueOrNull;
        final isLoginRoute = state.matchedLocation == '/login';

        if (auth == null || auth.status == AuthStatus.unknown) return null;
        if (auth.status == AuthStatus.unauthenticated && !isLoginRoute) {
          return '/login';
        }
        if (auth.status == AuthStatus.authenticated && isLoginRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/',      builder: (_, __) => const HomeScreen()),
      ],
    );

    return MaterialApp.router(
      title:        'Standup',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3498DB),
        useMaterial3:    true,
      ),
    );
  }
}

// Bridges Riverpod state changes to GoRouter's Listenable interface.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
