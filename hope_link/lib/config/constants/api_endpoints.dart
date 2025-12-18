class ApiEndpoints {
  // static const String baseUrl = 'http://localhost:3008/api/v1';
  static const String baseUrl = 'http://192.168.1.95:3008/api/v1'; // cg2.4

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getProfile => '$baseUrl/auth/me';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resendOtp => '$baseUrl/auth/resend-otp';

  // User profile endpoints
  static String get updateProfile => '$baseUrl/user/profile';
  static String get uploadProfilePhoto => '$baseUrl/user/profile/photo';
  static String get uploadCV => '$baseUrl/user/profile/cv';
}
