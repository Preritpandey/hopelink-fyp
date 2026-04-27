import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/hive_config.dart';
import 'package:hope_link/features/Auth/pages/otp_verification_page.dart';
import 'package:hope_link/features/Auth/pages/user_registration_page.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
import 'package:hope_link/features/Commerce/pages/cart_page.dart';
import 'package:hope_link/features/Commerce/pages/checkout_page.dart';
import 'package:hope_link/features/Commerce/pages/order_detail_page.dart';
import 'package:hope_link/features/Commerce/pages/orders_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/campaign_details_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/all_campaigns_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/all_volunteer_jobs_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/campaigns_list_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/donate_page.dart';
import 'package:hope_link/features/DonateEssentials/pages/commit_essential_donation_page.dart';
import 'package:hope_link/features/DonateEssentials/pages/essential_request_detail_page.dart';
import 'package:hope_link/features/DonateEssentials/pages/essential_requests_page.dart';
import 'package:hope_link/features/DonateEssentials/pages/my_essential_commitments_page.dart';
import 'package:hope_link/features/Home/pages/home_screen.dart';
import 'package:hope_link/features/Onboarding/pages/splash_screen.dart';
import 'package:hope_link/features/OrganizationProfile/pages/organization_profile_page.dart';
import 'package:hope_link/features/Profile/pages/saved_causes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config/payment_config.dart';
import 'features/Donate Funds/pages/volunteer_job_details_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveConfig.initialize();
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final isLoggedIn =
      (prefs.getBool('is_logged_in') ?? false) && token.isNotEmpty;
  // Fetch payment config from backend before starting app
  await PaymentConfig.fetch();
  // Configure Stripe publishable key (may be null if fetch failed)
  if (PaymentConfig.stripePublishableKey != null &&
      PaymentConfig.stripePublishableKey!.isNotEmpty) {
    Stripe.publishableKey = PaymentConfig.stripePublishableKey!;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      Stripe.merchantIdentifier = 'merchant.com.example';
    }
    await Stripe.instance.applySettings();
  }

  runApp(MyApp(prefs: prefs, isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final bool isLoggedIn;

  const MyApp({super.key, required this.prefs, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Put the SharedPreferences instance in the dependency injection
    return GetMaterialApp(
      title: 'Hope Link',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/signup', page: () => const SignUpPage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/campaigns-all', page: () => const AllCampaignsPage()),
        GetPage(
          name: '/volunteer-jobs-all',
          page: () => AllVolunteerJobsPage(),
        ),

        GetPage(
          name: '/volunteer-job-details',
          page: () => const VolunteerJobDetailsPage(),
        ),

        GetPage(
          name: '/campaigns',
          page: () => const CampaignsListPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/campaigns-all',
          page: () => const AllCampaignsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/volunteer-jobs-all',
          page: () => const AllVolunteerJobsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/campaign-details',
          page: () => const CampaignDetailsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/organization-profile',
          page: () => const OrganizationProfilePage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/saved-causes',
          page: () => const SavedCausesPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/donate',
          page: () => const DonatePage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/essentials',
          page: () => const EssentialRequestsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/essential-requests',
          page: () => const EssentialRequestDetailPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/essential-commit',
          page: () => const CommitEssentialDonationPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/essential-commitments',
          page: () => const MyEssentialCommitmentsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/verify-otp',
          page: () => OtpVerificationPage(
            email: (Get.arguments is Map && Get.arguments.containsKey('email'))
                ? Get.arguments['email']
                : '',
            token: (Get.arguments is Map && Get.arguments.containsKey('token'))
                ? Get.arguments['token']
                : '',
          ),
        ),
        GetPage(
          name: '/cart',
          page: () => CartPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/checkout',
          page: () => CheckoutPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/orders',
          page: () => OrdersPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/orders/details',
          page: () => OrderDetailPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/home',
          page: () {
            final token = prefs.getString('auth_token') ?? '';
            if (token.isEmpty) {
              Future.microtask(() => Get.offAllNamed('/login'));
              return const SizedBox.shrink();
            }
            return HomePage(token: token);
          },
        ),
      ],
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(body: Center(child: Text('Page not found'))),
      ),
    );
  }
}
