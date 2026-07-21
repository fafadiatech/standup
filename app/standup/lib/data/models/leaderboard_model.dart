import 'package:flutter/material.dart';

class LeaderboardEntry {
  final String id;
  final int rank;
  final String name;
  final String role;
  final int energyPoints;
  final String initials;
  final Color avatarColor;

  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.role,
    required this.energyPoints,
    required this.initials,
    required this.avatarColor,
  });
}

class EmployeeOfMonth {
  final String name;
  final String role;
  final String description;
  final String initials;
  final Color avatarColor;
  // Pre-formatted as dd/MM/yyyy
  final String displayDate;

  const EmployeeOfMonth({
    required this.name,
    required this.role,
    required this.description,
    required this.initials,
    required this.avatarColor,
    required this.displayDate,
  });
}
