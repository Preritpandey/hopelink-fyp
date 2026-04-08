class ApiEndpoints {
  // static const String baseUrl =
  //     'http://192.168.1.65:3008/api/v1'; // home network
  // static const String baseUrl = 'http://10.22.3.27:3008/api/v1'; // cg2.4.
  // static const String baseUrl = 'http://10.0.2.2:3008/api/v1';
  static const String baseUrl = 'http://10.24.2.220:3008/api/v1';

  // static const String baseUrl = 'http://10.24.1.217:3008/api/v1'; // college
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
  static String get campaigns => '$baseUrl/campaigns';
  static String get closedCampaigns => '$baseUrl/campaigns/closed';
  static String get upcomingCampaigns => '$baseUrl/campaigns/upcoming';
  static String get events => '$baseUrl/events';

  // User profile
  static String get updateProfile => '$baseUrl/user/profile';
  static String get uploadProfilePhoto => '$baseUrl/user/profile/photo';
  static String get uploadCV => '$baseUrl/user/profile/cv';
  static String get userActivities => '$baseUrl/users/me/activities';

  // Volunteer job
  static String get volunteerJobs => '$baseUrl/volunteer-jobs';

  // Payment
  static String get createPaymentIntent => '$baseUrl/payments/stripe/init';
  static String get verrifyPayment => '$baseUrl/payments/stripe/verify';
  static String get completePayment => '$baseUrl/donations/complete-payment';
  static String get khaltiInitPayment => '$baseUrl/payments/khalti/init';
  static String get khaltiCompletePayment =>
      '$baseUrl/donations/complete-khalti-payment';

  // Products
  static String get products => '$baseUrl/products';
}
