import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:hope_link/core/services/api_client.dart';

import '../models/essential_models.dart';

class DonateEssentialsService {
  DonateEssentialsService({Dio? dio}) : _dio = dio ?? ApiClient.create();

  final Dio _dio;

  static const _requestsBox = 'essentials_requests_cache';
  static const _commitmentsBox = 'essentials_commitments_cache';
  static const _prefsBox = 'preferences';
  static const _lastRequestsSyncKey = 'essentials_requests_last_sync';
  static const _lastCommitmentsSyncKey = 'essentials_commitments_last_sync';
  static const _staleMinutes = 20;

  Future<List<EssentialRequest>> fetchRequests({
    bool forceRefresh = false,
    String? category,
    String? urgency,
  }) async {
    final cacheKey = _requestsCacheKey(category: category, urgency: urgency);
    if (!forceRefresh && !(await _isRequestsStale(cacheKey))) {
      final cached = await getCachedRequests(
        category: category,
        urgency: urgency,
      );
      if (cached.isNotEmpty) return cached;
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.essentialRequests,
        queryParameters: {
          if (category != null && category != 'all') 'category': category,
          if (urgency != null && urgency != 'all') 'urgency': urgency,
        },
      );
      final data = response.data;
      final requests =
          ((data['data'] as List?) ?? const [])
              .map(
                (item) => EssentialRequest.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
      await _cacheRequests(
        cacheKey: cacheKey,
        requests: requests,
      );
      return requests;
    } catch (_) {
      return getCachedRequests(category: category, urgency: urgency);
    }
  }

  Future<List<EssentialRequest>> getCachedRequests({
    String? category,
    String? urgency,
  }) async {
    final box = await Hive.openBox(_requestsBox);
    final raw = box.get(
      _requestsCacheKey(category: category, urgency: urgency),
    ) as String?;
    if (raw == null || raw.isEmpty) return [];
    return decodeRequestsCache(raw);
  }

  Future<EssentialRequest?> fetchRequestDetail(
    String requestId, {
    bool forceRefresh = true,
  }) async {
    if (!forceRefresh) {
      final cached = await getCachedRequestById(requestId);
      if (cached != null) return cached;
    }

    try {
      final response = await _dio.get(ApiEndpoints.essentialRequestById(requestId));
      final request = EssentialRequest.fromJson(
        (response.data['data'] as Map).cast<String, dynamic>(),
      );
      await _upsertRequestCache(request);
      return request;
    } catch (_) {
      return getCachedRequestById(requestId);
    }
  }

  Future<EssentialRequest?> getCachedRequestById(String requestId) async {
    final allCached = await getCachedRequests();
    try {
      return allCached.firstWhere((item) => item.id == requestId);
    } catch (_) {
      return null;
    }
  }

  Future<List<DonationCommitment>> fetchMyCommitments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && !(await _isCommitmentsStale())) {
      final cached = await getCachedCommitments();
      if (cached.isNotEmpty) return cached;
    }

    try {
      final response = await _dio.get(ApiEndpoints.userEssentialCommitments);
      final commitments =
          ((response.data['data'] as List?) ?? const [])
              .map(
                (item) => DonationCommitment.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList();
      await _cacheCommitments(commitments);
      return commitments;
    } catch (_) {
      return getCachedCommitments();
    }
  }

  Future<List<DonationCommitment>> getCachedCommitments() async {
    final box = await Hive.openBox(_commitmentsBox);
    final raw = box.get('mine') as String?;
    if (raw == null || raw.isEmpty) return [];
    return decodeCommitmentsCache(raw);
  }

  Future<DonationCommitment> createCommitment(CommitDonationPayload payload) async {
    final response = await _dio.post(
      ApiEndpoints.commitDonation,
      data: payload.toJson(),
    );
    final commitment = DonationCommitment.fromJson(
      (response.data['data'] as Map).cast<String, dynamic>(),
    );
    await fetchMyCommitments(forceRefresh: true);
    await fetchRequestDetail(payload.requestId, forceRefresh: true);
    return commitment;
  }

  Future<DonationCommitment> markCommitmentDelivered({
    required String commitmentId,
    DateTime? deliveryDate,
    String? proofImage,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.commitDonationStatus(commitmentId),
      data: {
        'status': 'delivered',
        if (deliveryDate != null) 'deliveryDate': deliveryDate.toIso8601String(),
        if (proofImage != null && proofImage.isNotEmpty) 'proofImage': proofImage,
      },
    );

    final commitment = DonationCommitment.fromJson(
      (response.data['data'] as Map).cast<String, dynamic>(),
    );
    await fetchMyCommitments(forceRefresh: true);
    await fetchRequestDetail(commitment.requestId.id, forceRefresh: true);
    return commitment;
  }

  String? toDataUrl(Uint8List? bytes, {String mimeType = 'image/jpeg'}) {
    if (bytes == null || bytes.isEmpty) return null;
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> _cacheRequests({
    required String cacheKey,
    required List<EssentialRequest> requests,
  }) async {
    final box = await Hive.openBox(_requestsBox);
    await box.put(cacheKey, encodeRequestsCache(requests));

    final prefsBox = await Hive.openBox(_prefsBox);
    await prefsBox.put(
      '$_lastRequestsSyncKey:$cacheKey',
      DateTime.now().toIso8601String(),
    );

  }

  Future<void> _upsertRequestCache(EssentialRequest request) async {
    final box = await Hive.openBox(_requestsBox);
    final raw = box.get(_requestsCacheKey()) as String?;
    final requests = raw == null || raw.isEmpty ? <EssentialRequest>[] : decodeRequestsCache(raw);
    final index = requests.indexWhere((item) => item.id == request.id);
    if (index >= 0) {
      requests[index] = request;
    } else {
      requests.insert(0, request);
    }
    await box.put(_requestsCacheKey(), encodeRequestsCache(requests));
    final prefsBox = await Hive.openBox(_prefsBox);
    await prefsBox.put(
      '$_lastRequestsSyncKey:${_requestsCacheKey()}',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _cacheCommitments(List<DonationCommitment> commitments) async {
    final box = await Hive.openBox(_commitmentsBox);
    await box.put('mine', encodeCommitmentsCache(commitments));
    final prefsBox = await Hive.openBox(_prefsBox);
    await prefsBox.put(_lastCommitmentsSyncKey, DateTime.now().toIso8601String());
  }

  Future<bool> _isRequestsStale(String cacheKey) async {
    final prefsBox = await Hive.openBox(_prefsBox);
    final raw = prefsBox.get('$_lastRequestsSyncKey:$cacheKey') as String?;
    if (raw == null || raw.isEmpty) return true;
    final time = DateTime.tryParse(raw);
    if (time == null) return true;
    return DateTime.now().difference(time).inMinutes >= _staleMinutes;
  }

  Future<bool> _isCommitmentsStale() async {
    final prefsBox = await Hive.openBox(_prefsBox);
    final raw = prefsBox.get(_lastCommitmentsSyncKey) as String?;
    if (raw == null || raw.isEmpty) return true;
    final time = DateTime.tryParse(raw);
    if (time == null) return true;
    return DateTime.now().difference(time).inMinutes >= _staleMinutes;
  }

  String _requestsCacheKey({String? category, String? urgency}) =>
      'requests:${category ?? 'all'}:${urgency ?? 'all'}';
}
