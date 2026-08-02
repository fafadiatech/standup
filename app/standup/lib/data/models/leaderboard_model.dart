import 'package:flutter/material.dart';

// Deterministic avatar colors — cycled by index derived from name hash.
const List<Color> _kAvatarPalette = [
  Color(0xFF7C3AED),
  Color(0xFF16A34A),
  Color(0xFF1E40AF),
  Color(0xFFDC2626),
  Color(0xFF0891B2),
  Color(0xFFD97706),
  Color(0xFF9333EA),
  Color(0xFF065F46),
];

Color _avatarColor(String name) {
  final hash = name.codeUnits.fold(0, (h, c) => h + c);
  return _kAvatarPalette[hash % _kAvatarPalette.length];
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

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

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ?? '';
    return LeaderboardEntry(
      id:           (json['employee_id'] as String?) ?? '',
      rank:         (json['rank'] as num?)?.toInt() ?? 0,
      name:         name,
      role:         (json['designation'] as String?) ?? '',
      energyPoints: (json['energy_points'] as num?)?.toInt() ?? 0,
      initials:     _initials(name),
      avatarColor:  _avatarColor(name),
    );
  }
}

class EmployeeOfMonth {
  final String name;
  final String role;
  final String description;
  final String initials;
  final Color avatarColor;
  // Pre-formatted as Month YYYY
  final String displayDate;

  const EmployeeOfMonth({
    required this.name,
    required this.role,
    required this.description,
    required this.initials,
    required this.avatarColor,
    required this.displayDate,
  });

  factory EmployeeOfMonth.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ?? '';
    return EmployeeOfMonth(
      name:        name,
      role:        (json['designation'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      initials:    _initials(name),
      avatarColor: _avatarColor(name),
      displayDate: (json['display_month'] as String?) ?? '',
    );
  }
}
