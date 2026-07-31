class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarInitials;
  final int leaveBalance;
  final int energyPoints;
  final String issueNumber;
  final String issueName;
  final String issueStatus;

  // Extended profile fields
  final String role;
  final String department;
  final String phone;
  final String location;
  final String joinedDate;
  final String managedBy;
  final String employeeId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarInitials,
    required this.leaveBalance,
    required this.energyPoints,
    required this.issueNumber,
    required this.issueName,
    required this.issueStatus,
    this.role = '',
    this.department = '',
    this.phone = '',
    this.location = '',
    this.joinedDate = '',
    this.managedBy = '',
    this.employeeId = '',
  });

  /// Build a [UserModel] from the `user` object returned by the
  /// `/api/method/standup.api.auth.mobile_login` (and `/me`) endpoints.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fullName = (json['full_name'] as String?) ?? '';
    final roles =
        (json['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ??
            [];

    // Route pantry staff to the pantry dashboard by tagging them 'Pantry'.
    final isPantry = roles.any((r) => r.toLowerCase().contains('pantry'));
    final primaryRole = isPantry
        ? 'Pantry'
        : (roles.isNotEmpty ? roles.first : '');

    // Derive avatar initials from the first and last name segments.
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : fullName.isNotEmpty
            ? fullName[0].toUpperCase()
            : '?';

    return UserModel(
      id: (json['name'] as String?) ?? '',
      name: fullName,
      email: (json['email'] as String?) ?? '',
      avatarInitials: initials,
      leaveBalance: 0,
      energyPoints: 0,
      issueNumber: '-',
      issueName: '-',
      issueStatus: '-',
      role: primaryRole,
    );
  }
}
