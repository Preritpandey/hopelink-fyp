// ─────────────────────────────────────────────────────────────
//  MODEL  —  organization_model.dart
// ─────────────────────────────────────────────────────────────

class OrganizationRegistrationRequest {
  // ── Basic Info ──────────────────────────────────────────────
  final String organizationName;
  final String organizationType;
  final String registrationNumber;
  final String dateOfRegistration; // "YYYY-MM-DD"
  final String country;
  final String city;
  final String registeredAddress;

  // ── Contact ─────────────────────────────────────────────────
  final String officialEmail;
  final String officialPhone;
  final String? website;

  // ── Social ──────────────────────────────────────────────────
  final String? facebook;
  final String? instagram;
  final String? linkedin;

  // ── Representative ──────────────────────────────────────────
  final String representativeName;
  final String designation;

  // ── Bank ────────────────────────────────────────────────────
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String bankBranch;

  // ── Mission ─────────────────────────────────────────────────
  final String primaryCause;
  final String missionStatement;
  final int activeMembers;
  final String recentCampaigns;

  // ── Files ───────────────────────────────────────────────────
  final String taxCertificatePath;
  final String constitutionFilePath;
  final String proofOfAddressPath;
  final String voidChequePath;

  const OrganizationRegistrationRequest({
    required this.organizationName,
    required this.organizationType,
    required this.registrationNumber,
    required this.dateOfRegistration,
    required this.country,
    required this.city,
    required this.registeredAddress,
    required this.officialEmail,
    required this.officialPhone,
    this.website,
    this.facebook,
    this.instagram,
    this.linkedin,
    required this.representativeName,
    required this.designation,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.bankBranch,
    required this.primaryCause,
    required this.missionStatement,
    required this.activeMembers,
    required this.recentCampaigns,
    required this.taxCertificatePath,
    required this.constitutionFilePath,
    required this.proofOfAddressPath,
    required this.voidChequePath,
  });
}

// ── Success Response ─────────────────────────────────────────
class OrganizationRegistrationResponse {
  final bool success;
  final String message;
  final OrganizationData data;

  const OrganizationRegistrationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OrganizationRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationRegistrationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: OrganizationData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class OrganizationData {
  final String id;
  final String name;
  final String status;

  const OrganizationData({
    required this.id,
    required this.name,
    required this.status,
  });

  factory OrganizationData.fromJson(Map<String, dynamic> json) {
    return OrganizationData(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
    );
  }
}

// ── Org Type Enum ────────────────────────────────────────────
enum OrganizationType {
  ngo('NGO'),
  ingo('INGO'),
  nonprofit('Non-Profit'),
  charity('Charity'),
  foundation('Foundation'),
  socialEnterprise('Social Enterprise');

  final String label;
  const OrganizationType(this.label);
}
