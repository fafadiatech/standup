class ApiConstants {
  ApiConstants._();

  // Android emulator reaches the host machine via 10.0.2.2.
  // Docker exposes ERPNext through nginx on port 8080 (not 8000).
  // Change to your server's IP/hostname for physical device or production.
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Frappe uses the Host header to identify which site to serve.
  // This must match the SITE_NAME configured in docker-compose.yaml.
  static const String frappeSiteName = 'site1.localhost';

  // Auth endpoints
  static const String mobileLogin =
      '/api/method/standup.api.auth.mobile_login';
  static const String logout = '/api/method/standup.api.auth.logout';
  static const String me = '/api/method/standup.api.auth.me';
  static const String refreshToken =
      '/api/method/standup.api.auth.refresh_token';

  // Secure-storage keys
  static const String keyApiKey = 'api_key';
  static const String keyApiSecret = 'api_secret';
}
