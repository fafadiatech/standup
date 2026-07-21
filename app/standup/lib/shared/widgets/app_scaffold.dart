import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/navigation_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: AppStrings.navHome,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/home',
    ),
    _NavItem(
      label: AppStrings.navTask,
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt,
      route: '/task',
    ),
    _NavItem(
      label: AppStrings.navLeave,
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      route: '/leave',
    ),
    _NavItem(
      label: AppStrings.navBoard,
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      route: '/board',
    ),
    _NavItem(
      label: AppStrings.navProfile,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          context.go(_navItems[index].route);
        },
        items: _navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon, color: AppColors.primary),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
