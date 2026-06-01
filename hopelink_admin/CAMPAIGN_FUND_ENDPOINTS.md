# Campaign Fund Collection Endpoints - HopeLink Backend

## Overview
This document outlines all backend endpoints related to tracking and retrieving fund collection data for campaigns organized by nonprofits.

---

## 1. Campaign Fund Status Endpoints

### 1.1 Get Campaign Fund Status
**Route:** `GET /api/v1/campaigns/:id/fund-status`  
**Access:** Public (Unauthenticated)  
**Location:** `campaign.controller.js` → `getCampaignFundStatus()`

**Description:** Retrieves comprehensive fund tracking information for a specific campaign including progress, donation statistics, and timeline.

**Response Data Structure:**
```json
{
  "success": true,
  "data": {
    "campaignId": "ObjectId",
    "campaignTitle": "string",
    "organization": {
      "id": "ObjectId",
      "name": "string",
      "totalDonationsReceived": "number",
      "totalDonationCount": "number"
    },
    "fundStatus": {
      "targetAmount": "number",
      "currentAmount": "number",
      "remainingAmount": "number",
      "progress": "number (decimal)",
      "progressPercentage": "number (0-100)",
      "donationCount": "number",
      "isComplete": "boolean"
    },
    "timeline": {
      "startDate": "ISO DateTime",
      "endDate": "ISO DateTime",
      "daysRemaining": "number",
      "isActive": "boolean"
    }
  }
}
```

**Example cURL:**
```bash
curl -X GET "https://hopelink-fyp.onrender.com/api/v1/campaigns/{campaignId}/fund-status"
```

---

### 1.2 Get Organization Fund Status
**Route:** `GET /api/v1/campaigns/organization/{orgId}/fund-status`  
**Access:** Public (Unauthenticated)  
**Location:** `campaign.controller.js` → `getOrganizationFundStatus()`

**Description:** Retrieves aggregated fund tracking information for ALL campaigns of a specific organization.

**Response Data Structure:**
```json
{
  "success": true,
  "data": {
    "organizationId": "ObjectId",
    "organizationName": "string",
    "fundStatus": {
      "totalDonationsReceived": "number",
      "totalDonationCount": "number",
      "totalCampaigns": "number",
      "activeCampaigns": "number",
      "completedCampaigns": "number"
    },
    "campaignOverview": {
      "totalTargetAmount": "number",
      "totalCurrentAmount": "number",
      "remainingAmount": "number",
      "overallProgress": "number (0-100)"
    },
    "recentDonations": [
      {
        "amount": "number",
        "donor": "ObjectId",
        "campaignId": "ObjectId",
        "createdAt": "ISO DateTime"
      }
    ]
  }
}
```

**Note:** This endpoint is defined in routes but may need to be added to the routes file.

---

## 2. Donation Summary Endpoints

### 2.1 Get Organization Donation Summary (Current User's Organization)
**Route:** `GET /api/v1/donations/summary/org`  
**Access:** Private (Organization authenticated)  
**Location:** `donation.controller.js` → `getOrgDonationSummary()`

**Description:** Retrieves the total amount and count of completed donations for the authenticated user's organization.

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
```

**Response Data Structure:**
```json
{
  "success": true,
  "data": {
    "_id": "OrganizationId",
    "totalAmount": "number",
    "donationCount": "number"
  }
}
```

---

### 2.2 Get All Organizations' Donation Summary
**Route:** `GET /api/v1/donations/summary/all`  
**Access:** Private (Admin only)  
**Location:** `donation.controller.js` → `getDonationsSummaryByOrg()`

**Description:** Retrieves donation summary aggregated by organization for all organizations. Admin endpoint.

**Headers Required:**
```
Authorization: Bearer {ADMIN_JWT_TOKEN}
Content-Type: application/json
```

**Response Data Structure:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "OrganizationId",
      "totalAmount": "number",
      "donationCount": "number"
    },
    ...
  ]
}
```

---

### 2.3 Get Specific Organization Donation Summary by ID
**Route:** `GET /api/v1/donations/summary/org/:orgId`  
**Access:** Private (Admin only)  
**Location:** `donation.controller.js` → `getOrgDonationSummaryById()`

**Description:** Retrieves donation summary for a specific organization by ID. Admin endpoint.

**Headers Required:**
```
Authorization: Bearer {ADMIN_JWT_TOKEN}
```

**Response Data Structure:**
```json
{
  "success": true,
  "data": {
    "_id": "OrganizationId",
    "totalAmount": "number",
    "donationCount": "number"
  }
}
```

**Example cURL:**
```bash
curl -X GET "https://hopelink-fyp.onrender.com/api/v1/donations/summary/org/{orgId}" \
  -H "Authorization: Bearer {ADMIN_JWT_TOKEN}"
```

---

## 3. Campaign Donations Endpoints

### 3.1 Get Donations for Specific Campaign
**Route:** `GET /api/v1/campaigns/:campaignId/donations`  
**Access:** Private (Organization or Admin)  
**Location:** `donation.controller.js` → `getDonationsForCampaign()`

**Query Parameters:**
- `page` (number): Page number for pagination (default: 1)
- `limit` (number): Number of donations per page (default: 10)
- `sort` (string): Sort order (e.g., `-createdAt` for newest first)

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
```

**Description:** Retrieves paginated list of donations for a specific campaign.

**Response Data Structure:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "DonationId",
      "amount": "number",
      "donor": "ObjectId",
      "campaignId": "ObjectId",
      "createdAt": "ISO DateTime",
      ...
    }
  ],
  "pagination": {
    "next": {
      "page": "number",
      "limit": "number"
    }
  }
}
```

**Example cURL:**
```bash
curl -X GET "https://hopelink-fyp.onrender.com/api/v1/campaigns/{campaignId}/donations?page=1&limit=10&sort=-createdAt" \
  -H "Authorization: Bearer {JWT_TOKEN}"
```

---

## 4. Key Data Points Available

### Campaign-Level Metrics
- **targetAmount**: Total goal for the campaign
- **currentAmount**: Amount collected so far
- **remainingAmount**: Calculated (targetAmount - currentAmount)
- **progressPercentage**: Calculated progress (0-100%)
- **donationCount**: Total number of donations
- **isComplete**: Boolean indicating if target is reached

### Organization-Level Metrics
- **totalDonationsReceived**: Total amount donated across all campaigns
- **totalDonationCount**: Total number of donations across all campaigns
- **totalCampaigns**: Total number of campaigns
- **activeCampaigns**: Number of currently active campaigns
- **completedCampaigns**: Number of campaigns with target met
- **overallProgress**: Aggregate progress percentage

### Timeline Information
- **startDate**: Campaign start date
- **endDate**: Campaign end date
- **daysRemaining**: Days left until campaign ends
- **isActive**: Boolean indicating if campaign is still active

---

## 5. Implementation in Flutter Frontend

### Current Implementation in `campaign_list_controller.dart`

The frontend already implements several fund-related features:

**Fetching Campaign Data:**
```dart
Future<void> fetchCampaigns() async {
  // Fetches organization campaigns
  final uri = Uri.parse('$_base/campaigns/organization');
  final res = await http.get(uri, headers: _authHeaders);
}
```

**Available Getters for Fund Stats:**
```dart
int get activeCount => allCampaigns.where((c) => c.status == 'active').length;

double get totalRaised =>
    allCampaigns.fold(0.0, (sum, c) => sum + c.currentAmount);

double get totalTarget =>
    allCampaigns.fold(0.0, (sum, c) => sum + c.targetAmount);

double get overallProgress =>
    totalTarget > 0 ? (totalRaised / totalTarget * 100).clamp(0, 100) : 0;

int get withImagesCount => allCampaigns.where((c) => c.hasImages).length;

int get totalUpdates =>
    allCampaigns.fold(0, (sum, c) => sum + c.updates.length);
```

---

## 6. Recommended Usage Scenarios

### For Organization Admins:
1. **Dashboard Overview**: Use campaign fund-status endpoint to show current campaign progress
2. **Organization Summary**: Use `/donations/summary/org` to show total funds raised
3. **Campaign Details**: Use `/campaigns/:id/fund-status` for detailed fund tracking

### For General Users:
1. **Campaign Progress**: Use public `/campaigns/:id/fund-status` endpoint (no auth required)
2. **Campaign List**: Use `/campaigns` endpoint to get all campaigns

### For Admin/Analytics:
1. **Organization Comparison**: Use `/donations/summary/all` to compare organizations
2. **Specific Organization**: Use `/donations/summary/org/:orgId` for detailed analysis

---

## 7. Authentication

- **Public Endpoints**: No authentication required
- **Organization Endpoints**: Requires valid JWT token with `organization` role
- **Admin Endpoints**: Requires valid JWT token with `admin` role

**Token Location**: `Authorization: Bearer {JWT_TOKEN}`

---

## 8. Base URL
```
https://hopelink-fyp.onrender.com/api/v1
```

---

## Notes
- All monetary amounts are in NPR (Nepalese Rupees)
- Donation status is typically 'completed', 'pending', or 'failed'
- Pagination uses `limit` and `page` parameters
- Sort parameter uses MongoDB sort syntax (e.g., `-createdAt` for descending)
