import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: _AppWithSessionRestore(),
    ),
  );
}

/// Wraps [StandupApp] and silently restores the previous session before
/// the first frame is painted. Users with valid stored credentials are
/// redirected past the login screen by the router.
class _AppWithSessionRestore extends ConsumerStatefulWidget {
  const _AppWithSessionRestore();

  @override
  ConsumerState<_AppWithSessionRestore> createState() =>
      _AppWithSessionRestoreState();
}

class _AppWithSessionRestoreState
    extends ConsumerState<_AppWithSessionRestore> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: router will react once authProvider emits a new state.
    Future.microtask(
      () => ref.read(authProvider.notifier).tryRestoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) => const StandupApp();
}
