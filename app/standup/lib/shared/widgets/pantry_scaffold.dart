import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/navigation_provider.dart';

class PantryScaffold extends ConsumerWidget {
  final Widget child;

  const PantryScaffold({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: AppStrings.navPantryOrders,
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      route: AppStrings.routePantryDashboard,
    ),
    _NavItem(
      label: AppStrings.navProfile,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: AppStrings.routePantryProfile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final routeIndex =
        _navItems.indexWhere((item) => item.route == location);
    final currentIndex = routeIndex >= 0
        ? routeIndex
        : ref.watch(pantryNavigationIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex >= _navItems.length ? 0 : currentIndex,
        onTap: (index) {
          ref.read(pantryNavigationIndexProvider.notifier).state = index;
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
