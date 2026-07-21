import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/task/screens/task_screen.dart';
import 'features/task/screens/task_detail_screen.dart';
import 'features/task/screens/create_task_screen.dart';
import 'features/task/screens/manual_time_entry_screen.dart';
import 'features/leave/screens/leave_screen.dart';
import 'features/leave/screens/apply_leave_screen.dart';
import 'features/board/screens/board_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/snack/screens/snack_screen.dart';
import 'features/snack/screens/apply_snack_request_screen.dart';
import 'features/snack/screens/pantry_dashboard_screen.dart';
import 'features/snack/screens/pantry_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isLoggedIn = authState.isLoggedIn;
  final role = authState.user?.role.toLowerCase() ?? '';
  final isPantry = role == 'pantry';

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppStrings.routeLogin,
    redirect: (context, state) {
      final onLoginPage = state.matchedLocation == AppStrings.routeLogin;
      final onPantryPage = state.matchedLocation == AppStrings.routePantryDashboard ||
          state.matchedLocation == AppStrings.routePantryProfile;
      final onEmployeeRoute = state.matchedLocation == AppStrings.routeHome ||
          state.matchedLocation == AppStrings.routeTask ||
          state.matchedLocation == AppStrings.routeLeave ||
          state.matchedLocation == AppStrings.routeBoard ||
          state.matchedLocation == AppStrings.routeProfile ||
          state.matchedLocation == AppStrings.routeSnack ||
          state.matchedLocation == AppStrings.routeSnackApply;

      if (!isLoggedIn && !onLoginPage) {
        return AppStrings.routeLogin;
      }
      if (isLoggedIn && onLoginPage) {
        return isPantry
            ? AppStrings.routePantryDashboard
            : AppStrings.routeHome;
      }
      if (isLoggedIn && isPantry && onEmployeeRoute) {
        return AppStrings.routePantryDashboard;
      }
      if (isLoggedIn && !isPantry && onPantryPage) {
        return AppStrings.routeHome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppStrings.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppStrings.routeHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppStrings.routeTask,
        builder: (context, state) => const TaskScreen(),
      ),
      GoRoute(
        path: '/task/create',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: id);
        },
      ),
      GoRoute(
        path: '/task/:id/log-time',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ManualTimeEntryScreen(taskId: id);
        },
      ),
      GoRoute(
        path: AppStrings.routeLeave,
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: '/leave/apply',
        builder: (context, state) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: AppStrings.routeBoard,
        builder: (context, state) => const BoardScreen(),
      ),
      GoRoute(
        path: AppStrings.routeProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppStrings.routeSnack,
        builder: (context, state) => const SnackScreen(),
      ),
      GoRoute(
        path: AppStrings.routeSnackApply,
        builder: (context, state) => const ApplySnackRequestScreen(),
      ),
      GoRoute(
        path: AppStrings.routePantryDashboard,
        builder: (context, state) => const PantryDashboardScreen(),
      ),
      GoRoute(
        path: AppStrings.routePantryProfile,
        builder: (context, state) => const PantryProfileScreen(),
      ),
    ],
  );
});

class StandupApp extends ConsumerWidget {
  const StandupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
