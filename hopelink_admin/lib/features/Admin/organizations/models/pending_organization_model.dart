class PendingOrganizationsResponse {
  final bool success;
  final int count;
  final List<PendingOrganization> data;
  final PaginationMeta? pagination;

  const PendingOrganizationsResponse({
    required this.success,
    required this.count,
    required this.data,
    this.pagination,
  });

  factory PendingOrganizationsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return PendingOrganizationsResponse(
      success: json['success'] == true,
      count: _asInt(json['count']) ?? (rawData is List ? rawData.length : 0),
      data: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(PendingOrganization.fromJson)
                .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int totalPages;
  final int totalItems;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.totalItems,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 20,
      totalPages: _asInt(json['totalPages']) ?? 1,
      totalItems: _asInt(json['totalItems']) ?? 0,
    );
  }
}

class PendingOrganization {
  final String id;
  final String organizationName;
  final String organizationType;
  final String registrationNumber;
  final DateTime? dateOfRegistration;
  final String officialEmail;
  final String officialPhone;
  final String website;
  final String country;
  final String city;
  final String registeredAddress;
  final String representativeName;
  final String designation;
  final String primaryCause;
  final String missionStatement;
  final int activeMembers;
  final List<String> recentCampaigns;
  final OrganizationDocument? logo;
  final OrganizationDocument? registrationCertificate;
  final OrganizationDocument? taxCertificate;
  final OrganizationDocument? constitutionFile;
  final OrganizationDocument? proofOfAddress;
  final BankDetails bankDetails;
  final SocialMedia socialMedia;
  final String status;
  final bool isVerified;
  final num totalDonationsReceived;
  final int totalDonationCount;
  final int activeCampaigns;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PendingOrganization({
    required this.id,
    required this.organizationName,
    required this.organizationType,
    required this.registrationNumber,
    required this.dateOfRegistration,
    required this.officialEmail,
    required this.officialPhone,
    required this.website,
    required this.country,
    required this.city,
    required this.registeredAddress,
    required this.representativeName,
    required this.designation,
    required this.primaryCause,
    required this.missionStatement,
    required this.activeMembers,
    required this.recentCampaigns,
    required this.logo,
    required this.registrationCertificate,
    required this.taxCertificate,
    required this.constitutionFile,
    required this.proofOfAddress,
    required this.bankDetails,
    required this.socialMedia,
    required this.status,
    required this.isVerified,
    required this.totalDonationsReceived,
    required this.totalDonationCount,
    required this.activeCampaigns,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingOrganization.fromJson(Map<String, dynamic> json) {
    return PendingOrganization(
      id: _asString(json['_id']),
      organizationName: _asString(json['organizationName']),
      organizationType: _asString(json['organizationType']),
      registrationNumber: _asString(json['registrationNumber']),
      dateOfRegistration: _asDate(json['dateOfRegistration']),
      officialEmail: _asString(json['officialEmail']),
      officialPhone: _asString(json['officialPhone']),
      website: _asString(json['website']),
      country: _asString(json['country']),
      city: _asString(json['city']),
      registeredAddress: _asString(json['registeredAddress']),
      representativeName: _asString(json['representativeName']),
      designation: _asString(json['designation']),
      primaryCause: _asString(json['primaryCause']),
      missionStatement: _asString(json['missionStatement']),
      activeMembers: _asInt(json['activeMembers']) ?? 0,
      recentCampaigns: json['recentCampaigns'] is List
          ? (json['recentCampaigns'] as List).map((e) => '$e').toList()
          : const [],
      logo: OrganizationDocument.fromMaybeJson(json['logo']),
      registrationCertificate: OrganizationDocument.fromMaybeJson(
        json['registrationCertificate'],
      ),
      taxCertificate: OrganizationDocument.fromMaybeJson(
        json['taxCertificate'],
      ),
      constitutionFile: OrganizationDocument.fromMaybeJson(
        json['constitutionFile'],
      ),
      proofOfAddress: OrganizationDocument.fromMaybeJson(
        json['proofOfAddress'],
      ),
      bankDetails: BankDetails.fromJson(
        json['bankDetails'] is Map<String, dynamic>
            ? json['bankDetails'] as Map<String, dynamic>
            : const {},
      ),
      socialMedia: SocialMedia.fromJson(
        json['socialMedia'] is Map<String, dynamic>
            ? json['socialMedia'] as Map<String, dynamic>
            : const {},
      ),
      status: _asString(json['status']),
      isVerified: json['isVerified'] == true,
      totalDonationsReceived: json['totalDonationsReceived'] is num
          ? json['totalDonationsReceived'] as num
          : 0,
      totalDonationCount: _asInt(json['totalDonationCount']) ?? 0,
      activeCampaigns: _asInt(json['activeCampaigns']) ?? 0,
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  String get location {
    final parts = [city, country].where((value) => value.trim().isNotEmpty);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  List<NamedDocument> get documents => [
    if (registrationCertificate != null)
      NamedDocument('Registration Certificate', registrationCertificate!),
    if (taxCertificate != null)
      NamedDocument('Tax Certificate', taxCertificate!),
    if (constitutionFile != null)
      NamedDocument('Constitution File', constitutionFile!),
    if (proofOfAddress != null)
      NamedDocument('Proof of Address', proofOfAddress!),
    if (bankDetails.voidCheque != null)
      NamedDocument('Void Cheque', bankDetails.voidCheque!),
    if (logo != null) NamedDocument('Logo', logo!),
  ];
}

class BankDetails {
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String bankBranch;
  final OrganizationDocument? voidCheque;

  const BankDetails({
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.bankBranch,
    required this.voidCheque,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: _asString(json['bankName']),
      accountHolderName: _asString(json['accountHolderName']),
      accountNumber: _asString(json['accountNumber']),
      bankBranch: _asString(json['bankBranch']),
      voidCheque: OrganizationDocument.fromMaybeJson(json['voidCheque']),
    );
  }
}

class SocialMedia {
  final String facebook;
  final String instagram;
  final String linkedin;

  const SocialMedia({
    required this.facebook,
    required this.instagram,
    required this.linkedin,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      facebook: _asString(json['facebook']),
      instagram: _asString(json['instagram']),
      linkedin: _asString(json['linkedin']),
    );
  }
}

class OrganizationDocument {
  final String id;
  final String url;
  final String publicId;
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime? uploadedAt;

  const OrganizationDocument({
    required this.id,
    required this.url,
    required this.publicId,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.uploadedAt,
  });

  factory OrganizationDocument.fromJson(Map<String, dynamic> json) {
    return OrganizationDocument(
      id: _asString(json['_id']),
      url: _asString(json['url']),
      publicId: _asString(json['publicId']),
      originalName: _asString(json['originalName']),
      mimeType: _asString(json['mimeType']),
      size: _asInt(json['size']) ?? 0,
      uploadedAt: _asDate(json['uploadedAt']),
    );
  }

  static OrganizationDocument? fromMaybeJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final doc = OrganizationDocument.fromJson(json);
    return doc.url.isEmpty ? null : doc;
  }

  bool get isPdf =>
      mimeType.toLowerCase().contains('pdf') ||
      originalName.toLowerCase().endsWith('.pdf') ||
      url.toLowerCase().contains('.pdf');

  bool get isImage => mimeType.toLowerCase().startsWith('image/');

  String get readableSize {
    if (size <= 0) return 'Unknown size';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class NamedDocument {
  final String label;
  final OrganizationDocument document;

  const NamedDocument(this.label, this.document);
}

String _asString(Object? value) => value?.toString() ?? '';

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _asDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
