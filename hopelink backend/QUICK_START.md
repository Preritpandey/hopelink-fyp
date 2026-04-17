# Quick Start Guide - Volunteer Credits System

## 5-Minute Setup

### Step 1: Verify Files Created ✅

Check these files exist in your project:

```
hopelink backend/
├── src/
│   ├── models/
│   │   └── volunteerCreditHours.model.js        [NEW]
│   ├── controllers/
│   │   └── volunteerCredits.controller.js       [NEW]
│   ├── routes/
│   │   └── volunteerCredits.routes.js           [NEW]
│   │   └── index.js                             [MODIFIED]
├── IMPLEMENTATION_SUMMARY.md                    [NEW]
├── VOLUNTEER_CREDITS_DOCUMENTATION.md           [NEW]
├── INTEGRATION_GUIDE.js                         [NEW]
├── API_TESTING_EXAMPLES.md                      [NEW]
└── DATABASE_SCHEMA_REFERENCE.md                 [NEW]
```

### Step 2: Start Your Server

```bash
cd hopelink\ backend/backend
npm install  # If you haven't already
npm start
# Or: npm run dev
```

### Step 3: Test an Endpoint

```bash
# Get global leaderboard (no auth needed)
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=5"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "leaderboard": [],  // Empty if no credits granted yet
    "pagination": {
      "currentPage": 1,
      "pageSize": 5,
      "totalUsers": 0,
      "totalPages": 0,
      "hasMore": false
    }
  }
}
```

### Step 4: Create Test Data

Get a valid user ID and application ID, then grant credits:

```bash
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/application/APP_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "creditHours": 8
  }'
```

### Step 5: View Results

```bash
# Get the leaderboard again
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard"
# User should now be ranked
```

---

## Key Endpoints Reference

| Task | Endpoint | Method | Auth |
|------|----------|--------|------|
| Award credits | `/volunteer-credits/grant/application/:id` | POST | ✅ |
| My stats | `/volunteer-credits/me` | GET | ✅ |
| User stats | `/volunteer-credits/user/:id` | GET | ❌ |
| Top users | `/volunteer-credits/leaderboard` | GET | ❌ |
| My history | `/volunteer-credits/my-history` | GET | ✅ |
| Regional leaderboard | `/volunteer-credits/leaderboard/category/:cat` | GET | ❌ |

---

## Integration Checklist

To integrate with your existing code:

- [ ] **Volunteer Application Approval**
  - When approving an application, call `/grant/application/{appId}`
  - User's points will update automatically

- [ ] **Event Enrollment**
  - When marking attendance, call `/grant/enrollment/{enrollmentId}`
  - Event's creditHours field used if available

- [ ] **User Profile**
  - Call `/volunteer-credits/user/:id` to get stats
  - Display totalPoints and totalCreditHours

- [ ] **Leaderboard Display**
  - Call `/volunteer-credits/leaderboard?limit=20`
  - Shows top 20 volunteers with rankings

- [ ] **User Dashboard**
  - Call `/volunteer-credits/me` (requires auth token)
  - Shows user's detailed credit breakdown

---

## Common Use Cases

### Use Case 1: Approve Volunteer Application

```bash
# When org approves a volunteer application
POST /api/v1/volunteer-credits/grant/application/APP_123
{
  "creditHours": 8,
  "description": "Approved volunteer work"
}
```

User's totalPoints automatically updated from 0 → 2 (8÷4)

### Use Case 2: Show User's Volunteer Profile

```bash
# Frontend wants to show user's stats
GET /api/v1/volunteer-credits/user/USER_123
```

Returns:
- Total hours: 32
- Total points: 8
- Credit breakdown: [array of all credits]

### Use Case 3: Display Top Volunteers

```bash
# App homepage showing top 10 volunteers
GET /api/v1/volunteer-credits/leaderboard?limit=10
```

Returns leaderboard with ranking, name, points, hours

### Use Case 4: Regional Competition

```bash
# Show leaderboard for USA only
GET /api/v1/volunteer-credits/leaderboard/category/USA?limit=20
```

Returns regional rankings

### Use Case 5: Volunteer Activity Feed

```bash
# Show user's credit history
GET /api/v1/volunteer-credits/my-history?limit=50
```

Returns transactions with timestamps and descriptions

---

## Important Notes ⚠️

1. **4 Credit Hours = 1 Point** (hardcoded, adjust in controller if needed)

2. **Duplicate Prevention**: Same activity can't award credits twice
   - Unique index on `{user, source, sourceId}`

3. **Manual Updates Only**: Credits don't auto-grant
   - Admin/org must call grant endpoint
   - Or integrate in your approval workflow

4. **Real-time Updates**: Changes visible immediately
   - No caching - always fresh data

5. **Pagination**: All list endpoints support pagination
   - Default limit: 20 records
   - Max limit: 100 records

---

## Troubleshooting

### Problem: "Credits have already been granted for this application"

**Solution**: User already received credits for this activity. Check credit history.

### Problem: User not showing on leaderboard

**Solution**: Either they have 0 points, or records aren't marked `isApplied: true`.

### Problem: Points don't match calculation

**Solution**: Call `/volunteer-credits/me` to get real-time recalculation.

### Problem: Leaderboard shows old ranking

**Solution**: Rankings are calculated on-the-fly, but make sure database is fresh.

---

## Environment Variables

No new env variables needed. Uses existing:
- `JWT_SECRET` - For authentication
- `MONGODB_URI` - Database connection

---

## Database Requirements

- MongoDB with collections:
  - `users` (already exists)
  - `volunteercredithours` (auto-created on first write)

Indexes auto-created when model loads.

---

## Testing Tools

### Option 1: cURL (Command Line)
```bash
curl -X GET http://localhost:5000/api/v1/volunteer-credits/leaderboard
```

### Option 2: Postman
- Import `API_TESTING_EXAMPLES.md` collection
- Set JWT token in environment
- Run requests

### Option 3: JavaScript
```javascript
const response = await fetch('http://localhost:5000/api/v1/volunteer-credits/me', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const data = await response.json();
console.log(data.data.totalPoints);
```

---

## File Locations

**Main Code:**
- Model: `src/models/volunteerCreditHours.model.js`
- Controller: `src/controllers/volunteerCredits.controller.js`
- Routes: `src/routes/volunteerCredits.routes.js`

**Documentation:**
- API Reference: `VOLUNTEER_CREDITS_DOCUMENTATION.md`
- Code Integration: `INTEGRATION_GUIDE.js`
- Test Examples: `API_TESTING_EXAMPLES.md`
- Database Info: `DATABASE_SCHEMA_REFERENCE.md`
- This File: `QUICK_START.md`

---

## Next Steps

1. **Test** the endpoints with provided examples
2. **Integrate** with your volunteer approval workflow
3. **Display** leaderboards on your frontend
4. **Monitor** credit awards to ensure accuracy
5. **Optimize** with caching if high traffic

---

## Support Resources

- **Complete Docs**: See `VOLUNTEER_CREDITS_DOCUMENTATION.md`
- **Code Examples**: See `INTEGRATION_GUIDE.js`
- **API Tests**: See `API_TESTING_EXAMPLES.md`
- **DB Queries**: See `DATABASE_SCHEMA_REFERENCE.md`

---

## Success Criteria ✅

You'll know it's working when:

1. ✅ Can call `/volunteer-credits/leaderboard` without error
2. ✅ Can grant credits to a user
3. ✅ User's totalPoints updates automatically
4. ✅ Leaderboard shows user ranked correctly
5. ✅ Credit history shows all transactions

---

**Happy Volunteering! 🎉**

For detailed documentation, see `IMPLEMENTATION_SUMMARY.md`
