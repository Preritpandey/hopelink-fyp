import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../models/essential_models.dart';
import '../services/donate_essentials_service.dart';

class DonateEssentialsController extends GetxController {
  DonateEssentialsController({DonateEssentialsService? service})
    : _service = service ?? DonateEssentialsService();

  final DonateEssentialsService _service;
  final ImagePicker _imagePicker = ImagePicker();

  final RxList<EssentialRequest> requests = <EssentialRequest>[].obs;
  final RxList<DonationCommitment> myCommitments = <DonationCommitment>[].obs;
  final Rxn<EssentialRequest> selectedRequest = Rxn<EssentialRequest>();

  final RxBool isLoadingRequests = false.obs;
  final RxBool isLoadingCommitments = false.obs;
  final RxBool isSubmittingCommitment = false.obs;
  final RxBool isUpdatingStatus = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString selectedCategory = 'all'.obs;
  final RxString selectedUrgency = 'all'.obs;

  final RxString selectedPickupLocationId = ''.obs;
  final Rxn<DateTime> selectedDeliveryDate = Rxn<DateTime>();
  final Rxn<Uint8List> proofImageBytes = Rxn<Uint8List>();
  final RxString proofImageName = ''.obs;
  final Map<String, TextEditingController> quantityControllers = {};

  @override
  void onInit() {
    super.onInit();
    loadRequests();
    loadMyCommitments();
  }

  Future<void> loadRequests({bool forceRefresh = false}) async {
    isLoadingRequests.value = true;
    errorMessage.value = '';
    try {
      final result = await _service.fetchRequests(
        forceRefresh: forceRefresh,
        category: selectedCategory.value == 'all' ? null : selectedCategory.value,
        urgency: selectedUrgency.value == 'all' ? null : selectedUrgency.value,
      );
      requests.assignAll(result);
    } catch (error) {
      errorMessage.value = 'Unable to load essential requests';
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> loadRequestDetail(String requestId, {bool forceRefresh = true}) async {
    final request = await _service.fetchRequestDetail(requestId, forceRefresh: forceRefresh);
    if (request != null) {
      selectedRequest.value = request;
      if (selectedPickupLocationId.value.isEmpty && request.pickupLocations.isNotEmpty) {
        selectedPickupLocationId.value = request.pickupLocations.first.id;
      }
      _ensureQuantityControllers(request);
    }
  }

  Future<void> loadMyCommitments({bool forceRefresh = false}) async {
    isLoadingCommitments.value = true;
    try {
      final result = await _service.fetchMyCommitments(forceRefresh: forceRefresh);
      myCommitments.assignAll(result);
    } finally {
      isLoadingCommitments.value = false;
    }
  }

  void applyFilters({String? category, String? urgency}) {
    if (category != null) selectedCategory.value = category;
    if (urgency != null) selectedUrgency.value = urgency;
    loadRequests(forceRefresh: true);
  }

  void startCommitFlow(EssentialRequest request) {
    selectedRequest.value = request;
    selectedPickupLocationId.value =
        request.pickupLocations.isNotEmpty ? request.pickupLocations.first.id : '';
    selectedDeliveryDate.value = DateTime.now().add(const Duration(days: 1));
    proofImageBytes.value = null;
    proofImageName.value = '';
    _ensureQuantityControllers(request, resetValues: true);
  }

  Future<void> pickProofImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;
    proofImageBytes.value = await file.readAsBytes();
    proofImageName.value = file.name;
  }

  Future<bool> submitCommitment() async {
    final request = selectedRequest.value;
    if (request == null) return false;

    final items = _buildCommittedItems(request);
    if (items.isEmpty) {
      Get.snackbar(
        'No items selected',
        'Add at least one item quantity to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (selectedPickupLocationId.value.isEmpty) {
      Get.snackbar(
        'Pickup required',
        'Select a pickup location before continuing',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSubmittingCommitment.value = true;
    try {
      final mime = proofImageName.value.isEmpty
          ? 'image/jpeg'
          : (lookupMimeType(proofImageName.value) ?? 'image/jpeg');
      await _service.createCommitment(
        CommitDonationPayload(
          requestId: request.id,
          selectedPickupLocationId: selectedPickupLocationId.value,
          itemsDonating: items,
          deliveryDate: selectedDeliveryDate.value,
          proofImage: _service.toDataUrl(proofImageBytes.value, mimeType: mime),
        ),
      );
      await loadRequests(forceRefresh: true);
      await loadRequestDetail(request.id, forceRefresh: true);
      await loadMyCommitments(forceRefresh: true);
      return true;
    } catch (error) {
      Get.snackbar(
        'Commitment failed',
        'Please review quantities and try again',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmittingCommitment.value = false;
    }
  }

  Future<bool> markDelivered(DonationCommitment commitment) async {
    isUpdatingStatus.value = true;
    try {
      final mime = proofImageName.value.isEmpty
          ? 'image/jpeg'
          : (lookupMimeType(proofImageName.value) ?? 'image/jpeg');
      await _service.markCommitmentDelivered(
        commitmentId: commitment.id,
        deliveryDate: selectedDeliveryDate.value ?? DateTime.now(),
        proofImage: _service.toDataUrl(proofImageBytes.value, mimeType: mime),
      );
      await loadMyCommitments(forceRefresh: true);
      await loadRequestDetail(commitment.requestId.id, forceRefresh: true);
      await loadRequests(forceRefresh: true);
      return true;
    } catch (_) {
      Get.snackbar(
        'Update failed',
        'Unable to mark this commitment as delivered',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  int impactFamiliesForCommitment(DonationCommitment commitment) {
    final totalUnits = commitment.itemsDonating.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    return max(1, (totalUnits / 5).round());
  }

  String statusLabel(String status) {
    switch (status) {
      case 'pledged':
        return 'Pending';
      case 'delivered':
        return 'Delivered';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  List<CommittedItem> _buildCommittedItems(EssentialRequest request) {
    final reportingMap = {
      for (final item in request.reporting.items) item.itemName.toLowerCase(): item,
    };
    final items = <CommittedItem>[];

    for (final item in request.itemsNeeded) {
      final controller = quantityControllers[item.id];
      final quantity = int.tryParse(controller?.text.trim() ?? '') ?? 0;
      if (quantity <= 0) continue;

      final reporting = reportingMap[item.itemName.toLowerCase()];
      if (reporting != null && quantity > reporting.quantityRemaining) {
        throw Exception('Quantity exceeds remaining amount');
      }

      items.add(CommittedItem(itemName: item.itemName, quantity: quantity));
    }

    return items;
  }

  void _ensureQuantityControllers(
    EssentialRequest request, {
    bool resetValues = false,
  }) {
    for (final item in request.itemsNeeded) {
      quantityControllers.putIfAbsent(item.id, TextEditingController.new);
      if (resetValues) {
        quantityControllers[item.id]!.text = '';
      }
    }
  }

  @override
  void onClose() {
    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }
}
