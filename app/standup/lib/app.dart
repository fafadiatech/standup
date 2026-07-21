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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppStrings.routeLogin,
    redirect: (context, state) {
      final onLoginPage = state.matchedLocation == AppStrings.routeLogin;

      if (!isLoggedIn && !onLoginPage) {
        return AppStrings.routeLogin;
      }
      if (isLoggedIn && onLoginPage) {
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
        path: '/task',
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
        path: '/leave',
        builder: (context, state) => const LeaveScreen(),
      ),
      GoRoute(
        path: '/leave/apply',
        builder: (context, state) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: '/board',
        builder: (context, state) => const BoardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
