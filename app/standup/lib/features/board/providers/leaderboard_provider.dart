import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/board_service.dart';
import '../../../data/models/leaderboard_model.dart';

final _boardServiceProvider = Provider<BoardService>((ref) {
  return BoardService(AuthService());
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.read(_boardServiceProvider).getLeaderboard();
});

final employeeOfMonthProvider = FutureProvider<EmployeeOfMonth?>((ref) {
  return ref.read(_boardServiceProvider).getEmployeeOfMonth();
});
