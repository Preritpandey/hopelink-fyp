class ApiEndpoints {
  // static const String baseUrl =
  //     'http://192.168.1.65:3008/api/v1'; // home network
  // static const String baseUrl = 'http://10.22.3.27:3008/api/v1'; // cg2.4.
  // static const String baseUrl = 'http://10.21.6.154:3008/api/v1';
  // static const String baseUrl =
  // 'http://192.168.1.96:3008/api/v1'; // android emulator

  static const String baseUrl = 'http://localhost:3008/api/v1'; // college
  // static const String baseUrl = 'http://localhost:3008/api/v1'; // college

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getProfile => '$baseUrl/auth/me';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resendOtp => '$baseUrl/auth/resend-otp';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';

  // Campaign and events

  // Volunteer job
  static String get volunteerJobs => '$baseUrl/volunteer-jobs';
}
