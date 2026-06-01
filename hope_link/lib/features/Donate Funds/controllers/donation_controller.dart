import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:hope_link/config/payment_config.dart';
import 'package:hope_link/core/services/payment_service.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_controller.dart';
import '../models/campaign_model.dart';

enum DonationPaymentMethod { stripe, khalti }

class DonationController extends GetxController {
  DonationController({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController platformSupportAmountController =
      TextEditingController();

  final RxInt selectedAmount = 0.obs;
  final RxInt customAmount = 0.obs;
  final RxBool supportPlatform = false.obs;
  final RxInt selectedPlatformSupportAmount = 0.obs;
  final RxBool isAnonymous = false.obs;
  final RxBool isProcessing = false.obs;
  final Rx<DonationPaymentMethod> paymentMethod =
      DonationPaymentMethod.stripe.obs;

  Campaign? campaign;

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(() {
      if (selectedAmount.value == 0) {
        customAmount.value = int.tryParse(amountController.text) ?? 0;
      }
    });
    platformSupportAmountController.addListener(() {
      selectedPlatformSupportAmount.value =
          int.tryParse(platformSupportAmountController.text) ?? 0;
    });
  }

  void setCampaign(Campaign camp) {
    campaign = camp;
  }

  void setAmount(int amount) {
    selectedAmount.value = amount;
    customAmount.value = amount;
    amountController.text = amount.toString();
  }

  void setPlatformSupport(bool value) {
    supportPlatform.value = value;
    if (!value) {
      selectedPlatformSupportAmount.value = 0;
      platformSupportAmountController.clear();
    } else if (selectedPlatformSupportAmount.value == 0) {
      setPlatformSupportAmount(50);
    }
  }

  void setPlatformSupportAmount(int amount) {
    supportPlatform.value = amount > 0;
    selectedPlatformSupportAmount.value = amount;
    platformSupportAmountController.text = amount > 0 ? amount.toString() : '';
  }

  void setPaymentMethod(DonationPaymentMethod method) {
    paymentMethod.value = method;
  }

  Future<void> processDonation() async {
    // Check authentication first
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final isLoggedIn =
        (prefs.getBool('is_logged_in') ?? false) && token.isNotEmpty;

    if (!isLoggedIn || token.isEmpty) {
      Get.snackbar(
        'Authentication Required',
        'Please log in to make a donation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red.withOpacity(0.9),
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );

      // Navigate to login page
      Get.offAllNamed('/login');
      return;
    }

    if (campaign == null) return;

    try {
      isProcessing.value = true;

      final amount = _resolveAmount();

      if (amount < 100) {
        Get.snackbar(
          'Invalid Amount',
          'Minimum donation is NPR 100',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.red.withOpacity(0.9),
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      if (paymentMethod.value == DonationPaymentMethod.khalti) {
        await _processKhaltiDonation(amount);
      } else {
        await _processStripeDonation(amount);
      }
    } catch (e) {
      print('[Donation] Error: $e');
      Get.snackbar(
        'Error',
        'Failed to process donation: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red.withOpacity(0.9),
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  int _resolveAmount() {
    return selectedAmount.value > 0
        ? selectedAmount.value
        : int.tryParse(amountController.text) ?? 0;
  }

  int _resolvePlatformSupportAmount() {
    if (!supportPlatform.value) return 0;
    return selectedPlatformSupportAmount.value > 0
        ? selectedPlatformSupportAmount.value
        : int.tryParse(platformSupportAmountController.text) ?? 0;
  }

  int get totalPayableAmount =>
      _resolveAmount() + _resolvePlatformSupportAmount();

  Future<void> _processStripeDonation(int amount) async {
    try {
      final platformSupportAmount = _resolvePlatformSupportAmount();
      final totalAmount = amount + platformSupportAmount;
      final amountInPaisa = totalAmount * 100; // convert NPR to paisa
      final paymentIntentId = await _paymentService.processStripePayment(
        initializePayment: () async {
          final res = await _authorizedPost(
            ApiEndpoints.createPaymentIntent,
            data: {
              'amount': amountInPaisa,
              'currency': 'npr',
              'type': 'donation',
              'campaignId': campaign!.id,
              'metadata': {
                'campaignAmount': amount.toString(),
                'platformSupportAmount': platformSupportAmount.toString(),
                'supportPlatform': (platformSupportAmount > 0).toString(),
              },
            },
          );
          return Map<String, dynamic>.from(res.data['data'] as Map);
        },
        verifyPayment: (paymentIntentId) async {
          final verifyRes = await _authorizedPost(
            ApiEndpoints.verrifyPayment,
            data: {'paymentIntentId': paymentIntentId},
          );
          final verified = verifyRes.data['data'];
          return verified != null &&
              (verified['status'] as String?) == 'succeeded';
        },
      );

      await _completeStripeDonation(
        paymentIntentId,
        campaignAmount: amount,
        platformSupportAmount: platformSupportAmount,
        totalAmount: totalAmount,
      );
    } catch (e) {
      print('[Donation] Stripe payment error: $e');
      if (e is dio.DioException) {
        print('[Donation] DioException status code: ${e.response?.statusCode}');
        print('[Donation] DioException message: ${e.message}');
        print('[Donation] DioException response body: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          _handleAuthError();
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> _processKhaltiDonation(int amount) async {
    try {
      if (PaymentConfig.khaltiPublicKey == null ||
          PaymentConfig.khaltiPublicKey!.isEmpty) {
        await PaymentConfig.fetch();
      }

      if (PaymentConfig.khaltiPublicKey == null ||
          PaymentConfig.khaltiPublicKey!.isEmpty) {
        Get.snackbar(
          'Configuration Error',
          'Khalti is not configured. Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.red.withOpacity(0.9),
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      final context = Get.context;
      if (context == null) {
        Get.snackbar(
          'Error',
          'Unable to start Khalti payment. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.red.withOpacity(0.9),
          colorText: AppColors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      final platformSupportAmount = _resolvePlatformSupportAmount();
      final totalAmount = amount + platformSupportAmount;
      final amountInPaisa = totalAmount * 100;
      await _paymentService.processKhaltiPayment(
        context: context,
        publicKey: PaymentConfig.khaltiPublicKey!,
        environment: _resolveKhaltiEnvironment(),
        initializePayment: () async {
          final initRes = await _authorizedPost(
            ApiEndpoints.khaltiInitPayment,
            data: {
              'amount': amountInPaisa,
              'purchaseOrderId': campaign!.id,
              'purchaseOrderName': campaign!.title,
            },
          );
          return Map<String, dynamic>.from(
            (initRes.data['data'] ?? initRes.data) as Map,
          );
        },
        onPaymentSuccess: (paidPidx) async {
          try {
            await _completeKhaltiDonation(
              paidPidx,
              amountInPaisa,
              campaignAmount: amount,
              platformSupportAmount: platformSupportAmount,
              totalAmount: totalAmount,
            );
          } on dio.DioException catch (e) {
            print(
              '[Donation] Khalti completion Dio error body: ${e.response?.data}',
            );
            if (e.response?.statusCode == 401) {
              _handleAuthError(logoutUser: false);
              Get.snackbar(
                'Payment Pending Review',
                'Your Khalti payment may have succeeded, but we could not verify it with your current session. Please refresh and check your donation history.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.orange.withOpacity(0.9),
                colorText: AppColors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                duration: const Duration(seconds: 5),
              );
            } else {
              rethrow;
            }
          } catch (e) {
            print('[Donation] Khalti completion fallback error: $e');
            Get.snackbar(
              'Payment Received',
              'Your payment was successful but we encountered an issue recording the donation. Our team will verify it shortly.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.orange.withOpacity(0.9),
              colorText: AppColors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              duration: const Duration(seconds: 5),
            );
          }
        },
        confirmationTitle: 'Confirming Payment',
        confirmationMessage:
            'Your Khalti payment was received. We are finalizing your donation in the app.',
      );
    } catch (e) {
      print('[Donation] Khalti payment error: $e');
      if (e is dio.DioException) {
        print('[Donation] DioException status code: ${e.response?.statusCode}');
        print('[Donation] DioException message: ${e.message}');
        print('[Donation] DioException response body: ${e.response?.data}');
        if (_isKhaltiCredentialError(e)) {
          _showKhaltiConfigurationError();
          return;
        }
        if (e.response?.statusCode == 401) {
          _handleAuthError();
          return;
        }
      }
      rethrow;
    }
  }

  Future<void> _completeStripeDonation(
    String paymentIntentId, {
    required int campaignAmount,
    required int platformSupportAmount,
    required int totalAmount,
  }) async {
    try {
      final completeRes = await _authorizedPost(
        ApiEndpoints.completePayment,
        data: {
          'paymentIntentId': paymentIntentId,
          'amount': totalAmount,
          'campaignAmount': campaignAmount,
          'platformSupportAmount': platformSupportAmount,
          'totalAmount': totalAmount,
          'supportPlatform': platformSupportAmount > 0,
          'campaignId': campaign!.id,
          'isAnonymous': isAnonymous.value,
          'message': messageController.text,
        },
      );

      print('[Donation] Complete payment response: ${completeRes.data}');
      await _updateCampaignCache();
      _showSuccessDialog(totalAmount);
      _clearForm();
    } catch (e) {
      print('[Donation] Error creating donation record: $e');
      rethrow;
    }
  }

  Future<void> _completeKhaltiDonation(
    String pidx,
    int amountInPaisa, {
    required int campaignAmount,
    required int platformSupportAmount,
    required int totalAmount,
  }) async {
    print(
      '[Donation] Completing Khalti donation with pidx=$pidx amountInPaisa=$amountInPaisa campaignId=${campaign?.id}',
    );
    final completeRes = await _authorizedPost(
      ApiEndpoints.khaltiCompletePayment,
      data: {
        'pidx': pidx,
        'amount': amountInPaisa,
        'campaignAmount': campaignAmount,
        'platformSupportAmount': platformSupportAmount,
        'totalAmount': totalAmount,
        'supportPlatform': platformSupportAmount > 0,
        'campaignId': campaign!.id,
        'isAnonymous': isAnonymous.value,
        'message': messageController.text,
      },
    );

    print('[Donation] Complete Khalti payment response: ${completeRes.data}');
    _dismissActiveDialog();
    await _updateCampaignCache();
    _showSuccessDialog(totalAmount);
    _clearForm();
  }

  Future<dio.Dio> _buildAuthorizedDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      Get.snackbar(
        'Authentication Required',
        'Please log in again to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red.withOpacity(0.9),
        colorText: AppColors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      throw Exception('Unauthorized: missing auth token');
    }
    print('[Donation] Creating Dio with token: ${token.substring(0, 10)}...');
    return dio.Dio(
      dio.BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<dio.Dio> _buildAuthorizedDioWithRetry() async {
    try {
      return await _buildAuthorizedDio();
    } catch (e) {
      // If token is missing, don't retry
      rethrow;
    }
  }

  Future<dio.Response<dynamic>> _authorizedPost(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    final dioClient = await _buildAuthorizedDioWithRetry();
    try {
      print('[Donation] POST request to: $url');
      final response = await dioClient.post(url, data: data);
      print('[Donation] POST response status: ${response.statusCode}');
      return response;
    } catch (e) {
      if (e is dio.DioException) {
        print(
          '[Donation] Dio error - Status: ${e.response?.statusCode}, Message: ${e.message}',
        );
        print('[Donation] Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  bool _isKhaltiCredentialError(dio.DioException error) {
    final response = error.response?.data;
    if (response is! Map) return false;

    final rawError = response['error'];
    final rawMessage = response['message'];

    final source = rawError is Map ? rawError['source'] : null;
    final detail = rawError is Map ? rawError['detail'] : null;

    return source == 'khalti' ||
        (rawMessage is String &&
            rawMessage.toLowerCase().contains('khalti credentials')) ||
        (detail is String && detail.toLowerCase().contains('invalid token'));
  }

  void _showKhaltiConfigurationError() {
    Get.snackbar(
      'Khalti Configuration Error',
      'The server Khalti credentials are invalid or do not match the active Khalti environment. Please update the backend Khalti keys and try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.red.withOpacity(0.9),
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 5),
    );
  }

  void _handleAuthError({bool logoutUser = false}) {
    Get.snackbar(
      'Session Expired',
      logoutUser
          ? 'Your session has expired. Please log in again.'
          : 'Your session could not be verified for this payment request. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.orange.withOpacity(0.9),
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
    if (logoutUser) {
      logout();
    }
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final isLoggedIn =
        (prefs.getBool('is_logged_in') ?? false) && token.isNotEmpty;
    return isLoggedIn && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    Get.offAllNamed('/login');
  }

  Future<void> _updateCampaignCache() async {
    try {
      final campaignController = Get.isRegistered<CampaignController>()
          ? Get.find<CampaignController>()
          : null;

      if (campaignController != null) {
        final updated = await campaignController.getCampaignById(campaign!.id);
        if (updated != null) {
          final idx = campaignController.campaigns.indexWhere(
            (c) => c.id == updated.id,
          );
          if (idx >= 0) {
            campaignController.campaigns[idx] = updated;
          } else {
            campaignController.campaigns.add(updated);
          }
          campaignController.applyFilters();
        }
      }
    } catch (e) {
      print('[Donation] Error updating local campaign cache: $e');
    }
  }

  void _showSuccessDialog(int amount) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your donation of NPR ${amount.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')} has been received.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will receive a confirmation email shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.grey600),
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
                    backgroundColor: AppColors.purple,
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
                      color: AppColors.white,
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
  }

  void _showPaymentConfirmationDialog() {
    _dismissActiveDialog();
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirming Payment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Khalti payment was received. We are finalizing your donation in the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.grey700),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _dismissActiveDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void _closeKhaltiCheckout(
    Khalti khalti,
    BuildContext context,
    Completer<void> completer, {
    required bool alreadyClosed,
  }) {
    if (!alreadyClosed) {
      khalti.close(context);
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  Environment _resolveKhaltiEnvironment() {
    final env = PaymentConfig.khaltiEnvironment.toLowerCase();
    if (env == 'prod' || env == 'production' || env == 'live') {
      return Environment.prod;
    }
    return Environment.test;
  }

  void _clearForm() {
    amountController.clear();
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    messageController.clear();
    platformSupportAmountController.clear();
    selectedAmount.value = 0;
    customAmount.value = 0;
    supportPlatform.value = false;
    selectedPlatformSupportAmount.value = 0;
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
    platformSupportAmountController.dispose();
    super.onClose();
  }
}
