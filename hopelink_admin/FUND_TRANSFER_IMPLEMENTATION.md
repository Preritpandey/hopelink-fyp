# Fund Transfer API Implementation Guide

## Overview
Complete admin fund transfer system for disbursing collected donations to organizations. Admins can initiate, track, and manage fund transfers with full audit trails.

---

## ✅ Implemented Endpoints

### 1. Initiate Fund Transfer
**Route:** `POST /api/v1/fund-transfers`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `initiateFundTransfer()`

**Description:** Create a new fund transfer request to an organization

**Request Body:**
```json
{
  "organizationId": "org_id_here",
  "amount": 50000,
  "transferMethod": "bank_transfer",
  "reason": "Campaign payout - Education Initiative Campaign",
  "reference": "CAMP-2024-001",
  "relatedCampaigns": ["campaign_id_1", "campaign_id_2"],
  "notes": "Optional admin notes"
}
```

**Parameters:**
- `organizationId` (required): MongoDB ObjectId of organization
- `amount` (required): Amount to transfer (must be > 0)
- `transferMethod` (required): One of `bank_transfer`, `stripe`, `khalti`, `cash`, `cheque`
- `reason` (required): Reason for transfer
- `reference` (optional): Unique reference number
- `relatedCampaigns` (optional): Array of campaign IDs
- `notes` (optional): Admin notes

**Response:**
```json
{
  "success": true,
  "message": "Fund transfer initiated successfully",
  "data": {
    "_id": "transfer_id",
    "transferId": "FT-123456-1",
    "organization": {
      "_id": "org_id",
      "organizationName": "Organization Name",
      "officialEmail": "org@example.com"
    },
    "amount": 50000,
    "transferMethod": "bank_transfer",
    "bankDetails": {
      "bankName": "Nepal Bank Ltd",
      "accountHolderName": "Org Name",
      "accountNumber": "****5678",
      "bankBranch": "Kathmandu"
    },
    "status": "initiated",
    "reason": "Campaign payout - Education Initiative Campaign",
    "reference": "CAMP-2024-001",
    "initiatedBy": {
      "_id": "admin_id",
      "name": "Admin Name",
      "email": "admin@example.com"
    },
    "initiatedAt": "2024-06-02T10:30:00Z",
    "expectedCompletionDate": "2024-06-07T00:00:00Z",
    "createdAt": "2024-06-02T10:30:00Z"
  }
}
```

**Example cURL:**
```bash
curl -X POST "https://hopelink-fyp.onrender.com/api/v1/fund-transfers" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "organizationId": "60d5e1f9e4b0d1b0c1e1e1e1",
    "amount": 50000,
    "transferMethod": "bank_transfer",
    "reason": "Campaign payout",
    "reference": "CAMP-2024-001"
  }'
```

---

### 2. Get All Fund Transfers
**Route:** `GET /api/v1/fund-transfers`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `getFundTransfers()`

**Query Parameters:**
- `status` (optional): Filter by status (initiated, processing, completed, failed, cancelled)
- `organizationId` (optional): Filter by organization
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "transfer_id",
      "transferId": "FT-123456-1",
      "organization": { /* org details */ },
      "amount": 50000,
      "status": "completed",
      ...
    }
  ],
  "pagination": {
    "total": 45,
    "page": 1,
    "next": { "page": 2, "limit": 10 },
    "prev": null
  }
}
```

**Example cURL:**
```bash
curl -X GET "https://hopelink-fyp.onrender.com/api/v1/fund-transfers?status=completed&page=1&limit=10" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"
```

---

### 3. Get Specific Fund Transfer
**Route:** `GET /api/v1/fund-transfers/:transferId`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `getFundTransfer()`

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "transfer_id",
    "transferId": "FT-123456-1",
    "organization": { /* org details */ },
    "amount": 50000,
    "status": "completed",
    "bankDetails": { /* bank info */ },
    "initiatedBy": { /* admin info */ },
    "completedBy": { /* admin info */ },
    ...
  }
}
```

---

### 4. Get Fund Transfers for Organization
**Route:** `GET /api/v1/fund-transfers/org/:organizationId/history`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `getFundTransfersForOrg()`

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Results per page

**Response:**
```json
{
  "success": true,
  "data": [ /* array of transfers */ ],
  "stats": [
    {
      "_id": "initiated",
      "totalAmount": 100000,
      "count": 2
    },
    {
      "_id": "completed",
      "totalAmount": 500000,
      "count": 10
    }
  ],
  "pagination": { /* pagination info */ }
}
```

---

### 5. Update Fund Transfer Status
**Route:** `PUT /api/v1/fund-transfers/:transferId/status`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `updateFundTransferStatus()`

**Request Body:**
```json
{
  "status": "completed",
  "transactionHash": "TXN-123456789",
  "notes": "Transfer successful via NEFT",
  "failureReason": null
}
```

**Parameters:**
- `status` (required): One of `initiated`, `processing`, `completed`, `failed`, `cancelled`
- `transactionHash` (optional): Transaction ID from payment gateway
- `notes` (optional): Additional notes
- `failureReason` (optional): Reason for failure (if status is failed)

**Response:**
```json
{
  "success": true,
  "message": "Fund transfer status updated to completed",
  "data": {
    "_id": "transfer_id",
    "status": "completed",
    "completedBy": { /* admin info */ },
    "completedAt": "2024-06-05T14:30:00Z",
    ...
  }
}
```

**Example cURL:**
```bash
curl -X PUT "https://hopelink-fyp.onrender.com/api/v1/fund-transfers/60d5e1f9e4b0d1b0c1e1e1e1/status" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "transactionHash": "TXN-123456789",
    "notes": "Transfer successful via NEFT"
  }'
```

---

### 6. Cancel Fund Transfer
**Route:** `PUT /api/v1/fund-transfers/:transferId/cancel`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `cancelFundTransfer()`

**Request Body:**
```json
{
  "reason": "Organization bank details invalid"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Fund transfer cancelled",
  "data": {
    "_id": "transfer_id",
    "status": "cancelled",
    "failureReason": "Organization bank details invalid",
    ...
  }
}
```

---

### 7. Get Fund Transfer Statistics
**Route:** `GET /api/v1/fund-transfers/stats/summary`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `getFundTransferStats()`

**Query Parameters:**
- `organizationId` (optional): Filter by organization
- `startDate` (optional): ISO date string
- `endDate` (optional): ISO date string

**Response:**
```json
{
  "success": true,
  "data": {
    "byStatus": [
      { "_id": "completed", "totalAmount": 500000, "count": 10 },
      { "_id": "processing", "totalAmount": 50000, "count": 2 },
      { "_id": "failed", "totalAmount": 10000, "count": 1 }
    ],
    "byMethod": [
      { "_id": "bank_transfer", "totalAmount": 500000, "count": 10 },
      { "_id": "cash", "totalAmount": 50000, "count": 2 }
    ],
    "totals": [
      {
        "totalAmount": 560000,
        "totalTransfers": 13,
        "avgTransferAmount": 43076.92
      }
    ]
  }
}
```

---

### 8. Get Organization Fund Transfer Summary
**Route:** `GET /api/v1/fund-transfers/org/:organizationId/summary`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `getOrgFundTransferSummary()`

**Response:**
```json
{
  "success": true,
  "data": {
    "organization": "Organization Name",
    "fundTransfers": {
      "totalTransferred": 500000,
      "totalPending": 50000,
      "totalFailed": 10000,
      "completedTransfers": 10,
      "pendingTransfers": 2,
      "failedTransfers": 1,
      "totalTransfers": 13
    },
    "fundraising": {
      "totalDonations": 560000
    },
    "outstandingAmount": 60000
  }
}
```

---

### 9. Generate Fund Transfer Receipt
**Route:** `GET /api/v1/fund-transfers/:transferId/receipt`  
**Access:** Private (Admin only)  
**Location:** `fundTransfer.controller.js` → `generateFundTransferReceipt()`

**Response:**
```json
{
  "success": true,
  "data": {
    "receiptNumber": "FT-123456-1",
    "reference": "CAMP-2024-001",
    "transactionHash": "TXN-123456789",
    "organization": {
      "name": "Organization Name",
      "registrationNumber": "REG-12345",
      "email": "org@example.com"
    },
    "transfer": {
      "amount": 50000,
      "method": "bank_transfer",
      "reason": "Campaign payout",
      "status": "completed"
    },
    "bankDetails": {
      "bankName": "Nepal Bank Ltd",
      "accountHolderName": "Org Name",
      "accountNumber": "****5678"
    },
    "dates": {
      "initiated": "2024-06-02T10:30:00Z",
      "completed": "2024-06-05T14:30:00Z",
      "expected": "2024-06-07T00:00:00Z"
    },
    "admin": {
      "initiatedBy": "Admin Name",
      "completedBy": "Admin Name 2"
    },
    "notes": "Transfer notes here"
  }
}
```

---

## 📊 Data Model

### FundTransfer Schema
```javascript
{
  transferId: String,              // Auto-generated: FT-XXXXXX-X
  organization: ObjectId,          // Ref to Organization
  amount: Number,                  // Must be > 0
  transferMethod: String,          // bank_transfer, stripe, khalti, cash, cheque
  bankDetails: {                   // Snapshot of org's bank details
    bankName: String,
    accountHolderName: String,
    accountNumber: String,
    bankBranch: String
  },
  status: String,                  // initiated, processing, completed, failed, cancelled
  reason: String,                  // Required reason
  reference: String,               // Optional unique reference
  initiatedBy: ObjectId,           // Admin who created
  completedBy: ObjectId,           // Admin who completed
  initiatedAt: Date,               // Creation timestamp
  completedAt: Date,               // Completion timestamp
  expectedCompletionDate: Date,    // Estimated completion
  notes: String,                   // Optional notes
  transactionHash: String,         // Payment gateway transaction ID
  failureReason: String,           // If failed, reason why
  relatedCampaigns: [ObjectId],    // Related campaign IDs
  metadata: Object,                // Additional data
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🔒 Security Features

✅ **Admin-only access** - All endpoints require admin role  
✅ **Audit trail** - All transfers logged with who initiated/completed  
✅ **Bank details validation** - Ensures org has bank details before transfer  
✅ **Duplicate prevention** - Unique reference numbers and transaction hashes  
✅ **Amount validation** - Must be positive number  
✅ **Status transitions** - Logical workflow (initiated → processing/failed → completed/cancelled)  
✅ **Email notifications** - Auto-notify organization on status changes  

---

## 📧 Email Notifications

Automatic emails sent to organization when:

1. **Transfer Initiated** - `fund-transfer-initiated` template
2. **Transfer Completed** - `fund-transfer-completed` template
3. **Transfer Failed** - `fund-transfer-failed` template
4. **Transfer Cancelled** - `fund-transfer-cancelled` template

---

## 🚀 Implementation Notes

### Status Workflow
```
initiated → processing → completed
           → failed
           → cancelled
```

### Transfer ID Generation
- Format: `FT-{timestamp}-{count}`
- Example: `FT-234567-1`
- Auto-generated on save if not provided

### Expected Completion Dates
- Automatically set to 5 business days from initiation
- Can be customized per transfer

### Bank Details
- Snapshot of organization's bank details at time of transfer
- Prevents issues if org updates bank details later
- Secure handling of account numbers

---

## 🔄 Integration with Existing Systems

### Donation Model Integration
```
Donation (collected) → FundTransfer (disbursement)
```

### Organization Model Integration
```
Organization.bankDetails → FundTransfer.bankDetails (snapshot)
```

### Admin Dashboard Integration
- Track total transferred vs. collected
- See outstanding amounts per organization
- Monitor transfer status in real-time

---

## 📊 Analytics & Reporting

**Summary Statistics Available:**
- Total transferred amount
- Total pending amount
- Total failed amount
- Transfer count by status
- Transfer count by method
- Average transfer amount
- Outstanding balances

---

## ⚠️ Error Handling

| Error | Status | Message |
|-------|--------|---------|
| Missing required fields | 400 | Specific field required |
| Invalid amount | 400 | Amount must be greater than 0 |
| Org not found | 404 | Organization not found |
| No bank details | 400 | Organization has no bank details on file |
| Invalid reference | 400 | A transfer with this reference already exists |
| Invalid status | 400 | Invalid status |
| Transfer not found | 404 | Fund transfer not found |
| Cannot cancel completed | 400 | Cannot cancel a completed transfer |

---

## 🧪 Testing Examples

### Create Transfer
```bash
POST /api/v1/fund-transfers
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json

{
  "organizationId": "60d5e1f9e4b0d1b0c1e1e1e1",
  "amount": 25000,
  "transferMethod": "bank_transfer",
  "reason": "Monthly payout",
  "reference": "PAYOUT-JUN-2024-001"
}
```

### Mark as Complete
```bash
PUT /api/v1/fund-transfers/60d5e1f9e4b0d1b0c1e1e1e2/status
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json

{
  "status": "completed",
  "transactionHash": "NEFT-123456",
  "notes": "Successfully transferred via NEFT"
}
```

### Get Stats
```bash
GET /api/v1/fund-transfers/stats/summary?startDate=2024-01-01&endDate=2024-06-02
Authorization: Bearer ADMIN_TOKEN
```

---

## 📱 Flutter Integration

Example for admin dashboard:
```dart
// Fetch all transfers
Future<List<FundTransfer>> getFundTransfers() async {
  final uri = Uri.parse('$_base/fund-transfers');
  final res = await http.get(uri, headers: _authHeaders);
  // Parse response
}

// Initiate transfer
Future<bool> initiateFundTransfer(
  String organizationId,
  double amount,
  String reason
) async {
  final uri = Uri.parse('$_base/fund-transfers');
  final res = await http.post(
    uri,
    headers: _authHeaders,
    body: jsonEncode({
      'organizationId': organizationId,
      'amount': amount,
      'transferMethod': 'bank_transfer',
      'reason': reason,
    }),
  );
  return res.statusCode == 201;
}
```

---

## 📋 Database Indexes

Created for performance:
- `{ organization: 1, status: 1 }`
- `{ initiatedAt: -1 }`
- `{ status: 1, initiatedAt: -1 }`
- `{ transferId: 1 }` (unique)
- `{ reference: 1 }` (unique, sparse)
- `{ transactionHash: 1 }` (unique, sparse)

---

## 🎯 Next Steps

1. ✅ Create email templates for notifications
2. ✅ Add fund transfer widgets to admin dashboard
3. ✅ Implement payment gateway integration
4. ✅ Create bulk transfer feature
5. ✅ Add transfer scheduling/automation
6. ✅ Implement transfer reversals
7. ✅ Add advanced filtering & search
8. ✅ Create transfer analytics dashboard
