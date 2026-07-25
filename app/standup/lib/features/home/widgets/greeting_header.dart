import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/notification_bell.dart';

class GreetingHeader extends ConsumerWidget {
  final UserModel user;

  const GreetingHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi ${user.name} 👋',
          style: theme.textTheme.headlineMedium,
        ),
        const NotificationBell(),
      ],
    );
  }
}
