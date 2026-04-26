import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/donate_essentials_controller.dart';
import '../models/essential_models.dart';

class MyEssentialCommitmentsPage extends StatelessWidget {
  const MyEssentialCommitmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DonateEssentialsController>()
        ? Get.find<DonateEssentialsController>()
        : Get.put(DonateEssentialsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Commitments',
          style: GoogleFonts.dmSans(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadMyCommitments(forceRefresh: true),
        child: Obx(() {
          if (controller.isLoadingCommitments.value &&
              controller.myCommitments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final verifiedFamilies = controller.myCommitments
              .where((item) => item.status == 'verified')
              .fold<int>(
                0,
                (sum, item) => sum + controller.impactFamiliesForCommitment(item),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  verifiedFamilies > 0
                      ? 'You helped about $verifiedFamilies families through verified essentials.'
                      : 'Your pending and delivered pledges will show their impact here once verified.',
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.myCommitments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('No commitments yet')),
                ),
              ...controller.myCommitments.map(
                (commitment) => _CommitmentCard(
                  commitment: commitment,
                  controller: controller,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({
    required this.commitment,
    required this.controller,
  });

  final DonationCommitment commitment;
  final DonateEssentialsController controller;

  @override
  Widget build(BuildContext context) {
    final color = controller.statusColor(commitment.status);
    final label = controller.statusLabel(commitment.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  commitment.requestId.title,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                commitment.itemsDonating
                    .map(
                      (item) => Chip(
                        label: Text('${item.itemName} | ${item.quantity}'),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          _timeline(commitment),
          if (commitment.selectedPickupLocation != null) ...[
            const SizedBox(height: 10),
            Text(
              commitment.selectedPickupLocation!.address,
              style: GoogleFonts.dmSans(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                commitment.deliveryDate == null
                    ? 'Delivery date pending'
                    : 'Delivery ${DateFormat('MMM d, yyyy').format(commitment.deliveryDate!)}',
                style: GoogleFonts.dmSans(color: Colors.black45),
              ),
              const Spacer(),
              if (commitment.canMarkDelivered)
                Obx(
                  () => FilledButton.tonal(
                    onPressed: controller.isUpdatingStatus.value
                        ? null
                        : () async {
                            controller.selectedDeliveryDate.value =
                                commitment.deliveryDate ?? DateTime.now();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Mark as delivered'),
                                content: const Text(
                                  'Confirm that you delivered these items to the pickup location.',
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
                              await controller.markDelivered(commitment);
                            }
                          },
                    child: controller.isUpdatingStatus.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Mark Delivered'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeline(DonationCommitment commitment) {
    final currentIndex = switch (commitment.status) {
      'pledged' => 0,
      'delivered' => 1,
      'verified' => 2,
      'rejected' => 2,
      _ => 0,
    };

    final labels = [
      'Pending',
      'Delivered',
      commitment.status == 'rejected' ? 'Rejected' : 'Verified',
    ];

    return Row(
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final active = (index ~/ 2) < currentIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              color: active ? Colors.green : Colors.grey.shade300,
            ),
          );
        }

        final step = index ~/ 2;
        final active = step <= currentIndex;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.green : Colors.grey.shade300,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              labels[step],
              style: GoogleFonts.dmSans(fontSize: 11),
            ),
          ],
        );
      }),
    );
  }
}
