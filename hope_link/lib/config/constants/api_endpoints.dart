class ApiEndpoints {
  // static const String baseUrl =
  //     'http://192.168.1.65:3008/api/v1'; // home network
  // static const String baseUrl = 'http://10.22.3.27:3008/api/v1'; // cg2.4.
  // static const String baseUrl = 'http://10.0.2.2:3008/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:3008/api/v1';

  static const String baseUrl = 'http://192.168.18.48:3008/api/v1'; // college
  //   static const String baseUrl = 'http://localhost:3008/api/v1'; // college

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
  static String campaignReportById(String campaignId) =>
      '$baseUrl/campaign-reports/campaign/$campaignId';
  static String get closedCampaigns => '$baseUrl/campaigns/closed';
  static String get upcomingCampaigns => '$baseUrl/campaigns/upcoming';
  static String get events => '$baseUrl/events';

  // User profile
  static String get updateProfile => '$baseUrl/user/profile';
  static String get uploadProfilePhoto => '$baseUrl/user/profile/photo';
  static String get uploadCV => '$baseUrl/user/profile/cv';
  static String get userActivities => '$baseUrl/users/me/activities';
  static String get volunteerCredits => '$baseUrl/volunteer-credits/me';

  // Volunteer job
  static String get volunteerJobs => '$baseUrl/volunteer-jobs';
  static String postLike(String postId) => '$baseUrl/posts/$postId/like';
  static String postUnlike(String postId) => '$baseUrl/posts/$postId/unlike';
  static String postComments(String postId) =>
      '$baseUrl/posts/$postId/comments';
  static String deleteComment(String commentId) =>
      '$baseUrl/comments/$commentId';

  // Organization profile
  static String organizationProfile(String organizationId) =>
      '$baseUrl/organizations/$organizationId/public-profile';
  static String organizationPosts(String organizationId) =>
      '$baseUrl/organizations/$organizationId/posts';
  static String organizationProfileFeed(String organizationId) =>
      '$baseUrl/organizations/$organizationId/profile-feed';

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
