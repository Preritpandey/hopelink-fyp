# Volunteer Credits System - Implementation Guide

## Overview
The enhanced Volunteer Credits System manages volunteer credit hours and calculates points for users across all volunteer activities in the HopeLink platform.

**Key Features:**
- ✅ Aggregate credit hours from all sources (volunteer jobs, events, enrollments)
- ✅ Automatic points calculation (4 credit hours = 1 point)
- ✅ Unified endpoints for credit information
- ✅ Dynamic leaderboard based on points
- ✅ Credit history tracking
- ✅ Efficient and scalable architecture

---

## System Architecture

### 1. **Data Models**

#### User Model (Updated)
```javascript
// Added fields:
{
  totalVolunteerHours: Number,  // Total credit hours
  totalPoints: Number           // Calculated points (totalVolunteerHours / 4)
}
```

#### VolunteerCreditHours Model (New)
Tracks all credit hour entries with the following structure:
```javascript
{
  user: ObjectId,           // Reference to User
  creditHours: Number,      // Amount of hours granted
  source: String,           // Source of credit (volunteer_application, volunteer_enrollment, event_participation, manual_grant)
  sourceId: ObjectId,       // ID of the source document
  sourceModel: String,      // Type of source (VolunteerApplication, VolunteerEnrollment, Event, Organization)
  description: String,      // Human-readable description
  isApplied: Boolean,       // Whether credits have been applied to user
  appliedAt: Date,         // When credits were applied
  createdAt: Date,         // Creation timestamp
  updatedAt: Date          // Last update timestamp
}
```

---

## API Endpoints

### 1. **Grant Credit Hours from Volunteer Application**
```
POST /api/v1/volunteer-credits/grant/application/:applicationId
```

**Authentication:** Required (JWT Token)

**Request Body:**
```json
{
  "creditHours": 8,
  "description": "Completed volunteer work at community center"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Credit hours granted successfully",
  "creditEntry": {
    "_id": "...",
    "user": "...",
    "creditHours": 8,
    "source": "volunteer_application",
    "sourceId": "...",
    "isApplied": true,
    "appliedAt": "2024-04-17T10:30:00Z"
  }
}
```

**Use Case:** When an organization approves a volunteer application and wants to grant credit hours.

---

### 2. **Grant Credit Hours from Event Enrollment**
```
POST /api/v1/volunteer-credits/grant/enrollment/:enrollmentId
```

**Authentication:** Required (JWT Token)

**Request Body:**
```json
{
  "creditHours": 4,
  "description": "Event participation - Beach cleanup"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Credit hours granted successfully",
  "creditEntry": { ... }
}
```

**Use Case:** When event attendance is confirmed and credit hours need to be awarded.

---

### 3. **Get My Credit Hours and Points (Authenticated User)**
```
GET /api/v1/volunteer-credits/me
```

**Authentication:** Required (JWT Token)

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "totalCreditHours": 32,
    "totalPoints": 8,
    "pointsPerHour": 4,
    "creditBreakdown": [
      {
        "_id": "...",
        "creditHours": 8,
        "source": "volunteer_application",
        "description": "Community center work",
        "appliedAt": "2024-04-10T10:30:00Z"
      },
      {
        "_id": "...",
        "creditHours": 12,
        "source": "volunteer_enrollment",
        "description": "Event participation",
        "appliedAt": "2024-04-12T15:45:00Z"
      }
    ]
  }
}
```

**Use Case:** User profile page to display volunteer statistics.

---

### 4. **Get User's Credit Hours and Points**
```
GET /api/v1/volunteer-credits/user/:userId
```

**Authentication:** Not required (Public)

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "totalCreditHours": 32,
    "totalPoints": 8,
    "pointsPerHour": 4,
    "creditBreakdown": [ ... ]
  }
}
```

**Use Case:** View another user's volunteer profile.

---

### 5. **Get Global Leaderboard**
```
GET /api/v1/volunteer-credits/leaderboard?limit=20&skip=0
```

**Authentication:** Not required (Public)

**Query Parameters:**
- `limit` (optional): Number of records per page (default: 20, max: 100)
- `skip` (optional): Number of records to skip for pagination (default: 0)

**Response:**
```json
{
  "success": true,
  "data": {
    "leaderboard": [
      {
        "rank": 1,
        "_id": "user_001",
        "name": "Alice Smith",
        "email": "alice@example.com",
        "profileImage": "https://...",
        "location": {
          "country": "USA",
          "city": "New York"
        },
        "totalCreditHours": 120,
        "totalPoints": 30,
        "rating": 4.8
      },
      {
        "rank": 2,
        "_id": "user_002",
        "name": "Bob Johnson",
        "email": "bob@example.com",
        "profileImage": "https://...",
        "location": {
          "country": "USA",
          "city": "Los Angeles"
        },
        "totalCreditHours": 96,
        "totalPoints": 24,
        "rating": 4.5
      },
      // ... more users
    ],
    "pagination": {
      "currentPage": 1,
      "pageSize": 20,
      "totalUsers": 250,
      "totalPages": 13,
      "hasMore": true
    }
  }
}
```

**Use Case:** Display global volunteer leaderboard on app dashboard.

---

### 6. **Get Category-based Leaderboard**
```
GET /api/v1/volunteer-credits/leaderboard/category/:category?limit=20&skip=0
```

**Authentication:** Not required (Public)

**Path Parameters:**
- `category`: Country/region name (e.g., "USA", "Canada", "UK")

**Response:**
```json
{
  "success": true,
  "data": {
    "category": "USA",
    "leaderboard": [ ... ],
    "pagination": { ... }
  }
}
```

**Use Case:** Display leaderboards by country or region.

---

### 7. **Get My Credit History**
```
GET /api/v1/volunteer-credits/my-history?limit=50&skip=0
```

**Authentication:** Required (JWT Token)

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "userName": "John Doe",
    "history": [
      {
        "_id": "...",
        "creditHours": 8,
        "source": "volunteer_application",
        "sourceId": "app_456",
        "sourceModel": "VolunteerApplication",
        "description": "Community center work",
        "isApplied": true,
        "appliedAt": "2024-04-10T10:30:00Z",
        "createdAt": "2024-04-10T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "pageSize": 50,
      "total": 12,
      "totalPages": 1
    }
  }
}
```

**Use Case:** User's personal activity history page.

---

### 8. **Get User's Credit History**
```
GET /api/v1/volunteer-credits/history/:userId?limit=50&skip=0
```

**Authentication:** Not required (Public)

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "userName": "John Doe",
    "history": [ ... ],
    "pagination": { ... }
  }
}
```

**Use Case:** View another user's volunteer activity history.

---

## Points Calculation

The system uses a simple conversion formula:

```
totalPoints = floor(totalCreditHours / 4)
```

### Examples:
- 4 credit hours → 1 point
- 8 credit hours → 2 points
- 12 credit hours → 3 points
- 15 credit hours → 3 points (3.75 rounds down)
- 32 credit hours → 8 points

---

## Integration with Existing Features

### 1. **Volunteer Application Approval**
When an organization approves a volunteer application and wants to grant credits:

```javascript
// Example in volunteerApplication.controller.js
const { updateUserPoints } = require('../controllers/volunteerCredits.controller.js');

export const approveApplication = async (req, res) => {
  // ... existing logic ...
  
  // Grant credits (optional - based on your workflow)
  if (req.body.creditHours) {
    const creditEntry = await VolunteerCreditHours.create({
      user: application.user,
      creditHours: req.body.creditHours,
      source: 'volunteer_application',
      sourceId: application._id,
      sourceModel: 'VolunteerApplication',
      isApplied: true,
      appliedAt: new Date(),
    });

    // Update user's total points
    await updateUserPoints(application.user);
  }
};
```

### 2. **Event Enrollment Confirmation**
When event attendance is marked:

```javascript
// Example in event.controller.js
const { updateUserPoints } = require('../controllers/volunteerCredits.controller.js');

export const markAttendance = async (req, res) => {
  // ... existing logic ...
  
  if (enrollment.status === 'attended') {
    // Award credits equal to event's creditHours
    const creditEntry = await VolunteerCreditHours.create({
      user: enrollment.user,
      creditHours: event.creditHours,
      source: 'volunteer_enrollment',
      sourceId: enrollment._id,
      sourceModel: 'VolunteerEnrollment',
      isApplied: true,
      appliedAt: new Date(),
    });

    // Update user's total points
    await updateUserPoints(enrollment.user);
  }
};
```

---

## Scalability Considerations

### 1. **Indexing**
The VolunteerCreditHours model includes indexes on:
- `user` (for user queries)
- `user + createdAt` (for historical data)
- `user + source + sourceId` (for uniqueness)
- `isApplied` (for filtering)

### 2. **Efficient Aggregation**
- Credit aggregation is done with MongoDB aggregation pipeline
- Leaderboard uses efficient sorting and pagination
- Only applied credits are counted in totals

### 3. **Caching Strategy** (Recommended)
For high-traffic scenarios, consider caching:
- User's total points (cache for 1 hour)
- Leaderboard (cache for 5-10 minutes)
- Popular user profiles (cache for 30 minutes)

---

## Testing the API

### Using cURL:

**Grant Credits from Application:**
```bash
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/application/APP_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "creditHours": 8,
    "description": "Volunteer work at community center"
  }'
```

**Get My Credits:**
```bash
curl -X GET http://localhost:5000/api/v1/volunteer-credits/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Get Leaderboard:**
```bash
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=10&skip=0"
```

---

## Database Queries

### Get User's Total Credits (Manual Query)
```javascript
const user = await VolunteerCreditHours.find({ user: userId, isApplied: true });
const totalHours = user.reduce((sum, entry) => sum + entry.creditHours, 0);
const totalPoints = Math.floor(totalHours / 4);
```

### Bulk Update User Points
```javascript
const users = await User.find({ role: 'user' });

for (const user of users) {
  const totalHours = await aggregateUserCreditHours(user._id);
  const totalPoints = calculatePointsFromHours(totalHours);
  
  await User.updateOne(
    { _id: user._id },
    { totalVolunteerHours: totalHours, totalPoints: totalPoints }
  );
}
```

---

## Error Handling

### Common Error Responses:

**Invalid Credit Hours:**
```json
{
  "success": false,
  "message": "Valid credit hours are required"
}
```

**Duplicate Credits:**
```json
{
  "success": false,
  "message": "Credits have already been granted for this application"
}
```

**User Not Found:**
```json
{
  "success": false,
  "message": "User not found"
}
```

---

## Performance Metrics

Expected response times:
- Get user credits: **< 50ms**
- Get leaderboard (20 users): **< 100ms**
- Grant credits: **< 200ms**
- Calculate points: **< 10ms**

---

## Future Enhancements

1. **Badge System**: Award badges for milestone points (10, 50, 100, etc.)
2. **Reward System**: Convert points to vouchers or donations
3. **Streak Tracking**: Track consecutive volunteer days
4. **Notifications**: Notify users when they reach point milestones
5. **Analytics Dashboard**: Show trends and statistics
6. **Bulk Import**: Allow organizations to import credit hours for past activities

---

## Support & Troubleshooting

### Issue: User points not updating
**Solution:** Call the `updateUserPoints(userId)` function manually or check if credits are marked as `isApplied: true`.

### Issue: Leaderboard showing old data
**Solution:** Clear any caching and ensure `totalPoints` field in User model is calculated correctly.

### Issue: Duplicate credit entries
**Solution:** The unique compound index on `{user, source, sourceId}` prevents duplicates automatically.

---

**Version:** 1.0.0  
**Last Updated:** April 17, 2024
