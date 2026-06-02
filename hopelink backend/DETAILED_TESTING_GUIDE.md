# Step-by-Step Testing Guide for Currency Conversion

## 📋 Prerequisites

Before testing, you need:
- Backend running at `http://localhost:3000`
- API token for authentication (from login)
- A test campaign ID
- An organization ID
- Postman/Insomnia or curl

## 🔑 Getting Required IDs

### 1. Get Your Auth Token
```bash
POST http://localhost:3000/api/v1/auth/login
Content-Type: application/json

{
  "email": "your@email.com",
  "password": "yourpassword"
}
```
Copy the `token` from response.

### 2. Get a Campaign ID
```bash
GET http://localhost:3000/api/v1/campaigns
Authorization: Bearer <YOUR_TOKEN>
```
Use any `_id` from the response, or create a test campaign.

### 3. Get Organization ID (From Campaign)
```bash
GET http://localhost:3000/api/v1/campaigns/<CAMPAIGN_ID>
Authorization: Bearer <YOUR_TOKEN>
```
Look for the `organization` field in the response.

## 🧪 Test Scenario

Let's test with a realistic scenario:

**Campaign Target**: 100,000 NPR
**Already Received**: 50,000 NPR in smaller NPR donations

**New Donations to Test**:
- Donor from USA: $100 USD
- Donor from India: ₹1000 INR  
- Donor from Europe: €50 EUR

**Expected Results**:
- USA: $100 ≈ 13,050 NPR
- India: ₹1000 ≈ 155 NPR
- Europe: €50 ≈ 5,200 NPR
- **Total**: 50,000 + 13,050 + 155 + 5,200 = **68,405 NPR** (NOT 50 + 100 + 1000 + 50 = 51,150)

## 🚀 Step-by-Step Testing

### STEP 1: Create Initial Donation (NPR baseline)

**Postman Setup:**
```
Method: POST
URL: http://localhost:3000/api/v1/donations
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
  - Content-Type: application/json
Body:
{
  "campaign": "<CAMPAIGN_ID>",
  "amount": 50000,
  "campaignAmount": 50000,
  "supportPlatform": false,
  "paymentMethod": "test",
  "paymentId": "init_npr_50k",
  "currency": "NPR"
}
```

**Verify Response:**
```json
{
  "success": true,
  "data": {
    "amountNpr": 50000,
    "campaignAmountNpr": 50000,
    "originalCurrency": "NPR",
    "exchangeRate": 1,
    "convertedAmountNpr": 50000,
    "convertedTotalAmountNpr": 50000
  }
}
```

✅ Save this response. Amount should be exactly 50000.

---

### STEP 2: Verify Campaign Updated (Should be 50,000)

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/campaigns/<CAMPAIGN_ID>
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Verify Response:**
```json
{
  "success": true,
  "data": {
    "currentAmount": 50000,  // ✅ Should be 50,000
    "targetAmount": 100000,
    "donationsCount": 1
  }
}
```

✅ currentAmount should be 50,000 NPR

---

### STEP 3: Create USD Donation ($100)

**Postman Setup:**
```
Method: POST
URL: http://localhost:3000/api/v1/donations
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
  - Content-Type: application/json
Body:
{
  "campaign": "<CAMPAIGN_ID>",
  "amount": 100,
  "campaignAmount": 100,
  "supportPlatform": false,
  "paymentMethod": "stripe",
  "paymentId": "test_usd_100_$(date +%s)",
  "currency": "USD"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "amount": 100,
    "amountNpr": 13050,          // ✅ Should be ~13,050 (NOT 100)
    "campaignAmountNpr": 13050,  // ✅ Should be ~13,050
    "originalCurrency": "USD",
    "exchangeRate": 130.5,       // 1 USD = 130.5 NPR
    "convertedAmountNpr": 13050
  }
}
```

✅ amountNpr should be approximately 13,000-13,100

---

### STEP 4: Verify Campaign Updated (Should be ~63,050)

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/campaigns/<CAMPAIGN_ID>
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "currentAmount": 63050,  // ✅ Should be 50,000 + 13,050
    "targetAmount": 100000,
    "donationsCount": 2
  }
}
```

✅ currentAmount should be approximately 63,050
❌ NOT 50,100 (which would be the raw sum without conversion)

---

### STEP 5: Create INR Donation (₹1000)

**Postman Setup:**
```
Method: POST
URL: http://localhost:3000/api/v1/donations
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
  - Content-Type: application/json
Body:
{
  "campaign": "<CAMPAIGN_ID>",
  "amount": 1000,
  "campaignAmount": 1000,
  "supportPlatform": false,
  "paymentMethod": "stripe",
  "paymentId": "test_inr_1000_$(date +%s)",
  "currency": "INR"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "amount": 1000,
    "amountNpr": 155,           // ✅ Should be ~155 (NOT 1000)
    "campaignAmountNpr": 155,   // ✅ Should be ~155
    "originalCurrency": "INR",
    "exchangeRate": 0.155,      // 1 INR = 0.155 NPR
    "convertedAmountNpr": 155
  }
}
```

✅ amountNpr should be approximately 150-160

---

### STEP 6: Verify Campaign Updated (Should be ~63,205)

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/campaigns/<CAMPAIGN_ID>
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "currentAmount": 63205,  // ✅ Should be 50,000 + 13,050 + 155
    "targetAmount": 100000,
    "donationsCount": 3
  }
}
```

✅ currentAmount should be approximately 63,205
❌ NOT 51,100 (which would be raw sum without conversion)

---

### STEP 7: Create EUR Donation (€50)

**Postman Setup:**
```
Method: POST
URL: http://localhost:3000/api/v1/donations
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
  - Content-Type: application/json
Body:
{
  "campaign": "<CAMPAIGN_ID>",
  "amount": 50,
  "campaignAmount": 50,
  "supportPlatform": false,
  "paymentMethod": "stripe",
  "paymentId": "test_eur_50_$(date +%s)",
  "currency": "EUR"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "amount": 50,
    "amountNpr": 5200,         // ✅ Should be ~5,200 (NOT 50)
    "campaignAmountNpr": 5200, // ✅ Should be ~5,200
    "originalCurrency": "EUR",
    "exchangeRate": 104,       // 1 EUR = 104 NPR
    "convertedAmountNpr": 5200
  }
}
```

✅ amountNpr should be approximately 5,100-5,300

---

### STEP 8: Verify Final Campaign Total (Should be ~68,405)

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/campaigns/<CAMPAIGN_ID>
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "currentAmount": 68405,  // ✅ Should be 50,000 + 13,050 + 155 + 5,200
    "targetAmount": 100000,
    "progress": "68.4%",
    "donationsCount": 4
  }
}
```

✅ currentAmount should be approximately 68,405
✅ Progress should be ~68%
❌ NOT 51,150 (which would be raw sum: 50000 + 100 + 1000 + 50)

---

### STEP 9: Verify Organization Statement (NPR Amounts)

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/admin/fund-transfers/org/<ORGANIZATION_ID>/summary
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "organization": "Your Organization Name",
    "fundraising": {
      "totalDonations": 68405  // ✅ Should be ~68,405 (in NPR)
    },
    "outstandingAmount": 31595,  // 100,000 - 68,405
    "fundTransfers": { ... }
  }
}
```

✅ totalDonations should be approximately 68,405
❌ NOT 51,150 (which would be without conversion)

---

### STEP 10: Verify Donation List Shows NPR

**Postman Setup:**
```
Method: GET
URL: http://localhost:3000/api/v1/donations?limit=10
Headers: 
  - Authorization: Bearer <YOUR_TOKEN>
```

**Expected Response (excerpt):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "amount": 100,
      "amountNpr": 13050,
      "campaignAmountNpr": 13050,
      "originalCurrency": "USD",
      "exchangeRate": 130.5,
      "convertedAmountNpr": 13050
    },
    {
      "_id": "...",
      "amount": 1000,
      "amountNpr": 155,
      "campaignAmountNpr": 155,
      "originalCurrency": "INR",
      "exchangeRate": 0.155,
      "convertedAmountNpr": 155
    }
    // ... more donations
  ]
}
```

✅ All donations should show `amountNpr` and `convertedAmountNpr`
✅ Values should match their NPR equivalents

---

## ✅ Final Verification Checklist

After completing all tests, verify:

- [ ] USD $100 donation shows ~13,050 NPR
- [ ] INR ₹1000 donation shows ~155 NPR
- [ ] EUR €50 donation shows ~5,200 NPR
- [ ] Campaign currentAmount is ~68,405 (not 51,150)
- [ ] Organization statement shows ~68,405 NPR total
- [ ] Donation list shows NPR amounts for each
- [ ] All original currency data preserved in database

## 🔧 Troubleshooting

### Problem: amountNpr still shows raw amount (e.g., 100 instead of 13050)
**Solution**: 
1. Check that `currency` parameter is being sent
2. Verify `convertedAmountNpr` field is in response
3. Check backend logs for exchange rate fetch errors

### Problem: Campaign total is 51,150 instead of 68,405
**Solution**:
1. Restart backend to apply fixes
2. Check that fundTransfer controller is using `convertedAmountNpr`
3. Verify database donations have `convertedAmountNpr` field populated

### Problem: "NPR exchange rate not available"
**Solution**:
1. Check if exchangerate-api.com is accessible
2. Try a different currency
3. Check network connectivity from backend

### Problem: Exchange rates show as 1.0 for non-NPR currencies
**Solution**:
1. Backend may not have currency conversion code deployed
2. Restart the backend service
3. Check backend console for API errors

## 💡 Quick Summary

| Scenario | Before Fix ❌ | After Fix ✅ |
|----------|-------------|----------|
| Donate $100 USD | Shows as 100 | Shows as ~13,050 NPR |
| Campaign total | 50,100 | 63,050 NPR |
| Org statement | 100 USD showing | 13,050 NPR showing |
| Invoice amount | 100 | 13,050 NPR |

---

**🎉 All tests should pass! The currency conversion is now working correctly.** 🎉
