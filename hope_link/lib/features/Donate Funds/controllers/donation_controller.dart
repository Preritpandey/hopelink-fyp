import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/campaign_model.dart';
import 'campaign_controller.dart';

class DonationController extends GetxController {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final RxInt selectedAmount = 0.obs;
  final RxBool isAnonymous = false.obs;
  final RxBool isProcessing = false.obs;

  Campaign? campaign;

  void setCampaign(Campaign camp) {
    campaign = camp;
  }

  void setAmount(int amount) {
    selectedAmount.value = amount;
    amountController.text = amount.toString();
  }

  Future<void> processDonation() async {
    if (campaign == null) return;

    try {
      isProcessing.value = true;

      final amount = selectedAmount.value > 0
          ? selectedAmount.value
          : int.tryParse(amountController.text) ?? 0;

      if (amount < 100) {
        Get.snackbar(
          'Invalid Amount',
          'Minimum donation is NPR 100',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Validate Stripe is initialized
      if (Stripe.publishableKey.isEmpty) {
        Get.snackbar(
          'Configuration Error',
          'Payment system not initialized. Please restart the app.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Call backend to create Stripe PaymentIntent
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final amountInPaisa = amount * 100; // convert NPR to paisa

      print('[Donation] Creating payment intent with amount: $amountInPaisa');

      final res = await dio.post(
        ApiEndpoints.createPaymentIntent,
        data: {
          'amount': amountInPaisa,
          'currency': 'npr',
          'type': 'donation',
          'campaignId': campaign!.id,
        },
      );

      print('[Donation] Payment intent response: ${res.data}');

      final intent = res.data['data'];
      final clientSecret = intent['clientSecret'] as String?;
      final paymentIntentId = intent['id'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception(
          'Failed to create payment intent. Missing clientSecret or paymentIntentId',
        );
      }

      print('[Donation] Client secret: $clientSecret');
      print('[Donation] Payment intent ID: $paymentIntentId');

      // Initialize and present payment sheet
      try {
        print('[Donation] Initializing payment sheet...');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Hope Link',
            applePay: PaymentSheetApplePay(merchantCountryCode: 'NP'),
            googlePay: PaymentSheetGooglePay(
              merchantCountryCode: 'NP',
              testEnv: true,
            ),
            style: ThemeMode.light,
          ),
        );

        print('[Donation] Presenting payment sheet...');
        await Stripe.instance.presentPaymentSheet();
        print('[Donation] Payment sheet presented successfully');
      } catch (e) {
        print('[Donation] Payment sheet error: $e');
        // Payment failed / canceled
        if (e is StripeException) {
          Get.snackbar(
            'Payment Failed',
            e.error.message ?? 'Payment was cancelled',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
          return;
        }
        rethrow;
      }

      print('[Donation] Verifying payment on server...');

      // Verify on server
      final verifyRes = await dio.post(
        ApiEndpoints.verrifyPayment,
        data: {'paymentIntentId': paymentIntentId},
      );

      print('[Donation] Verify response: ${verifyRes.data}');

      final verified = verifyRes.data['data'];

      // Show success dialog only if server confirms succeeded
      if (verified != null && (verified['status'] as String?) == 'succeeded') {
        print('[Donation] Payment successful! Creating donation record...');

        // Create donation record and update campaign/organization
        try {
          final completeRes = await dio.post(
            ApiEndpoints.completePayment,
            data: {
              'paymentIntentId': paymentIntentId,
              'amount': amount,
              'campaignId': campaign!.id,
              'isAnonymous': isAnonymous.value,
              'message': messageController.text,
            },
          );

          print('[Donation] Complete payment response: ${completeRes.data}');

          // Update local cache and in-memory campaign list if possible
          try {
            final campaignController = Get.isRegistered<CampaignController>()
                ? Get.find<CampaignController>()
                : null;

            if (campaignController != null) {
              // Fetch updated campaign from API/local and replace in controller lists
              final updated = await campaignController.getCampaignById(
                campaign!.id,
              );
              if (updated != null) {
                final idx = campaignController.campaigns.indexWhere(
                  (c) => c.id == updated.id,
                );
                if (idx >= 0) {
                  campaignController.campaigns[idx] = updated;
                } else {
                  campaignController.campaigns.add(updated);
                }
                // Reapply filters so UI updates
                campaignController.applyFilters();
              }
            }
          } catch (e) {
            print('[Donation] Error updating local campaign cache: $e');
          }

          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Thank You!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your donation of NPR ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} has been received.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will receive a confirmation email shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(); // Close dialog
                          Get.back(); // Go back to campaign details
                          Get.back(); // Go back to campaigns list
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4CE6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: false,
          );

          // Clear form
          _clearForm();
        } catch (e) {
          print('[Donation] Error creating donation record: $e');
          Get.snackbar(
            'Payment Received',
            'Your payment was successful but we encountered an issue recording the donation. Our team will verify it shortly.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        throw Exception(
          'Payment verification failed. Status: ${verified?['status'] ?? 'unknown'}',
        );
      }
    } catch (e) {
      print('[Donation] Error: $e');
      Get.snackbar(
        'Error',
        'Failed to process donation: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void _clearForm() {
    amountController.clear();
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    messageController.clear();
    selectedAmount.value = 0;
    isAnonymous.value = false;
  }

  // Get donation history
  Future<List<Map<String, dynamic>>> getDonationHistory() async {
    try {
      final box = await Hive.openBox('donations');
      final donations = <Map<String, dynamic>>[];

      for (var key in box.keys) {
        final donation = box.get(key) as Map;
        donations.add({'id': key, ...Map<String, dynamic>.from(donation)});
      }

      // Sort by timestamp descending
      donations.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      return donations;
    } catch (e) {
      print('Error getting donation history: $e');
      return [];
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
