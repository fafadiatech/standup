// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final user = auth?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standup'),
        actions: [
          IconButton(
            icon:     const Icon(Icons.logout),
            tooltip:  'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?['full_name'] ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(user?['email'] as String? ?? ''),
          ],
        ),
      ),
    );
  }
}
