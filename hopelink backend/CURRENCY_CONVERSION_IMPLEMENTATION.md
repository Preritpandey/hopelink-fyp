# Donation Currency Conversion Fix - Complete Implementation Guide

## Overview

This document describes the fixes implemented to handle currency conversion for donations in the HopeLink backend. The system now correctly converts all donations to NPR (Nepali Rupees) regardless of the input currency, ensuring accurate campaign totals and organization statements.

## Problem Statement

### Original Issue
- When a user from USA donated $100 USD, it was being added to campaign totals as `100` instead of the NPR-converted amount (~16,000 NPR)
- Campaign that needed 100,000 NPR with 50,000 NPR collected would show 50,100 after a $100 USD donation instead of ~66,000 NPR
- Organization statements were showing foreign currency amounts instead of NPR

### Root Causes
1. **fundTransfer.controller.js**: Organization statement aggregation was summing raw `campaignAmount` instead of `convertedAmountNpr`
2. **donation.controller.js - createDonation()**: The function wasn't accepting a currency parameter and always assumed NPR
3. **Multiple aggregation pipelines**: Some donation queries weren't using the NPR conversion fields

## Solutions Implemented

### 1. Fixed Fund Transfer Organization Statement (CRITICAL)

**File**: `backend/src/controllers/fundTransfer.controller.js`

**Change**: Updated the organization fund transfer summary aggregation to use `convertedAmountNpr`:

```javascript
// Before (WRONG):
const [donations] = await Donation.aggregate([
  { $match: { organization: new mongoose.Types.ObjectId(organizationId), status: 'completed' } },
  {
    $group: {
      _id: null,
      totalDonations: { $sum: { $ifNull: ['$campaignAmount', '$amount'] } },
    },
  },
]);

// After (CORRECT):
const [donations] = await Donation.aggregate([
  { $match: { organization: new mongoose.Types.ObjectId(organizationId), status: 'completed' } },
  {
    $group: {
      _id: null,
      totalDonations: { $sum: { $ifNull: ['$convertedAmountNpr', { $ifNull: ['$campaignAmount', '$amount'] }] } },
    },
  },
]);
```

**Impact**: Organization statements now correctly show NPR-converted totals for all donations regardless of input currency.

### 2. Enhanced createDonation() to Support Currency Conversion

**File**: `backend/src/controllers/donation.controller.js`

**Changes**:
- Added `currency` parameter to the request body (defaults to 'NPR' for backward compatibility)
- Added currency conversion logic using the `convertToNPR` service
- Pass the exchange rate to `buildNprConversionSnapshot`

```javascript
// Key additions:
const {
  // ... other params
  currency = 'NPR',
} = req.body;

// Convert to NPR if currency is not NPR
let exchangeRate = 1;
if (String(currency).toUpperCase() !== 'NPR') {
  const rateData = await convertToNPR(1, currency);
  exchangeRate = rateData.exchangeRate;
}

const conversion = buildNprConversionSnapshot({
  campaignAmount: amounts.campaignAmount,
  platformSupportAmount: amounts.platformSupportAmount,
  totalAmount: amounts.totalAmount,
  currency: currency,
  exchangeRate: exchangeRate,
});
```

**Impact**: Direct donations (non-Stripe/Khalti) now support any currency and are correctly converted to NPR.

### 3. Verified Donation Aggregations Use NPR

**Status**: ✅ Already Correct

The following functions already use the `campaignDonationNprExpression` which correctly falls back to NPR amounts:
- `getOrgDonationSummary()` - line 303
- `getDonationsSummaryByOrg()` - line 340
- `getOrgDonationSummaryById()` - line 368
- `getDonations()` - applies `withDonationNprAmounts` to all results

## How It Works

### Donation Flow

```
1. Donation received in foreign currency (e.g., $100 USD)
         ↓
2. Exchange rate fetched from exchangerate-api.com
   USD 1 = 130.50 NPR
         ↓
3. Conversion snapshot created:
   - originalAmount: 100 USD
   - originalCurrency: USD
   - exchangeRate: 130.50
   - convertedAmountNpr: 13050
         ↓
4. Campaign updated with NPR amount:
   campaign.currentAmount += 13050 (NOT 100)
         ↓
5. Organization updated with NPR amount:
   org.totalDonationsReceived += 13050
         ↓
6. Donation record stored with both original and converted amounts
         ↓
7. Statements, reports, and aggregations use convertedAmountNpr
```

### Data Model

Each donation now stores:

```javascript
{
  // Original values
  amount: 100,                           // Raw input amount
  campaignAmount: 100,                   // Campaign portion in input currency
  platformSupportAmount: 0,              // Support portion in input currency
  totalAmount: 100,                      // Total in input currency
  
  // Original currency info
  originalCurrency: "USD",               // Input currency
  exchangeRate: 130.50,                  // Conversion rate
  
  // Converted amounts (NPR)
  convertedAmountNpr: 13050,            // Converted campaign amount
  convertedPlatformSupportAmountNpr: 0, // Converted support amount
  convertedTotalAmountNpr: 13050,       // Converted total
  
  // For convenience (added via withDonationNprAmounts)
  amountNpr: 13050,
  campaignAmountNpr: 13050,
  platformSupportAmountNpr: 0,
  totalAmountNpr: 13050,
}
```

## Testing Guide

### Automated Test Script

Run the provided test script:

```bash
# View test details
node CURRENCY_CONVERSION_TEST.js manual

# Or run automated tests (requires API running)
node CURRENCY_CONVERSION_TEST.js
```

### Manual Testing with Postman/Insomnia

#### Test 1: Create USD Donation

```
POST /api/v1/donations
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "campaign": "66d4f8e1c3b2a1f5g9h8i7j6",
  "amount": 100,
  "campaignAmount": 100,
  "supportPlatform": false,
  "paymentMethod": "stripe",
  "paymentId": "test_usd_$(date +%s)",
  "currency": "USD"
}
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "amountNpr": 13050,
    "campaignAmountNpr": 13050,
    "originalCurrency": "USD",
    "exchangeRate": 130.50,
    "convertedAmountNpr": 13050
  }
}
```

#### Test 2: Verify Campaign Updated in NPR

```
GET /api/v1/campaigns/66d4f8e1c3b2a1f5g9h8i7j6
```

**Expected**: `currentAmount` includes the NPR-converted value, NOT the original USD amount

#### Test 3: Verify Organization Statement

```
GET /api/v1/admin/fund-transfers/org/66d4f8e1c3b2a1f5g9h8i7j6/summary
Authorization: Bearer <ADMIN_TOKEN>
```

**Expected**: `fundraising.totalDonations` shows sum of all donations in NPR

#### Test 4: Multi-Currency Test

Create donations in different currencies:

```bash
# USD
POST /donations with currency: "USD", amount: 100
# Expected: ~13,050 NPR

# INR  
POST /donations with currency: "INR", amount: 1000
# Expected: ~155 NPR

# EUR
POST /donations with currency: "EUR", amount: 50
# Expected: ~5,200 NPR

# GBP
POST /donations with currency: "GBP", amount: 50
# Expected: ~6,500 NPR
```

Then verify:
1. Each donation has correct `convertedAmountNpr`
2. Campaign `currentAmount` = sum of all `convertedAmountNpr` values
3. Organization statement shows correct NPR total

## Validation Checklist

- [ ] **Stripe Payments**: Already correctly handle currency conversion (verified in `completeStripePayment`)
- [ ] **Khalti Payments**: Already correctly handle currency conversion (verified in `completeKhaltiPayment`)
- [ ] **Direct Donations**: Now support currency parameter and conversion
- [ ] **Campaign Totals**: Updated using `convertedAmountNpr` values
- [ ] **Organization Totals**: Updated using `convertedAmountNpr` values
- [ ] **Fund Transfer Statements**: Aggregate using `convertedAmountNpr`
- [ ] **Donation Lists**: Return `amountNpr` and `campaignAmountNpr` fields
- [ ] **Original Data Preserved**: All original currency/amount data retained for audit trail

## Exchange Rate Source

The system uses the free exchangerate-api.com API to fetch real-time exchange rates:
- Endpoint: `https://api.exchangerate-api.com/v4/latest/{CURRENCY}`
- Rate: Base rate per 1 unit of input currency
- Timeout: 10 seconds
- Fallback: If rate fetch fails, donation creation fails (returns error)

## Backward Compatibility

- **Default currency**: 'NPR' (maintains existing behavior)
- **Existing donations**: All donations without explicit currency are treated as NPR
- **API contract**: No breaking changes, `currency` parameter is optional

## Files Modified

1. `backend/src/controllers/fundTransfer.controller.js`
   - Fixed: `getOrgFundTransferSummary()` aggregation

2. `backend/src/controllers/donation.controller.js`
   - Enhanced: `createDonation()` to accept and convert currency

## Files Created

1. `CURRENCY_CONVERSION_TEST.js`
   - Manual testing guide
   - Test case scenarios for USD, INR, EUR, GBP
   - Validation instructions

## Deployment Steps

1. **Backup database** (if applicable)
2. **Deploy updated backend code**
3. **Verify API is running**: `GET /api/v1/health`
4. **Run manual tests** with different currencies
5. **Check organization statements** for existing donations
6. **Monitor error logs** for exchange rate fetch failures

## Monitoring & Troubleshooting

### Check Exchange Rate Service

```javascript
// In backend console/debug
const { convertToNPR } = require('./services/payment.service');
await convertToNPR(100, 'USD');
// Should return: { originalAmount: 100, originalCurrency: 'USD', exchangeRate: 130.50, convertedAmountNpr: 13050 }
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| NPR amount shows as raw amount | `convertedAmountNpr` not populated | Check if currency conversion was triggered |
| Campaign total incorrect | Not using NPR converted amount | Verify campaign update uses `conversion.convertedAmountNpr` |
| Organization statement wrong | Old aggregation using raw amounts | Confirm fundTransfer controller is using new aggregation |
| Exchange rate always 1.0 | API request failed | Check network connectivity to exchangerate-api.com |

## Future Improvements

1. **Cache exchange rates** to reduce API calls
2. **Add scheduled rate updates** for more accurate conversions
3. **Support offline mode** with historical rates
4. **Add currency preferences** per user/organization
5. **Audit trail** for exchange rate changes
6. **Webhook notifications** when exchange rates significantly change

## Support & Questions

For questions or issues with the currency conversion implementation:
1. Check the test results in CURRENCY_CONVERSION_TEST.js
2. Review this guide's troubleshooting section
3. Check backend logs for exchange rate fetch errors
4. Verify database donation records have `convertedAmountNpr` populated
