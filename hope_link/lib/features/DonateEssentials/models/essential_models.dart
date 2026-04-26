import 'dart:convert';

class EssentialRequestListResponse {
  EssentialRequestListResponse({
    required this.requests,
    required this.cachedAt,
  });

  final List<EssentialRequest> requests;
  final DateTime cachedAt;
}

class EssentialRequest {
  EssentialRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.urgencyLevel,
    required this.expiryDate,
    required this.status,
    required this.images,
    required this.itemsNeeded,
    required this.pickupLocations,
    required this.organization,
    required this.reporting,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String urgencyLevel;
  final DateTime expiryDate;
  final String status;
  final List<String> images;
  final List<EssentialItemNeed> itemsNeeded;
  final List<PickupLocation> pickupLocations;
  final EssentialOrganization organization;
  final EssentialReporting reporting;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EssentialRequest.fromJson(Map<String, dynamic> json) {
    return EssentialRequest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      urgencyLevel: (json['urgencyLevel'] ?? '').toString(),
      expiryDate:
          DateTime.tryParse((json['expiryDate'] ?? '').toString()) ??
          DateTime.now(),
      status: (json['status'] ?? 'active').toString(),
      images:
          ((json['images'] as List?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      itemsNeeded:
          ((json['itemsNeeded'] as List?) ?? const [])
              .map(
                (item) => EssentialItemNeed.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      pickupLocations:
          ((json['pickupLocations'] as List?) ?? const [])
              .map(
                (item) => PickupLocation.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      organization: EssentialOrganization.fromJson(
        (json['createdBy'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      reporting: EssentialReporting.fromJson(
        (json['reporting'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'category': category,
    'urgencyLevel': urgencyLevel,
    'expiryDate': expiryDate.toIso8601String(),
    'status': status,
    'images': images,
    'itemsNeeded': itemsNeeded.map((item) => item.toJson()).toList(),
    'pickupLocations': pickupLocations.map((item) => item.toJson()).toList(),
    'createdBy': organization.toJson(),
    'reporting': reporting.toJson(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  double get fulfillmentRatio {
    if (reporting.totals.quantityRequired <= 0) return 0;
    return (reporting.totals.quantityFulfilled / reporting.totals.quantityRequired)
        .clamp(0, 1);
  }

  int get daysRemaining {
    final difference = expiryDate.difference(DateTime.now());
    return difference.inDays < 0 ? 0 : difference.inDays;
  }

  bool get isUrgent => urgencyLevel.toLowerCase() == 'high';

  bool get isExpired =>
      status.toLowerCase() == 'expired' || expiryDate.isBefore(DateTime.now());
}

class EssentialItemNeed {
  EssentialItemNeed({
    required this.id,
    required this.itemName,
    required this.unit,
    required this.quantityRequired,
    required this.quantityFulfilled,
  });

  final String id;
  final String itemName;
  final String unit;
  final int quantityRequired;
  final int quantityFulfilled;

  factory EssentialItemNeed.fromJson(Map<String, dynamic> json) {
    return EssentialItemNeed(
      id: (json['_id'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      quantityRequired: _asInt(json['quantityRequired']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'itemName': itemName,
    'unit': unit,
    'quantityRequired': quantityRequired,
    'quantityFulfilled': quantityFulfilled,
  };
}

class PickupLocation {
  PickupLocation({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactPerson,
    required this.contactPhone,
    required this.availableTimeSlots,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String contactPerson;
  final String contactPhone;
  final String availableTimeSlots;

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      id: (json['_id'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      contactPerson: (json['contactPerson'] ?? '').toString(),
      contactPhone: (json['contactPhone'] ?? '').toString(),
      availableTimeSlots: (json['availableTimeSlots'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'contactPerson': contactPerson,
    'contactPhone': contactPhone,
    'availableTimeSlots': availableTimeSlots,
  };
}

class EssentialOrganization {
  EssentialOrganization({
    required this.id,
    required this.organizationName,
    required this.officialEmail,
    required this.officialPhone,
  });

  final String id;
  final String organizationName;
  final String officialEmail;
  final String officialPhone;

  factory EssentialOrganization.fromJson(Map<String, dynamic> json) {
    return EssentialOrganization(
      id: (json['_id'] ?? '').toString(),
      organizationName: (json['organizationName'] ?? 'Organization').toString(),
      officialEmail: (json['officialEmail'] ?? '').toString(),
      officialPhone: (json['officialPhone'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'organizationName': organizationName,
    'officialEmail': officialEmail,
    'officialPhone': officialPhone,
  };
}

class EssentialReporting {
  EssentialReporting({
    required this.items,
    required this.totals,
  });

  final List<EssentialReportingItem> items;
  final EssentialReportingTotals totals;

  factory EssentialReporting.fromJson(Map<String, dynamic> json) {
    return EssentialReporting(
      items:
          ((json['items'] as List?) ?? const [])
              .map(
                (item) => EssentialReportingItem.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      totals: EssentialReportingTotals.fromJson(
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'totals': totals.toJson(),
  };
}

class EssentialReportingItem {
  EssentialReportingItem({
    required this.itemName,
    required this.unit,
    required this.quantityRequired,
    required this.quantityPledged,
    required this.quantityFulfilled,
    required this.quantityRemaining,
  });

  final String itemName;
  final String unit;
  final int quantityRequired;
  final int quantityPledged;
  final int quantityFulfilled;
  final int quantityRemaining;

  factory EssentialReportingItem.fromJson(Map<String, dynamic> json) {
    return EssentialReportingItem(
      itemName: (json['itemName'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      quantityRequired: _asInt(json['quantityRequired']),
      quantityPledged: _asInt(json['quantityPledged']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
      quantityRemaining: _asInt(json['quantityRemaining']),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'unit': unit,
    'quantityRequired': quantityRequired,
    'quantityPledged': quantityPledged,
    'quantityFulfilled': quantityFulfilled,
    'quantityRemaining': quantityRemaining,
  };
}

class EssentialReportingTotals {
  EssentialReportingTotals({
    required this.quantityRequired,
    required this.quantityPledged,
    required this.quantityFulfilled,
    required this.quantityRemaining,
  });

  final int quantityRequired;
  final int quantityPledged;
  final int quantityFulfilled;
  final int quantityRemaining;

  factory EssentialReportingTotals.fromJson(Map<String, dynamic> json) {
    return EssentialReportingTotals(
      quantityRequired: _asInt(json['quantityRequired']),
      quantityPledged: _asInt(json['quantityPledged']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
      quantityRemaining: _asInt(json['quantityRemaining']),
    );
  }

  Map<String, dynamic> toJson() => {
    'quantityRequired': quantityRequired,
    'quantityPledged': quantityPledged,
    'quantityFulfilled': quantityFulfilled,
    'quantityRemaining': quantityRemaining,
  };
}

class DonationCommitment {
  DonationCommitment({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.itemsDonating,
    required this.selectedPickupLocationId,
    required this.status,
    required this.deliveryDate,
    required this.proofImage,
    required this.createdAt,
    required this.updatedAt,
    this.selectedPickupLocation,
  });

  final String id;
  final EssentialUserSummary userId;
  final EssentialRequest requestId;
  final List<CommittedItem> itemsDonating;
  final String selectedPickupLocationId;
  final String status;
  final DateTime? deliveryDate;
  final String proofImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PickupLocation? selectedPickupLocation;

  factory DonationCommitment.fromJson(Map<String, dynamic> json) {
    final request = EssentialRequest.fromJson(
      (json['requestId'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final explicitLocation =
        (json['selectedPickupLocation'] as Map?)?.cast<String, dynamic>();
    Map<String, dynamic>? fallbackLocation;
    final selectedPickupLocationId =
        (json['selectedPickupLocationId'] ?? '').toString();
    for (final location in request.pickupLocations) {
      if (location.id == selectedPickupLocationId) {
        fallbackLocation = location.toJson();
        break;
      }
    }
    final selectedLocation = explicitLocation ?? fallbackLocation;

    return DonationCommitment(
      id: (json['_id'] ?? '').toString(),
      userId: EssentialUserSummary.fromJson(
        (json['userId'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      requestId: request,
      itemsDonating:
          ((json['itemsDonating'] as List?) ?? const [])
              .map(
                (item) => CommittedItem.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      selectedPickupLocationId: selectedPickupLocationId,
      status: (json['status'] ?? 'pledged').toString(),
      deliveryDate: DateTime.tryParse((json['deliveryDate'] ?? '').toString()),
      proofImage: (json['proofImage'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      selectedPickupLocation:
          selectedLocation == null
              ? null
              : PickupLocation.fromJson(selectedLocation),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId.toJson(),
    'requestId': requestId.toJson(),
    'itemsDonating': itemsDonating.map((item) => item.toJson()).toList(),
    'selectedPickupLocationId': selectedPickupLocationId,
    'status': status,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'proofImage': proofImage,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    if (selectedPickupLocation != null)
      'selectedPickupLocation': selectedPickupLocation!.toJson(),
  };

  bool get canMarkDelivered => status == 'pledged';
  bool get isPending => status == 'pledged';
}

class EssentialUserSummary {
  EssentialUserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  factory EssentialUserSummary.fromJson(Map<String, dynamic> json) {
    return EssentialUserSummary(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };
}

class CommittedItem {
  CommittedItem({
    required this.itemName,
    required this.quantity,
  });

  final String itemName;
  final int quantity;

  factory CommittedItem.fromJson(Map<String, dynamic> json) {
    return CommittedItem(
      itemName: (json['itemName'] ?? '').toString(),
      quantity: _asInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'quantity': quantity,
  };
}

class CommitDonationPayload {
  CommitDonationPayload({
    required this.requestId,
    required this.selectedPickupLocationId,
    required this.itemsDonating,
    required this.deliveryDate,
    required this.proofImage,
  });

  final String requestId;
  final String selectedPickupLocationId;
  final List<CommittedItem> itemsDonating;
  final DateTime? deliveryDate;
  final String? proofImage;

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'selectedPickupLocationId': selectedPickupLocationId,
    'itemsDonating': itemsDonating.map((item) => item.toJson()).toList(),
    if (deliveryDate != null) 'deliveryDate': deliveryDate!.toIso8601String(),
    if (proofImage != null && proofImage!.isNotEmpty) 'proofImage': proofImage,
  };
}

String encodeRequestsCache(List<EssentialRequest> requests) =>
    jsonEncode(requests.map((item) => item.toJson()).toList());

List<EssentialRequest> decodeRequestsCache(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded
      .map((item) => EssentialRequest.fromJson((item as Map).cast<String, dynamic>()))
      .toList();
}

String encodeCommitmentsCache(List<DonationCommitment> commitments) =>
    jsonEncode(commitments.map((item) => item.toJson()).toList());

List<DonationCommitment> decodeCommitmentsCache(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded
      .map((item) => DonationCommitment.fromJson((item as Map).cast<String, dynamic>()))
      .toList();
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
