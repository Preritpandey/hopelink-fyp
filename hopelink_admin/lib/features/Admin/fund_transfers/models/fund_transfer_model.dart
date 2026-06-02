class FundTransferResponse {
  final bool success;
  final List<FundTransfer> data;
  final TransferPagination? pagination;

  const FundTransferResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory FundTransferResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return FundTransferResponse(
      success: json['success'] == true,
      data: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(FundTransfer.fromJson)
              .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? TransferPagination.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class TransferPagination {
  final int total;
  final int page;
  final int? nextPage;
  final int? prevPage;

  const TransferPagination({
    required this.total,
    required this.page,
    this.nextPage,
    this.prevPage,
  });

  factory TransferPagination.fromJson(Map<String, dynamic> json) {
    return TransferPagination(
      total: _asInt(json['total']) ?? 0,
      page: _asInt(json['page']) ?? 1,
      nextPage: json['next'] is Map<String, dynamic>
          ? _asInt((json['next'] as Map<String, dynamic>)['page'])
          : null,
      prevPage: json['prev'] is Map<String, dynamic>
          ? _asInt((json['prev'] as Map<String, dynamic>)['page'])
          : null,
    );
  }
}

class FundTransfer {
  final String id;
  final String transferId;
  final TransferOrganization? organization;
  final double amount;
  final String transferMethod;
  final BankSnapshot? bankDetails;
  final String status;
  final String reason;
  final String reference;
  final String notes;
  final String transactionHash;
  final String failureReason;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final DateTime? expectedCompletionDate;
  final DateTime? createdAt;

  const FundTransfer({
    required this.id,
    required this.transferId,
    required this.organization,
    required this.amount,
    required this.transferMethod,
    required this.bankDetails,
    required this.status,
    required this.reason,
    required this.reference,
    required this.notes,
    required this.transactionHash,
    required this.failureReason,
    required this.initiatedAt,
    required this.completedAt,
    required this.expectedCompletionDate,
    required this.createdAt,
  });

  factory FundTransfer.fromJson(Map<String, dynamic> json) {
    return FundTransfer(
      id: _asString(json['_id']),
      transferId: _asString(json['transferId']),
      organization: json['organization'] is Map<String, dynamic>
          ? TransferOrganization.fromJson(
              json['organization'] as Map<String, dynamic>,
            )
          : json['organization'] is String
              ? TransferOrganization(
                  id: _asString(json['organization']),
                  organizationName: 'Organization',
                  officialEmail: '',
                  registrationNumber: '',
                )
              : null,
      amount: _asDouble(json['amount']),
      transferMethod: _asString(json['transferMethod']),
      bankDetails: json['bankDetails'] is Map<String, dynamic>
          ? BankSnapshot.fromJson(json['bankDetails'] as Map<String, dynamic>)
          : null,
      status: _asString(json['status']).isEmpty
          ? 'initiated'
          : _asString(json['status']),
      reason: _asString(json['reason']),
      reference: _asString(json['reference']),
      notes: _asString(json['notes']),
      transactionHash: _asString(json['transactionHash']),
      failureReason: _asString(json['failureReason']),
      initiatedAt: _asDate(json['initiatedAt']),
      completedAt: _asDate(json['completedAt']),
      expectedCompletionDate: _asDate(json['expectedCompletionDate']),
      createdAt: _asDate(json['createdAt']),
    );
  }

  String get displayId => transferId.isNotEmpty ? transferId : id;
  String get organizationName =>
      organization?.organizationName.isNotEmpty == true
          ? organization!.organizationName
          : 'Organization';
  bool get canCancel => status != 'completed' && status != 'cancelled';
}

class TransferOrganization {
  final String id;
  final String organizationName;
  final String officialEmail;
  final String registrationNumber;

  const TransferOrganization({
    required this.id,
    required this.organizationName,
    required this.officialEmail,
    required this.registrationNumber,
  });

  factory TransferOrganization.fromJson(Map<String, dynamic> json) {
    return TransferOrganization(
      id: _asString(json['_id']).isEmpty ? _asString(json['id']) : _asString(json['_id']),
      organizationName: _asString(json['organizationName']).isEmpty
          ? _asString(json['name'])
          : _asString(json['organizationName']),
      officialEmail: _asString(json['officialEmail']).isEmpty
          ? _asString(json['email'])
          : _asString(json['officialEmail']),
      registrationNumber: _asString(json['registrationNumber']),
    );
  }
}

class BankSnapshot {
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String bankBranch;

  const BankSnapshot({
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.bankBranch,
  });

  factory BankSnapshot.fromJson(Map<String, dynamic> json) {
    return BankSnapshot(
      bankName: _asString(json['bankName']),
      accountHolderName: _asString(json['accountHolderName']),
      accountNumber: _asString(json['accountNumber']),
      bankBranch: _asString(json['bankBranch']),
    );
  }
}

class FundTransferStats {
  final List<TransferStatBucket> byStatus;
  final List<TransferStatBucket> byMethod;
  final double totalAmount;
  final int totalTransfers;
  final double averageTransferAmount;

  const FundTransferStats({
    required this.byStatus,
    required this.byMethod,
    required this.totalAmount,
    required this.totalTransfers,
    required this.averageTransferAmount,
  });

  factory FundTransferStats.empty() => const FundTransferStats(
        byStatus: [],
        byMethod: [],
        totalAmount: 0,
        totalTransfers: 0,
        averageTransferAmount: 0,
      );

  factory FundTransferStats.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] is List && (json['totals'] as List).isNotEmpty
        ? (json['totals'] as List).first
        : const {};
    final totalMap = totals is Map<String, dynamic> ? totals : const {};
    return FundTransferStats(
      byStatus: (json['byStatus'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TransferStatBucket.fromJson)
          .toList(),
      byMethod: (json['byMethod'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TransferStatBucket.fromJson)
          .toList(),
      totalAmount: _asDouble(totalMap['totalAmount']),
      totalTransfers: _asInt(totalMap['totalTransfers']) ?? 0,
      averageTransferAmount: _asDouble(totalMap['avgTransferAmount']),
    );
  }

  double amountForStatus(String status) {
    return byStatus
        .where((item) => item.id == status)
        .fold(0, (sum, item) => sum + item.totalAmount);
  }

  int countForStatus(String status) {
    return byStatus
        .where((item) => item.id == status)
        .fold(0, (sum, item) => sum + item.count);
  }
}

class TransferStatBucket {
  final String id;
  final double totalAmount;
  final int count;

  const TransferStatBucket({
    required this.id,
    required this.totalAmount,
    required this.count,
  });

  factory TransferStatBucket.fromJson(Map<String, dynamic> json) {
    return TransferStatBucket(
      id: _asString(json['_id']),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']) ?? 0,
    );
  }
}

class DonationOrgSummary {
  final String organizationId;
  final double totalAmount;
  final int donationCount;

  const DonationOrgSummary({
    required this.organizationId,
    required this.totalAmount,
    required this.donationCount,
  });

  factory DonationOrgSummary.fromJson(Map<String, dynamic> json) {
    return DonationOrgSummary(
      organizationId: _asString(json['_id']),
      totalAmount: _asDouble(json['totalAmount']),
      donationCount: _asInt(json['donationCount']) ?? 0,
    );
  }
}

class FundTransferReceipt {
  final String receiptNumber;
  final String reference;
  final String transactionHash;
  final String organizationName;
  final double amount;
  final String method;
  final String status;
  final String notes;

  const FundTransferReceipt({
    required this.receiptNumber,
    required this.reference,
    required this.transactionHash,
    required this.organizationName,
    required this.amount,
    required this.method,
    required this.status,
    required this.notes,
  });

  factory FundTransferReceipt.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>? ?? {};
    final transfer = json['transfer'] as Map<String, dynamic>? ?? {};
    return FundTransferReceipt(
      receiptNumber: _asString(json['receiptNumber']),
      reference: _asString(json['reference']),
      transactionHash: _asString(json['transactionHash']),
      organizationName: _asString(org['name']),
      amount: _asDouble(transfer['amount']),
      method: _asString(transfer['method']),
      status: _asString(transfer['status']),
      notes: _asString(json['notes']),
    );
  }
}

String _asString(Object? value) => value?.toString() ?? '';

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

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
