import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../controllers/donate_essentials_controller.dart';
import '../models/essential_models.dart';

class EssentialRequestsPage extends StatefulWidget {
  const EssentialRequestsPage({super.key});

  @override
  State<EssentialRequestsPage> createState() => _EssentialRequestsPageState();
}

class _EssentialRequestsPageState extends State<EssentialRequestsPage> {
  late final DonateEssentialsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DonateEssentialsController>()
        ? Get.find<DonateEssentialsController>()
        : Get.put(DonateEssentialsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Donate Essentials',
          style: GoogleFonts.dmSans(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Get.toNamed('/essential-commitments'),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('My Commitments'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadRequests(forceRefresh: true),
        child: Column(
          children: [
            _filterBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingRequests.value &&
                    controller.requests.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.requests.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No essential requests found')),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: controller.requests.length,
                  itemBuilder: (context, index) {
                    final request = controller.requests[index];
                    return _RequestCard(
                      request: request,
                      onTap: () async {
                        await controller.loadRequestDetail(request.id);
                        Get.toNamed('/essential-requests');
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    const categories = ['all', 'food', 'clothes', 'medicine', 'other'];
    const urgencies = ['all', 'high', 'medium', 'low'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse urgent item requests and pledge what you can deliver.',
            style: GoogleFonts.dmSans(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.toUpperCase()),
                        selected: controller.selectedCategory.value == category,
                        onSelected: (_) => controller.applyFilters(category: category),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...urgencies.map(
                    (urgency) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('Urgency: ${urgency.toUpperCase()}'),
                        selected: controller.selectedUrgency.value == urgency,
                        onSelected: (_) => controller.applyFilters(urgency: urgency),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final EssentialRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = request.fulfillmentRatio;
    final formatter = DateFormat('MMM d');
    final urgencyColor =
        request.urgencyLevel == 'high'
            ? Colors.redAccent
            : request.urgencyLevel == 'medium'
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColorToken.primary.color.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    request.urgencyLevel.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: urgencyColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: AppColorToken.primary.color,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${request.reporting.totals.quantityFulfilled}/${request.reporting.totals.quantityRequired} fulfilled',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  'Ends ${formatter.format(request.expiryDate)}',
                  style: GoogleFonts.dmSans(color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  request.reporting.items
                      .take(3)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${item.itemName} (${item.quantityRemaining} ${item.unit} left)',
                            style: GoogleFonts.dmSans(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
