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

  // Commerce
  static String get orgOrders => '$baseUrl/orders/org-orders';
  static String orderDetails(String orderId) => '$baseUrl/orders/$orderId';
  static String orderStatus(String orderId) => '$baseUrl/orders/$orderId/status';
  static String get orgSalesSummary => '$baseUrl/orders/org-sales/summary';
  static String get orgProductSales => '$baseUrl/orders/org-sales/products';
  static String get products => '$baseUrl/products';
  static String product(String productId) => '$baseUrl/products/$productId';
  static String get categories => '$baseUrl/categories';

  // Essentials
  static String get essentialRequests => '$baseUrl/essential-requests';
  static String essentialRequestById(String requestId) =>
      '$baseUrl/essential-requests/$requestId';
  static String orgRequestCommitments(String requestId) =>
      '$baseUrl/org/requests/$requestId/commitments';
  static String commitDonationStatus(String commitmentId) =>
      '$baseUrl/commit-donation/$commitmentId/status';
}
