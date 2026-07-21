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
}
