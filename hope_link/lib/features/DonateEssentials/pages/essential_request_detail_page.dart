import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/features/DonateEssentials/controllers/donate_essentials_controller.dart';
import 'package:hope_link/features/DonateEssentials/models/essential_models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EssentialRequestDetailPage extends StatelessWidget {
  const EssentialRequestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DonateEssentialsController>()
        ? Get.find<DonateEssentialsController>()
        : Get.put(DonateEssentialsController());
    return Scaffold(
      backgroundColor: AppColors.inputFill,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Request Details',
          style: GoogleFonts.dmSans(
            color: AppColors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Obx(() {
        final request = controller.selectedRequest.value;
        if (request == null) {
          return const Center(child: Text('Request not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroCard(request),
              const SizedBox(height: 16),
              _itemsCard(request),
              const SizedBox(height: 16),
              _locationCard(request),
              const SizedBox(height: 16),
              _impactCard(request),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final request = controller.selectedRequest.value;
        if (request == null) return const SizedBox.shrink();

        return SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: request.isExpired || request.status == 'fulfilled'
                ? null
                : () {
                    controller.startCommitFlow(request);
                    Get.toNamed('/essential-commit');
                  },
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: Text(
              request.status == 'fulfilled'
                  ? 'Request Fulfilled'
                  : request.isExpired
                  ? 'Request Expired'
                  : 'Commit Donation',
            ),
          ),
        );
      }),
    );
  }

  Widget _heroCard(EssentialRequest request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal,
            request.isUrgent ? AppColors.redDark : AppColors.blueDark,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.urgencyLevel.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            style: GoogleFonts.dmSans(
              color: AppColors.white.withOpacity(0.88),
              height: 1.5,
            ),
          ),
          if (request.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    request.images[index],
                    width: 180,
                    height: 124,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 180,
                      height: 124,
                      color: AppColors.white,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Needed', '${request.reporting.totals.quantityRequired}'),
              const SizedBox(width: 12),
              _metric(
                'Fulfilled',
                '${request.reporting.totals.quantityFulfilled}',
              ),
              const SizedBox(width: 12),
              _metric(
                'Remaining',
                '${request.reporting.totals.quantityRemaining}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(color: AppColors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard(EssentialRequest request) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items Needed',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...request.reporting.items.map((item) {
            final ratio = item.quantityRequired <= 0
                ? 0.0
                : (item.quantityFulfilled / item.quantityRequired).clamp(0, 1)
                      as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantityFulfilled}/${item.quantityRequired} ${item.unit}',
                        style: GoogleFonts.dmSans(color: AppColors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 9,
                      backgroundColor: AppColors.grey200,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.quantityRemaining} ${item.unit} still needed',
                    style: GoogleFonts.dmSans(
                      color: AppColors.black,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _locationCard(EssentialRequest request) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Locations',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...request.pickupLocations.map((location) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location.address,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openMap(location),
                        child: const Text('Open Map'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${location.contactPerson} | ${location.contactPhone}',
                    style: GoogleFonts.dmSans(color: AppColors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    location.availableTimeSlots,
                    style: GoogleFonts.dmSans(color: AppColors.black54),
                  ),
                  const SizedBox(height: 10),
                  _MapPreview(
                    height: 120,
                    latitude: location.latitude,
                    longitude: location.longitude,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _impactCard(EssentialRequest request) {
    final families = (request.reporting.totals.quantityFulfilled / 5).floor();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              families > 0
                  ? 'This request has already helped about $families families through verified essentials.'
                  : 'Your pledge can be one of the first verified deliveries for this request.',
              style: GoogleFonts.dmSans(height: 1.5),
            ),
          ),
          Text(
            DateFormat('MMM d').format(request.expiryDate),
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: AppColors.black54,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(15, 33, 63, 0.08),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );

  Future<void> _openMap(PickupLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.latitude,
    required this.longitude,
    required this.height,
  });

  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hope_link',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 46,
                  height: 46,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.redDark,
                    size: 34,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
