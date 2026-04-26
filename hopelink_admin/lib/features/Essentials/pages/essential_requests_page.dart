import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../Dashboard/widgets/dashboard_widgets.dart';
import '../controllers/essential_requests_controller.dart';
import '../models/essential_admin_models.dart';

class EssentialRequestsManagementPage extends StatefulWidget {
  const EssentialRequestsManagementPage({super.key});

  @override
  State<EssentialRequestsManagementPage> createState() =>
      _EssentialRequestsManagementPageState();
}

class _EssentialRequestsManagementPageState
    extends State<EssentialRequestsManagementPage> {
  late final EssentialRequestsController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(EssentialRequestsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Obx(() {
        final bundle = ctrl.selectedBundle.value;
        final selected = ctrl.selectedRequest.value;
        return Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _statsRow(bundle),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _filters(),
                              const SizedBox(height: 16),
                              _requestsTable(),
                            ],
                          ),
                        ),
                        if (selected != null) ...[
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 420,
                            child: _detailPanel(selected, bundle),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Essential Requests',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage in-kind donations, pickup points, and commitment verification.',
                style: GoogleFonts.dmSans(fontSize: 13, color: kTextSub),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => ctrl.fetchRequests(keepSelection: false),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Request'),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(AdminCommitmentBundle? bundle) {
    final requests = ctrl.requests;
    final active = requests.where((item) => item.status == 'active').length;
    final fulfilled = requests.where((item) => item.status == 'fulfilled').length;
    final highUrgency = requests.where((item) => item.urgencyLevel == 'high').length;
    final totalPending = requests.fold<int>(
      0,
      (sum, item) => sum + item.reporting.totals.quantityRemaining,
    );

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          label: 'Active Requests',
          value: '$active',
          icon: Icons.inventory_2_outlined,
          accent: kAccent,
        ),
        StatCard(
          label: 'High Urgency',
          value: '$highUrgency',
          icon: Icons.priority_high_rounded,
          accent: kRed,
        ),
        StatCard(
          label: 'Fulfilled',
          value: '$fulfilled',
          icon: Icons.verified_rounded,
          accent: kAccent2,
        ),
        StatCard(
          label: 'Still Needed',
          value: '$totalPending',
          icon: Icons.stacked_bar_chart_rounded,
          accent: kAmber,
          sub: bundle == null ? null : '${bundle.summary.totalCommitments} pledges',
        ),
      ],
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dropdown(
              value: ctrl.categoryFilter.value,
              label: 'Category',
              items: const ['all', 'food', 'clothes', 'medicine', 'other'],
              onChanged: (value) => ctrl.setFilters(category: value),
            ),
            _dropdown(
              value: ctrl.urgencyFilter.value,
              label: 'Urgency',
              items: const ['all', 'high', 'medium', 'low'],
              onChanged: (value) => ctrl.setFilters(urgency: value),
            ),
            if (ctrl.error.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ctrl.error.value,
                  style: GoogleFonts.dmSans(color: kRed),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _requestsTable() {
    return Obx(() {
      if (ctrl.isLoading.value && ctrl.requests.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: kAccent)),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Text(
                    'Requests',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${ctrl.requests.length} total',
                    style: GoogleFonts.dmSans(color: kTextSub),
                  ),
                ],
              ),
            ),
            const Divider(color: kBorder, height: 1),
            if (ctrl.requests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No essential requests found'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.requests.length,
                separatorBuilder: (_, __) => const Divider(color: kBorder, height: 1),
                itemBuilder: (context, index) {
                  final request = ctrl.requests[index];
                  final selected = ctrl.selectedRequest.value?.id == request.id;
                  return InkWell(
                    onTap: () async {
                      ctrl.selectedRequest.value = request;
                      await ctrl.fetchRequestBundle(request.id);
                    },
                    child: Container(
                      color: selected ? kSurface2 : Colors.transparent,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  request.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(color: kTextSub),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _pill(request.category, kAccent2),
                                const SizedBox(height: 8),
                                _pill(request.urgencyLevel, ctrl.statusColor(request.urgencyLevel)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: request.fulfillmentRatio,
                                    minHeight: 8,
                                    color: kAccent,
                                    backgroundColor: kBorder,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${request.reporting.totals.quantityFulfilled}/${request.reporting.totals.quantityRequired} fulfilled',
                                  style: GoogleFonts.dmSans(color: kTextSub),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          _pill(
                            ctrl.statusLabel(request.status),
                            ctrl.statusColor(request.status),
                          ),
                          IconButton(
                            onPressed: () => _openEditor(existing: request),
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(request),
                            icon: const Icon(Icons.delete_outline_rounded, color: kRed),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _detailPanel(
    AdminEssentialRequest selected,
    AdminCommitmentBundle? bundle,
  ) {
    final request = bundle?.request ?? selected;
    final commitments = bundle?.commitments ?? const <AdminDonationCommitment>[];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _pill(
                ctrl.statusLabel(request.status),
                ctrl.statusColor(request.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: GoogleFonts.dmSans(color: kTextSub, height: 1.5),
          ),
          if (request.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    request.images[index],
                    width: 150,
                    height: 116,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 150,
                      height: 116,
                      color: kSurface2,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Fulfillment Progress',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...request.reporting.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.itemName, style: _whiteBody()),
                      ),
                      Text(
                        '${item.quantityFulfilled}/${item.quantityRequired} ${item.unit}',
                        style: _subBody(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: item.quantityRequired <= 0
                          ? 0
                          : (item.quantityFulfilled / item.quantityRequired).clamp(0, 1),
                      minHeight: 8,
                      color: kAccent,
                      backgroundColor: kBorder,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Pickup Locations',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...request.pickupLocations.map(
            (location) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location.address, style: _whiteBody()),
                  const SizedBox(height: 6),
                  Text(
                    '${location.contactPerson} | ${location.contactPhone}',
                    style: _subBody(),
                  ),
                  const SizedBox(height: 10),
                  _MapPreviewCard(
                    latitude: location.latitude,
                    longitude: location.longitude,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${location.latitude}, ${location.longitude}',
                    style: GoogleFonts.dmMono(fontSize: 11, color: kAccent2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Donation Commitments',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (bundle != null)
                Text(
                  '${bundle.summary.totalCommitments} total',
                  style: _subBody(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (ctrl.isLoadingDetails.value)
            const Center(child: CircularProgressIndicator(color: kAccent))
          else if (commitments.isEmpty)
            Text('No commitments yet', style: _subBody())
          else
            ...commitments.map(
              (commitment) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(commitment.userName, style: _whiteBody()),
                        ),
                        _pill(
                          ctrl.statusLabel(commitment.status),
                          ctrl.statusColor(commitment.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(commitment.userEmail, style: _subBody()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commitment.items
                          .map((item) => _pill('${item.itemName} | ${item.quantity}', kAccent2))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (commitment.status == 'delivered')
                          FilledButton.tonal(
                            onPressed: () => _confirmCommitmentStatus(
                              commitment.id,
                              'verified',
                            ),
                            child: const Text('Verify'),
                          ),
                        if (commitment.status != 'verified' &&
                            commitment.status != 'rejected') ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _confirmCommitmentStatus(
                              commitment.id,
                              'rejected',
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminEssentialRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Delete Request', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the essential request if it has no active commitments.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: kRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ctrl.deleteRequest(request.id);
    }
  }

  Future<void> _confirmCommitmentStatus(String commitmentId, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          '${status[0].toUpperCase()}${status.substring(1)} Commitment',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Confirm updating this pledge to $status.',
          style: const TextStyle(color: Colors.white70),
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
      await ctrl.updateCommitmentStatus(
        commitmentId: commitmentId,
        status: status,
      );
    }
  }

  Future<void> _openEditor({AdminEssentialRequest? existing}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _EssentialRequestEditor(
          ctrl: ctrl,
          existing: existing,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: kSurface2,
        decoration: _inputDecoration(label),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (next) => onChanged(next ?? value),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmMono(fontSize: 11, color: color),
      ),
    );
  }

  TextStyle _whiteBody() => GoogleFonts.dmSans(color: Colors.white, fontSize: 13);
  TextStyle _subBody() => GoogleFonts.dmSans(color: kTextSub, fontSize: 12);
}

class _EssentialRequestEditor extends StatefulWidget {
  const _EssentialRequestEditor({
    required this.ctrl,
    this.existing,
  });

  final EssentialRequestsController ctrl;
  final AdminEssentialRequest? existing;

  @override
  State<_EssentialRequestEditor> createState() => _EssentialRequestEditorState();
}

class _EssentialRequestEditorState extends State<_EssentialRequestEditor> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _itemNameCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();
  final _itemUnitCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _timeSlotsCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  DateTime? _expiryDate;
  String _category = 'food';
  String _urgency = 'medium';
  final List<AdminEssentialItemNeed> _items = [];
  final List<AdminPickupLocation> _locations = [];
  final List<String> _images = [];
  final List<PlatformFile> _pickedImages = [];
  String _validationMessage = '';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description;
      _expiryDate = existing.expiryDate;
      _category = existing.category;
      _urgency = existing.urgencyLevel;
      _items.addAll(existing.itemsNeeded);
      _locations.addAll(existing.pickupLocations);
      _images.addAll(existing.images);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _titleCtrl,
      _descCtrl,
      _itemNameCtrl,
      _itemQtyCtrl,
      _itemUnitCtrl,
      _addressCtrl,
      _latCtrl,
      _lngCtrl,
      _contactPersonCtrl,
      _contactPhoneCtrl,
      _timeSlotsCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 980,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null ? 'Create Essential Request' : 'Edit Essential Request',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              dashField(_titleCtrl, label: 'Title', hint: 'Request title'),
              const SizedBox(height: 14),
              dashField(
                _descCtrl,
                label: 'Description',
                hint: 'Describe what is needed and why',
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: kSurface2,
                      decoration: _inputDecoration('Category'),
                      items: const ['food', 'clothes', 'medicine', 'other']
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _urgency,
                      dropdownColor: kSurface2,
                      decoration: _inputDecoration('Urgency'),
                      items: const ['low', 'medium', 'high']
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => _urgency = value ?? _urgency),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickExpiryDate,
                      child: InputDecorator(
                        decoration: _inputDecoration('Expiry Date'),
                        child: Text(
                          _expiryDate == null
                              ? 'Select expiry'
                              : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                          style: GoogleFonts.dmSans(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildItemsEditor(),
              const SizedBox(height: 18),
              _buildLocationsEditor(),
          const SizedBox(height: 18),
          _buildImagesEditor(),
              const SizedBox(height: 22),
              Obx(
                () => Row(
                  children: [
                    if (widget.ctrl.error.value.isNotEmpty || _validationMessage.isNotEmpty)
                      Expanded(
                        child: Text(
                          widget.ctrl.error.value.isNotEmpty
                              ? widget.ctrl.error.value
                              : _validationMessage,
                          style: GoogleFonts.dmSans(color: kRed),
                        ),
                      )
                    else
                      const Spacer(),
                    TextButton(
                      onPressed: widget.ctrl.isSaving.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: widget.ctrl.isSaving.value ? null : _submit,
                      child: widget.ctrl.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.existing == null ? 'Create Request' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Items Needed', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Typed values are only included after you press Add Item.',
            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dialogField(_itemNameCtrl, 'Item name')),
              const SizedBox(width: 10),
              SizedBox(width: 120, child: _dialogField(_itemQtyCtrl, 'Qty', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              SizedBox(width: 140, child: _dialogField(_itemUnitCtrl, 'Unit')),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${entry.value.itemName} | ${entry.value.quantityRequired} ${entry.value.unit}', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'Fulfilled ${entry.value.quantityFulfilled}',
                style: const TextStyle(color: kTextSub),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _items.removeAt(entry.key)),
                icon: const Icon(Icons.delete_outline_rounded, color: kRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pickup Locations', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addLocation,
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: const Text('Add Location'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Press Add Location to include the pickup point in the request.',
            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _dialogField(_addressCtrl, 'Address'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _pickLocationOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    _hasSelectedMapPoint ? 'Update map location' : 'Select on map',
                  ),
                ),
              ),
            ],
          ),
          if (_hasSelectedMapPoint) ...[
            const SizedBox(height: 10),
            _MapPreviewCard(
              latitude: double.tryParse(_latCtrl.text.trim()) ?? 0,
              longitude: double.tryParse(_lngCtrl.text.trim()) ?? 0,
              height: 180,
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${_latCtrl.text}, ${_lngCtrl.text}',
              style: const TextStyle(color: kTextSub),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dialogField(_contactPersonCtrl, 'Contact person')),
              const SizedBox(width: 10),
              Expanded(child: _dialogField(_contactPhoneCtrl, 'Contact phone')),
            ],
          ),
          const SizedBox(height: 10),
          _dialogField(_timeSlotsCtrl, 'Available time slots'),
          const SizedBox(height: 12),
          ..._locations.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value.address, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${entry.value.contactPerson} | ${entry.value.latitude}, ${entry.value.longitude}',
                style: const TextStyle(color: kTextSub),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _locations.removeAt(entry.key)),
                icon: const Icon(Icons.delete_outline_rounded, color: kRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Images', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('Select Images'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose images from your device. They will be uploaded to Cloudinary when you save the request.',
            style: GoogleFonts.dmSans(color: kTextSub, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ..._images.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  entry.value,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: kBorder,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.white70),
                  ),
                ),
              ),
              title: Text(
                'Uploaded image ${entry.key + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kTextSub),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _images.removeAt(entry.key)),
                icon: const Icon(Icons.delete_outline_rounded, color: kRed),
              ),
            ),
          ),
          ..._pickedImages.asMap().entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _SelectedImageThumb(file: entry.value),
              ),
              title: Text(
                entry.value.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Ready to upload',
                style: TextStyle(color: kTextSub),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _pickedImages.removeAt(entry.key)),
                icon: const Icon(Icons.delete_outline_rounded, color: kRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _addItem() {
    final quantity = int.tryParse(_itemQtyCtrl.text.trim()) ?? 0;
    if (_itemNameCtrl.text.trim().isEmpty || quantity <= 0 || _itemUnitCtrl.text.trim().isEmpty) {
      setState(() {
        _validationMessage = 'Complete item name, quantity, and unit before adding the item.';
      });
      return;
    }
    setState(() {
      _validationMessage = '';
      _items.add(
        AdminEssentialItemNeed(
          id: '',
          itemName: _itemNameCtrl.text.trim(),
          quantityRequired: quantity,
          quantityFulfilled: 0,
          unit: _itemUnitCtrl.text.trim(),
        ),
      );
      _itemNameCtrl.clear();
      _itemQtyCtrl.clear();
      _itemUnitCtrl.clear();
    });
  }

  void _addLocation() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (_addressCtrl.text.trim().isEmpty ||
        lat == null ||
        lng == null ||
        _contactPersonCtrl.text.trim().isEmpty ||
        _contactPhoneCtrl.text.trim().isEmpty ||
        _timeSlotsCtrl.text.trim().isEmpty) {
      setState(() {
        _validationMessage = 'Complete all pickup location fields before adding the location.';
      });
      return;
    }
    setState(() {
      _validationMessage = '';
      _locations.add(
        AdminPickupLocation(
          id: '',
          address: _addressCtrl.text.trim(),
          latitude: lat,
          longitude: lng,
          contactPerson: _contactPersonCtrl.text.trim(),
          contactPhone: _contactPhoneCtrl.text.trim(),
          availableTimeSlots: _timeSlotsCtrl.text.trim(),
        ),
      );
      _addressCtrl.clear();
      _contactPersonCtrl.clear();
      _contactPhoneCtrl.clear();
      _timeSlotsCtrl.clear();
      _latCtrl.clear();
      _lngCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _captureDraftEntries();

    final validationMessage = _buildSubmissionValidationMessage();
    if (validationMessage != null) {
      setState(() {
        _validationMessage = validationMessage;
      });
      return;
    }

    setState(() {
      _validationMessage = '';
    });

    final payload = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'urgencyLevel': _urgency,
      'expiryDate': _expiryDate!.toIso8601String(),
      'itemsNeeded': _items.map((item) => item.toJson()).toList(),
      'pickupLocations': _locations.map((item) => item.toJson()).toList(),
      'images': _images,
    };

    final ok = await widget.ctrl.saveRequest(
      requestId: widget.existing?.id,
      payload: payload,
      retainedImages: _images,
      newImages: _pickedImages,
    );

    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _captureDraftEntries() {
    if (_hasCompleteItemDraft) {
      _addItem();
    }
    if (_hasCompleteLocationDraft) {
      _addLocation();
    }
  }

  String? _buildSubmissionValidationMessage() {
    if (_expiryDate == null) {
      return 'Select an expiry date before creating the request.';
    }
    if (_hasPartialItemDraft) {
      return 'Finish the item row or clear it, then press Add Item.';
    }
    if (_items.isEmpty) {
      return 'Add at least one item before creating the request.';
    }
    if (_hasPartialLocationDraft) {
      return 'Finish the pickup location fields or clear them, then press Add Location.';
    }
    if (_locations.isEmpty) {
      return 'Add at least one pickup location before creating the request.';
    }
    return null;
  }

  bool get _hasCompleteItemDraft {
    final quantity = int.tryParse(_itemQtyCtrl.text.trim()) ?? 0;
    return _itemNameCtrl.text.trim().isNotEmpty &&
        quantity > 0 &&
        _itemUnitCtrl.text.trim().isNotEmpty;
  }

  bool get _hasPartialItemDraft {
    final hasAnyValue = _itemNameCtrl.text.trim().isNotEmpty ||
        _itemQtyCtrl.text.trim().isNotEmpty ||
        _itemUnitCtrl.text.trim().isNotEmpty;
    return hasAnyValue && !_hasCompleteItemDraft;
  }

  bool get _hasCompleteLocationDraft {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    return _addressCtrl.text.trim().isNotEmpty &&
        lat != null &&
        lng != null &&
        _contactPersonCtrl.text.trim().isNotEmpty &&
        _contactPhoneCtrl.text.trim().isNotEmpty &&
        _timeSlotsCtrl.text.trim().isNotEmpty;
  }

  bool get _hasPartialLocationDraft {
    final hasAnyValue = _addressCtrl.text.trim().isNotEmpty ||
        _latCtrl.text.trim().isNotEmpty ||
        _lngCtrl.text.trim().isNotEmpty ||
        _contactPersonCtrl.text.trim().isNotEmpty ||
        _contactPhoneCtrl.text.trim().isNotEmpty ||
        _timeSlotsCtrl.text.trim().isNotEmpty;
    return hasAnyValue && !_hasCompleteLocationDraft;
  }

  bool get _hasSelectedMapPoint =>
      _latCtrl.text.trim().isNotEmpty && _lngCtrl.text.trim().isNotEmpty;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _validationMessage = '';
      _pickedImages.addAll(
        result.files.where((file) => file.path != null && file.path!.isNotEmpty),
      );
    });
  }

  Future<void> _pickLocationOnMap() async {
    final initialPoint = _hasSelectedMapPoint
        ? LatLng(
            double.tryParse(_latCtrl.text.trim()) ?? 27.7172,
            double.tryParse(_lngCtrl.text.trim()) ?? 85.3240,
          )
        : const LatLng(27.7172, 85.3240);
    final picked = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapSelectionDialog(initialPoint: initialPoint),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _validationMessage = '';
      _latCtrl.text = picked.latitude.toStringAsFixed(6);
      _lngCtrl.text = picked.longitude.toStringAsFixed(6);
    });
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: Colors.white),
      decoration: _inputDecoration(label),
      validator: (value) {
        if (controller == _titleCtrl && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }
}

class _SelectedImageThumb extends StatelessWidget {
  const _SelectedImageThumb({required this.file});

  final PlatformFile file;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: 52,
      height: 52,
      color: kBorder,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white70),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.latitude,
    required this.longitude,
    this.height = 140,
  });

  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hopelink_admin',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: kRed,
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

class _MapSelectionDialog extends StatefulWidget {
  const _MapSelectionDialog({required this.initialPoint});

  final LatLng initialPoint;

  @override
  State<_MapSelectionDialog> createState() => _MapSelectionDialogState();
}

class _MapSelectionDialogState extends State<_MapSelectionDialog> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Pickup Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Click anywhere on the map to place the pickup marker.',
                          style: GoogleFonts.dmSans(color: kTextSub),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: widget.initialPoint,
                      initialZoom: 13,
                      onTap: (_, point) => setState(() => _selectedPoint = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.hopelink_admin',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: kRed,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lat ${_selectedPoint.latitude.toStringAsFixed(6)} | Lng ${_selectedPoint.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.dmMono(color: kAccent2),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selectedPoint),
                    child: const Text('Use Location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.dmSans(color: kTextSub),
    filled: true,
    fillColor: kSurface2,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kAccent),
    ),
  );
}
