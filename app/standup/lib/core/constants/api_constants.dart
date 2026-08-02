class ApiConstants {
  ApiConstants._();

  // Android emulator reaches the host machine via 10.0.2.2.
  // Docker exposes ERPNext through nginx on port 8080 (not 8000).
  // Change to your server's IP/hostname for physical device or production.
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Frappe uses the Host header to identify which site to serve.
  // This must match the SITE_NAME configured in docker-compose.yaml.
  static const String frappeSiteName = 'site1.localhost';

  // All endpoints live under standup.api.<function>
  static const String mobileLogin =
      '/api/method/standup.api.mobile_login';
  static const String logout      = '/api/method/standup.api.logout';
  static const String me          = '/api/method/standup.api.me';
  static const String refreshToken =
      '/api/method/standup.api.refresh_token';
  static const String getHolidays =
      '/api/method/standup.api.get_holidays';

  // Leave endpoints
  static const String getLeaveTypes =
      '/api/method/standup.api.get_leave_types';
  static const String getLeaveBalance =
      '/api/method/standup.api.get_leave_balance';
  static const String getLeaveHistory =
      '/api/method/standup.api.get_leave_history';
  static const String applyLeave =
      '/api/method/standup.api.apply_leave';

  // Pantry endpoints
  static const String getPantryCatalog =
      '/api/method/standup.api.get_pantry_catalog';
  static const String createSnackRequest =
      '/api/method/standup.api.create_snack_request';
  static const String getMySnackRequests =
      '/api/method/standup.api.get_my_snack_requests';
  static const String getAllSnackRequests =
      '/api/method/standup.api.get_all_snack_requests';
  static const String acceptSnackRequest =
      '/api/method/standup.api.accept_snack_request';
  static const String rejectSnackRequest =
      '/api/method/standup.api.reject_snack_request';
  static const String completeSnackRequest =
      '/api/method/standup.api.complete_snack_request';

  // Home endpoints
  static const String getWeeklyMeetings =
      '/api/method/standup.api.get_weekly_meetings';
  static const String getUpcomingEvents =
      '/api/method/standup.api.get_upcoming_events';
  static const String getBirthdays =
      '/api/method/standup.api.get_birthdays';
  static const String getWorkAnniversaries =
      '/api/method/standup.api.get_work_anniversaries';

  // Achievement endpoints
  static const String getAchievements =
      '/api/method/standup.api.get_achievements';

  // Board endpoints
  static const String getLeaderboard =
      '/api/method/standup.api.get_leaderboard';
  static const String getEmployeeOfMonth =
      '/api/method/standup.api.get_employee_of_month';

  // Secure-storage keys
  static const String keyApiKey    = 'api_key';
  static const String keyApiSecret = 'api_secret';
}
