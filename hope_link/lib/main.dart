import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hope_link/config/hive_config.dart';
import 'package:hope_link/features/Auth/pages/otp_verification_page.dart';
import 'package:hope_link/features/Auth/pages/user_registration_page.dart';
import 'package:hope_link/features/Auth/pages/login_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/campaign_details_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/campaigns_list_page.dart';
import 'package:hope_link/features/Donate%20Funds/pages/donate_page.dart';
import 'package:hope_link/features/Home/pages/home_screen.dart';
import 'package:hope_link/features/Onboarding/pages/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveConfig.initialize();
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final isLoggedIn =
      (prefs.getBool('is_logged_in') ?? false) && token.isNotEmpty;
  // Fetch publishable key from backend before starting app
  await StripeConfig.fetchPublishableKey();
  // Configure Stripe publishable key (may be null if fetch failed)
  if (StripeConfig.publishableKey != null &&
      StripeConfig.publishableKey!.isNotEmpty) {
    Stripe.publishableKey = StripeConfig.publishableKey!;
    Stripe.merchantIdentifier = 'merchant.com.example';
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

        GetPage(
          name: '/campaigns',
          page: () => const CampaignsListPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/campaign-details',
          page: () => const CampaignDetailsPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/donate',
          page: () => const DonatePage(),
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
