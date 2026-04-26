class AdminEssentialRequest {
  const AdminEssentialRequest({
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
    required this.reporting,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String urgencyLevel;
  final DateTime? expiryDate;
  final String status;
  final List<String> images;
  final List<AdminEssentialItemNeed> itemsNeeded;
  final List<AdminPickupLocation> pickupLocations;
  final AdminEssentialReporting reporting;

  factory AdminEssentialRequest.fromJson(Map<String, dynamic> json) {
    return AdminEssentialRequest(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      urgencyLevel: (json['urgencyLevel'] ?? '').toString(),
      expiryDate: DateTime.tryParse((json['expiryDate'] ?? '').toString()),
      status: (json['status'] ?? '').toString(),
      images:
          ((json['images'] as List?) ?? const [])
              .map((item) => item.toString())
              .toList(),
      itemsNeeded:
          ((json['itemsNeeded'] as List?) ?? const [])
              .map(
                (item) => AdminEssentialItemNeed.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      pickupLocations:
          ((json['pickupLocations'] as List?) ?? const [])
              .map(
                (item) => AdminPickupLocation.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      reporting: AdminEssentialReporting.fromJson(
        (json['reporting'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  double get fulfillmentRatio {
    if (reporting.totals.quantityRequired <= 0) return 0;
    return (reporting.totals.quantityFulfilled / reporting.totals.quantityRequired)
        .clamp(0, 1);
  }
}

class AdminEssentialItemNeed {
  const AdminEssentialItemNeed({
    required this.id,
    required this.itemName,
    required this.quantityRequired,
    required this.quantityFulfilled,
    required this.unit,
  });

  final String id;
  final String itemName;
  final int quantityRequired;
  final int quantityFulfilled;
  final String unit;

  factory AdminEssentialItemNeed.fromJson(Map<String, dynamic> json) {
    return AdminEssentialItemNeed(
      id: (json['_id'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      quantityRequired: _asInt(json['quantityRequired']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
      unit: (json['unit'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemName': itemName,
    'quantityRequired': quantityRequired,
    'unit': unit,
  };
}

class AdminPickupLocation {
  const AdminPickupLocation({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactPerson,
    required this.contactPhone,
    required this.availableTimeSlots,
  });

  final String id;
  final String address;
  final double latitude;
  final double longitude;
  final String contactPerson;
  final String contactPhone;
  final String availableTimeSlots;

  factory AdminPickupLocation.fromJson(Map<String, dynamic> json) {
    return AdminPickupLocation(
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
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'contactPerson': contactPerson,
    'contactPhone': contactPhone,
    'availableTimeSlots': availableTimeSlots,
  };
}

class AdminEssentialReporting {
  const AdminEssentialReporting({
    required this.items,
    required this.totals,
  });

  final List<AdminEssentialReportingItem> items;
  final AdminEssentialReportingTotals totals;

  factory AdminEssentialReporting.fromJson(Map<String, dynamic> json) {
    return AdminEssentialReporting(
      items:
          ((json['items'] as List?) ?? const [])
              .map(
                (item) => AdminEssentialReportingItem.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      totals: AdminEssentialReportingTotals.fromJson(
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class AdminEssentialReportingItem {
  const AdminEssentialReportingItem({
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

  factory AdminEssentialReportingItem.fromJson(Map<String, dynamic> json) {
    return AdminEssentialReportingItem(
      itemName: (json['itemName'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      quantityRequired: _asInt(json['quantityRequired']),
      quantityPledged: _asInt(json['quantityPledged']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
      quantityRemaining: _asInt(json['quantityRemaining']),
    );
  }
}

class AdminEssentialReportingTotals {
  const AdminEssentialReportingTotals({
    required this.quantityRequired,
    required this.quantityPledged,
    required this.quantityFulfilled,
    required this.quantityRemaining,
  });

  final int quantityRequired;
  final int quantityPledged;
  final int quantityFulfilled;
  final int quantityRemaining;

  factory AdminEssentialReportingTotals.fromJson(Map<String, dynamic> json) {
    return AdminEssentialReportingTotals(
      quantityRequired: _asInt(json['quantityRequired']),
      quantityPledged: _asInt(json['quantityPledged']),
      quantityFulfilled: _asInt(json['quantityFulfilled']),
      quantityRemaining: _asInt(json['quantityRemaining']),
    );
  }
}

class AdminCommitmentBundle {
  const AdminCommitmentBundle({
    required this.request,
    required this.summary,
    required this.commitments,
  });

  final AdminEssentialRequest request;
  final AdminCommitmentSummary summary;
  final List<AdminDonationCommitment> commitments;

  factory AdminCommitmentBundle.fromJson(Map<String, dynamic> json) {
    return AdminCommitmentBundle(
      request: AdminEssentialRequest.fromJson(
        (json['request'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      summary: AdminCommitmentSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      commitments:
          ((json['commitments'] as List?) ?? const [])
              .map(
                (item) => AdminDonationCommitment.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
    );
  }
}

class AdminCommitmentSummary {
  const AdminCommitmentSummary({
    required this.totalCommitments,
    required this.pledged,
    required this.delivered,
    required this.verified,
    required this.rejected,
  });

  final int totalCommitments;
  final int pledged;
  final int delivered;
  final int verified;
  final int rejected;

  factory AdminCommitmentSummary.fromJson(Map<String, dynamic> json) {
    return AdminCommitmentSummary(
      totalCommitments: _asInt(json['totalCommitments']),
      pledged: _asInt(json['pledged']),
      delivered: _asInt(json['delivered']),
      verified: _asInt(json['verified']),
      rejected: _asInt(json['rejected']),
    );
  }
}

class AdminDonationCommitment {
  const AdminDonationCommitment({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.deliveryDate,
    required this.items,
    required this.pickupLocationId,
    required this.proofImage,
  });

  final String id;
  final String userName;
  final String userEmail;
  final String status;
  final DateTime? deliveryDate;
  final List<AdminCommittedItem> items;
  final String pickupLocationId;
  final String proofImage;

  factory AdminDonationCommitment.fromJson(Map<String, dynamic> json) {
    final user = (json['userId'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AdminDonationCommitment(
      id: (json['_id'] ?? '').toString(),
      userName: (user['name'] ?? 'Donor').toString(),
      userEmail: (user['email'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deliveryDate: DateTime.tryParse((json['deliveryDate'] ?? '').toString()),
      items:
          ((json['itemsDonating'] as List?) ?? const [])
              .map(
                (item) => AdminCommittedItem.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList(),
      pickupLocationId: (json['selectedPickupLocationId'] ?? '').toString(),
      proofImage: (json['proofImage'] ?? '').toString(),
    );
  }
}

class AdminCommittedItem {
  const AdminCommittedItem({
    required this.itemName,
    required this.quantity,
  });

  final String itemName;
  final int quantity;

  factory AdminCommittedItem.fromJson(Map<String, dynamic> json) {
    return AdminCommittedItem(
      itemName: (json['itemName'] ?? '').toString(),
      quantity: _asInt(json['quantity']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
