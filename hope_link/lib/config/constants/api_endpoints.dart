class ApiEndpoints {
  // static const String baseUrl =
  //     'http://192.168.1.65:3008/api/v1'; // home network
  // static const String baseUrl = 'http://192.168.1.94:3008/api/v1';// cg5.
  // static const String baseUrl = 'http://10.21.6.154:3008/api/v1';
  static const String baseUrl =
      'http://10.0.2.2:3008/api/v1'; // android emulator

  // static const String baseUrl = 'http://192.168.1.94:3008/api/v1'; // cg2.4

  // Auth 
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getProfile => '$baseUrl/auth/me';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resendOtp => '$baseUrl/auth/resend-otp';

  // Campaign and events 
  static String get campaigns => '$baseUrl/campaigns';
  static String get events => '$baseUrl/events';

  // User profile 
  static String get updateProfile => '$baseUrl/user/profile';
  static String get uploadProfilePhoto => '$baseUrl/user/profile/photo';
  static String get uploadCV => '$baseUrl/user/profile/cv';

  // Volunteer job 
  static String get volunteerJobs => '$baseUrl/volunteer-jobs';

  // Payment 
  static String get createPaymentIntent => '$baseUrl/payments/stripe/init';
  static String get verrifyPayment => '$baseUrl/payments/stripe/verify';
  static String get completePayment => '$baseUrl/donations/complete-payment';
}
