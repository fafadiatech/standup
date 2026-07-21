import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/mock/mock_data.dart';

final employeeOfMonthProvider = Provider<EmployeeOfMonth>(
  (_) => MockData.employeeOfMonth,
);

final leaderboardProvider = Provider<List<LeaderboardEntry>>(
  (_) => MockData.leaderboard,
);
