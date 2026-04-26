import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_endpoints.dart';
import '../models/essential_admin_models.dart';

class EssentialRequestsController extends GetxController {
  final requests = <AdminEssentialRequest>[].obs;
  final selectedRequest = Rxn<AdminEssentialRequest>();
  final selectedBundle = Rxn<AdminCommitmentBundle>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isLoadingDetails = false.obs;
  final error = ''.obs;

  final categoryFilter = 'all'.obs;
  final urgencyFilter = 'all'.obs;

  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
    await fetchRequests();
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<void> fetchRequests({bool keepSelection = true}) async {
    isLoading.value = true;
    error.value = '';
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.essentialRequests).replace(
          queryParameters: {
            if (categoryFilter.value != 'all') 'category': categoryFilter.value,
            if (urgencyFilter.value != 'all') 'urgency': urgencyFilter.value,
          },
        ),
        headers: _headers,
      );

      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final list = ((json['data'] as List?) ?? const [])
            .map(
              (item) => AdminEssentialRequest.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
        requests.assignAll(list);
        if (keepSelection && selectedRequest.value != null) {
          final selectedId = selectedRequest.value!.id;
          AdminEssentialRequest? matched;
          for (final item in list) {
            if (item.id == selectedId) {
              matched = item;
              break;
            }
          }
          if (matched != null) {
            selectedRequest.value = matched;
            await fetchRequestBundle(matched.id);
          } else if (list.isNotEmpty) {
            selectedRequest.value = list.first;
            await fetchRequestBundle(list.first.id);
          } else {
            selectedRequest.value = null;
            selectedBundle.value = null;
          }
        } else if (list.isNotEmpty) {
          selectedRequest.value = list.first;
          await fetchRequestBundle(list.first.id);
        } else {
          selectedRequest.value = null;
          selectedBundle.value = null;
        }
      } else {
        error.value = _readMessage(
          json,
          fallback: 'Failed to load essential requests',
        );
      }
    } catch (_) {
      error.value = 'Failed to load essential requests';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRequestBundle(String requestId) async {
    isLoadingDetails.value = true;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.orgRequestCommitments(requestId)),
        headers: _headers,
      );
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final bundle = AdminCommitmentBundle.fromJson(
          (json['data'] as Map).cast<String, dynamic>(),
        );
        selectedBundle.value = bundle;
        selectedRequest.value = bundle.request;
      }
    } finally {
      isLoadingDetails.value = false;
    }
  }

  Future<bool> saveRequest({
    String? requestId,
    required Map<String, dynamic> payload,
    List<String> retainedImages = const [],
    List<PlatformFile> newImages = const [],
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse(
        requestId == null
            ? ApiEndpoints.essentialRequests
            : ApiEndpoints.essentialRequestById(requestId),
      );
      final request = http.MultipartRequest(
        requestId == null ? 'POST' : 'PUT',
        uri,
      )..headers['Authorization'] = 'Bearer $_token';

      request.fields['title'] = (payload['title'] ?? '').toString();
      request.fields['description'] = (payload['description'] ?? '').toString();
      request.fields['category'] = (payload['category'] ?? '').toString();
      request.fields['urgencyLevel'] = (payload['urgencyLevel'] ?? '').toString();
      request.fields['expiryDate'] = (payload['expiryDate'] ?? '').toString();
      request.fields['itemsNeeded'] = jsonEncode(payload['itemsNeeded'] ?? const []);
      request.fields['pickupLocations'] = jsonEncode(
        payload['pickupLocations'] ?? const [],
      );
      request.fields['images'] = jsonEncode(retainedImages);

      for (final file in newImages) {
        if (file.path == null || file.path!.isEmpty) {
          continue;
        }
        final mimeType = lookupMimeType(file.path!, headerBytes: file.bytes) ??
            lookupMimeType(file.name, headerBytes: file.bytes) ??
            'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            file.path!,
            filename: file.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final json = _decode(body);
      if ((streamed.statusCode == 200 || streamed.statusCode == 201) &&
          json['success'] == true) {
        await fetchRequests(keepSelection: false);
        final id = ((json['data'] as Map?)?['_id'] ?? requestId)?.toString();
        if (id != null && id.isNotEmpty) {
          await fetchRequestBundle(id);
        }
        return true;
      }
      error.value = _readMessage(json, fallback: 'Unable to save request');
      return false;
    } catch (_) {
      error.value = 'Unable to save request';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.essentialRequestById(requestId)),
        headers: _headers,
      );
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        selectedRequest.value = null;
        selectedBundle.value = null;
        await fetchRequests(keepSelection: false);
        return true;
      }
      error.value = _readMessage(json, fallback: 'Unable to delete request');
      return false;
    } catch (_) {
      error.value = 'Unable to delete request';
      return false;
    }
  }

  Future<bool> updateCommitmentStatus({
    required String commitmentId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.commitDonationStatus(commitmentId)),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      final json = _decode(response.body);
      if (response.statusCode == 200 && json['success'] == true) {
        final current = selectedRequest.value;
        await fetchRequests();
        if (current != null) {
          await fetchRequestBundle(current.id);
        }
        return true;
      }
      error.value = _readMessage(json, fallback: 'Unable to update commitment');
      return false;
    } catch (_) {
      error.value = 'Unable to update commitment';
      return false;
    }
  }

  void setFilters({String? category, String? urgency}) {
    if (category != null) categoryFilter.value = category;
    if (urgency != null) urgencyFilter.value = urgency;
    fetchRequests(keepSelection: false);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF10B981);
      case 'delivered':
        return const Color(0xFF3B82F6);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'fulfilled':
        return const Color(0xFF10B981);
      case 'expired':
        return const Color(0xFFFFB347);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case 'pledged':
        return 'Pending';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _readMessage(Map<String, dynamic> json, {required String fallback}) {
    return (json['message'] ??
            json['error']?['message'] ??
            json['error'] ??
            fallback)
        .toString();
  }
}
