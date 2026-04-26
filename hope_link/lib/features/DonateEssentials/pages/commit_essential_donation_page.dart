import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/donate_essentials_controller.dart';
import '../models/essential_models.dart';

class CommitEssentialDonationPage extends StatelessWidget {
  const CommitEssentialDonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DonateEssentialsController>()
        ? Get.find<DonateEssentialsController>()
        : Get.put(DonateEssentialsController());
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Commit Donation',
          style: GoogleFonts.dmSans(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Obx(() {
        final request = controller.selectedRequest.value;
        if (request == null) {
          return const Center(child: Text('No request selected'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                title: request.title,
                child: Column(
                  children:
                      request.reporting.items.map((item) {
                        EssentialItemNeed? source;
                        for (final need in request.itemsNeeded) {
                          if (need.itemName.toLowerCase() == item.itemName.toLowerCase()) {
                            source = need;
                            break;
                          }
                        }
                        if (source == null) {
                          return const SizedBox.shrink();
                        }
                        final fieldController = controller.quantityControllers[source.id]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: fieldController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  '${item.itemName} (${item.quantityRemaining} ${item.unit} remaining)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              helperText: 'Enter 0 to skip this item',
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Pickup Location',
                child: Column(
                  children:
                      request.pickupLocations.map((location) {
                        return Obx(
                          () => RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: location.id,
                            groupValue: controller.selectedPickupLocationId.value,
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedPickupLocationId.value = value;
                              }
                            },
                            title: Text(location.address),
                            subtitle: Text(
                              '${location.contactPerson} | ${location.availableTimeSlots}',
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Delivery Date',
                child: Obx(
                  () => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      controller.selectedDeliveryDate.value == null
                          ? 'Choose a delivery date'
                          : DateFormat('EEE, MMM d, yyyy').format(
                              controller.selectedDeliveryDate.value!,
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            controller.selectedDeliveryDate.value ??
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: request.expiryDate,
                      );
                      if (picked != null) {
                        controller.selectedDeliveryDate.value = picked;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _section(
                title: 'Optional Proof Image',
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.pickProofImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          controller.proofImageName.value.isEmpty
                              ? 'Select Image'
                              : controller.proofImageName.value,
                        ),
                      ),
                      if (controller.proofImageBytes.value != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            controller.proofImageBytes.value!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Obx(
          () => FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: controller.isSubmittingCommitment.value
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm pledge'),
                        content: const Text(
                          'You are about to commit these essentials for delivery. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final success = await controller.submitCommitment();
                      if (success) {
                        Get.back();
                        Get.toNamed('/essential-commitments');
                      }
                    }
                  },
            child: controller.isSubmittingCommitment.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Commitment'),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
