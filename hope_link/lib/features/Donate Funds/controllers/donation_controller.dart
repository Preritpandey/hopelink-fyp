import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/campaign_model.dart';

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

      // Create donation record
      final donation = {
        'campaignId': campaign!.id,
        'campaignTitle': campaign!.title,
        'amount': amount,
        'donorName': isAnonymous.value ? 'Anonymous' : nameController.text,
        'email': emailController.text,
        'phone': phoneController.text.isEmpty ? null : phoneController.text,
        'message': messageController.text.isEmpty
            ? null
            : messageController.text,
        'isAnonymous': isAnonymous.value,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending', // In real app, this would be updated after payment
      };

      // Save to local storage (Hive)
      final box = await Hive.openBox('donations');
      final donationId = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(donationId, donation);

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Show success dialog
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      Get.snackbar(
        'Error',
        'Failed to process donation. Please try again.',
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
