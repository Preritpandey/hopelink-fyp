# Volunteer Credits API - Testing & Examples

## Table of Contents
1. [cURL Examples](#curl-examples)
2. [Postman Collection](#postman-collection)
3. [JavaScript Examples](#javascript-examples)
4. [Testing Scenarios](#testing-scenarios)

---

## cURL Examples

### 1. Grant Credits from Volunteer Application

```bash
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/application/APPLICATION_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "creditHours": 8,
    "description": "Completed volunteer work at community center"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Credit hours granted successfully",
  "creditEntry": {
    "_id": "604c1f4e8f5a4c001234abcd",
    "user": "603c1f4e8f5a4c001234abcd",
    "creditHours": 8,
    "source": "volunteer_application",
    "sourceId": "APPLICATION_ID",
    "sourceModel": "VolunteerApplication",
    "description": "Completed volunteer work at community center",
    "isApplied": true,
    "appliedAt": "2024-04-17T10:30:00.000Z",
    "createdAt": "2024-04-17T10:30:00.000Z"
  }
}
```

---

### 2. Grant Credits from Event Enrollment

```bash
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/enrollment/ENROLLMENT_ID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "creditHours": 4,
    "description": "Event participation - Beach cleanup"
  }'
```

---

### 3. Get My Credits and Points (Authenticated)

```bash
curl -X GET http://localhost:5000/api/v1/volunteer-credits/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "userId": "603c1f4e8f5a4c001234abcd",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "totalCreditHours": 32,
    "totalPoints": 8,
    "pointsPerHour": 4,
    "creditBreakdown": [
      {
        "_id": "604c1f4e8f5a4c001234abe1",
        "creditHours": 8,
        "source": "volunteer_application",
        "sourceModel": "VolunteerApplication",
        "description": "Volunteer work at community center",
        "isApplied": true,
        "appliedAt": "2024-04-10T10:30:00.000Z"
      },
      {
        "_id": "604c1f4e8f5a4c001234abe2",
        "creditHours": 12,
        "source": "volunteer_enrollment",
        "sourceModel": "VolunteerEnrollment",
        "description": "Event participation",
        "isApplied": true,
        "appliedAt": "2024-04-12T15:45:00.000Z"
      },
      {
        "_id": "604c1f4e8f5a4c001234abe3",
        "creditHours": 12,
        "source": "volunteer_enrollment",
        "sourceModel": "VolunteerEnrollment",
        "description": "Event participation",
        "isApplied": true,
        "appliedAt": "2024-04-15T14:20:00.000Z"
      }
    ]
  }
}
```

---

### 4. Get Specific User's Credits (Public)

```bash
curl -X GET http://localhost:5000/api/v1/volunteer-credits/user/USER_ID \
  -H "Content-Type: application/json"
```

---

### 5. Get Global Leaderboard (Top 20 Users)

```bash
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=20&skip=0" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "leaderboard": [
      {
        "rank": 1,
        "_id": "603c1f4e8f5a4c001234aa01",
        "name": "Alice Smith",
        "email": "alice@example.com",
        "profileImage": "https://cloudinary.com/image.jpg",
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
        "_id": "603c1f4e8f5a4c001234aa02",
        "name": "Bob Johnson",
        "email": "bob@example.com",
        "profileImage": "https://cloudinary.com/image2.jpg",
        "location": {
          "country": "USA",
          "city": "Los Angeles"
        },
        "totalCreditHours": 96,
        "totalPoints": 24,
        "rating": 4.5
      },
      {
        "rank": 3,
        "_id": "603c1f4e8f5a4c001234aa03",
        "name": "Carol White",
        "email": "carol@example.com",
        "profileImage": "https://cloudinary.com/image3.jpg",
        "location": {
          "country": "USA",
          "city": "Chicago"
        },
        "totalCreditHours": 88,
        "totalPoints": 22,
        "rating": 4.6
      }
    ],
    "pagination": {
      "currentPage": 1,
      "pageSize": 20,
      "totalUsers": 150,
      "totalPages": 8,
      "hasMore": true
    }
  }
}
```

---

### 6. Get Leaderboard for Specific Region

```bash
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard/category/USA?limit=10&skip=0" \
  -H "Content-Type: application/json"
```

---

### 7. Get My Credit History (Paginated)

```bash
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/my-history?limit=50&skip=0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "userId": "603c1f4e8f5a4c001234abcd",
    "userName": "John Doe",
    "history": [
      {
        "_id": "604c1f4e8f5a4c001234abc1",
        "creditHours": 8,
        "source": "volunteer_application",
        "sourceId": "605d2e5f9f6b5d001234bcde",
        "sourceModel": "VolunteerApplication",
        "description": "Completed volunteer work at community center",
        "isApplied": true,
        "appliedAt": "2024-04-10T10:30:00.000Z",
        "createdAt": "2024-04-10T10:30:00.000Z"
      },
      {
        "_id": "604c1f4e8f5a4c001234abc2",
        "creditHours": 12,
        "source": "volunteer_enrollment",
        "sourceId": "605d2e5f9f6b5d001234bcdf",
        "sourceModel": "VolunteerEnrollment",
        "description": "Attended Beach Cleanup Event",
        "isApplied": true,
        "appliedAt": "2024-04-12T15:45:00.000Z",
        "createdAt": "2024-04-12T15:45:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "pageSize": 50,
      "total": 2,
      "totalPages": 1
    }
  }
}
```

---

### 8. Get Another User's Credit History (Public)

```bash
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/history/USER_ID?limit=50&skip=0" \
  -H "Content-Type: application/json"
```

---

## Postman Collection

### Import JSON into Postman

```json
{
  "info": {
    "name": "HopeLink Volunteer Credits API",
    "description": "Complete API collection for volunteer credits management",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Grant Credits from Application",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{jwt_token}}",
            "type": "text"
          },
          {
            "key": "Content-Type",
            "value": "application/json",
            "type": "text"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"creditHours\": 8,\n  \"description\": \"Completed volunteer work at community center\"\n}"
        },
        "url": {
          "raw": "{{base_url}}/api/v1/volunteer-credits/grant/application/{{application_id}}",
          "protocol": "http",
          "host": ["{{base_url}}"],
          "path": [
            "api",
            "v1",
            "volunteer-credits",
            "grant",
            "application",
            "{{application_id}}"
          ]
        }
      }
    },
    {
      "name": "Get My Credits",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{jwt_token}}",
            "type": "text"
          }
        ],
        "url": {
          "raw": "{{base_url}}/api/v1/volunteer-credits/me",
          "protocol": "http",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "volunteer-credits", "me"]
        }
      }
    },
    {
      "name": "Get Global Leaderboard",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/v1/volunteer-credits/leaderboard?limit=20&skip=0",
          "protocol": "http",
          "host": ["{{base_url}}"],
          "path": ["api", "v1", "volunteer-credits", "leaderboard"],
          "query": [
            {
              "key": "limit",
              "value": "20"
            },
            {
              "key": "skip",
              "value": "0"
            }
          ]
        }
      }
    },
    {
      "name": "Get My Credit History",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{jwt_token}}",
            "type": "text"
          }
        ],
        "url": {
          "raw": "{{base_url}}/api/v1/volunteer-credits/my-history?limit=50&skip=0",
          "protocol": "http",
          "host": ["{{base_url}}"],
          "path": [
            "api",
            "v1",
            "volunteer-credits",
            "my-history"
          ],
          "query": [
            {
              "key": "limit",
              "value": "50"
            },
            {
              "key": "skip",
              "value": "0"
            }
          ]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:5000"
    },
    {
      "key": "jwt_token",
      "value": "your_jwt_token_here"
    },
    {
      "key": "application_id",
      "value": "application_id_here"
    },
    {
      "key": "user_id",
      "value": "user_id_here"
    }
  ]
}
```

---

## JavaScript Examples

### 1. Fetch User's Credits and Points

```javascript
// Get my credits using fetch API
const getMyCredits = async (jwtToken) => {
  try {
    const response = await fetch(
      'http://localhost:5000/api/v1/volunteer-credits/me',
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${jwtToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await response.json();

    if (data.success) {
      console.log('Total Credit Hours:', data.data.totalCreditHours);
      console.log('Total Points:', data.data.totalPoints);
      console.log('Credit Breakdown:', data.data.creditBreakdown);
    } else {
      console.error('Error:', data.message);
    }

    return data;
  } catch (error) {
    console.error('Fetch error:', error);
  }
};

// Usage
getMyCredits('your_jwt_token');
```

---

### 2. Grant Credits from Application

```javascript
const grantCredits = async (applicationId, creditHours, jwtToken) => {
  try {
    const response = await fetch(
      `http://localhost:5000/api/v1/volunteer-credits/grant/application/${applicationId}`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${jwtToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          creditHours,
          description: 'Volunteer work completed'
        })
      }
    );

    const data = await response.json();

    if (data.success) {
      console.log('Credits granted successfully');
      console.log('Credit Hours:', data.creditEntry.creditHours);
    } else {
      console.error('Error:', data.message);
    }

    return data;
  } catch (error) {
    console.error('Fetch error:', error);
  }
};

// Usage
grantCredits('APP_ID', 8, 'jwt_token');
```

---

### 3. Get Leaderboard

```javascript
const getLeaderboard = async (limit = 20, skip = 0) => {
  try {
    const response = await fetch(
      `http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=${limit}&skip=${skip}`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await response.json();

    if (data.success) {
      console.log('Leaderboard:');
      data.data.leaderboard.forEach((user) => {
        console.log(`#${user.rank} - ${user.name}: ${user.totalPoints} points`);
      });

      console.log('\nPagination:', data.data.pagination);
    }

    return data;
  } catch (error) {
    console.error('Fetch error:', error);
  }
};

// Usage
getLeaderboard(10, 0);
```

---

### 4. Using Axios

```javascript
import axios from 'axios';

const creditApi = axios.create({
  baseURL: 'http://localhost:5000/api/v1/volunteer-credits'
});

// Get my credits
const getMyCreditsAxios = async (jwtToken) => {
  try {
    const response = await creditApi.get('/me', {
      headers: {
        'Authorization': `Bearer ${jwtToken}`
      }
    });

    return response.data.data;
  } catch (error) {
    console.error('Error:', error.response?.data?.message);
  }
};

// Grant credits
const grantCreditsAxios = async (applicationId, creditHours, jwtToken) => {
  try {
    const response = await creditApi.post(
      `/grant/application/${applicationId}`,
      {
        creditHours,
        description: 'Volunteer work'
      },
      {
        headers: {
          'Authorization': `Bearer ${jwtToken}`
        }
      }
    );

    return response.data;
  } catch (error) {
    console.error('Error:', error.response?.data?.message);
  }
};

// Get leaderboard
const getLeaderboardAxios = async (limit = 20, skip = 0) => {
  try {
    const response = await creditApi.get('/leaderboard', {
      params: { limit, skip }
    });

    return response.data.data;
  } catch (error) {
    console.error('Error:', error.response?.data?.message);
  }
};
```

---

## Testing Scenarios

### Scenario 1: Complete Volunteer Flow

```bash
# 1. Create a volunteer application
# (Use existing endpoint)

# 2. Approve application and grant credits
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/application/APP_ID \
  -H "Authorization: Bearer TOKEN" \
  -d '{"creditHours": 8}'

# 3. Check updated user credits
curl -X GET http://localhost:5000/api/v1/volunteer-credits/user/USER_ID

# 4. Check leaderboard position
curl -X GET http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=50

# 5. View credit history
curl -X GET "http://localhost:5000/api/v1/volunteer-credits/history/USER_ID?limit=50"
```

---

### Scenario 2: Multiple Credits from Same User

```bash
# First application: 8 hours
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/application/APP_1 \
  -H "Authorization: Bearer TOKEN" \
  -d '{"creditHours": 8}'

# First event enrollment: 4 hours
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/enrollment/ENROLL_1 \
  -H "Authorization: Bearer TOKEN" \
  -d '{"creditHours": 4}'

# Second event enrollment: 12 hours
curl -X POST http://localhost:5000/api/v1/volunteer-credits/grant/enrollment/ENROLL_2 \
  -H "Authorization: Bearer TOKEN" \
  -d '{"creditHours": 12}'

# Check totals: Should be 24 hours = 6 points
curl -X GET http://localhost:5000/api/v1/volunteer-credits/me \
  -H "Authorization: Bearer TOKEN"
```

---

### Scenario 3: Leaderboard Competition

```bash
# Create 5 users with different credit amounts
# User A: 32 hours (8 points)
# User B: 20 hours (5 points)
# User C: 40 hours (10 points)
# User D: 28 hours (7 points)
# User E: 12 hours (3 points)

# Expected leaderboard order: C > A > D > B > E

curl -X GET "http://localhost:5000/api/v1/volunteer-credits/leaderboard?limit=5"
```

---

**Version:** 1.0.0  
**Last Updated:** April 17, 2024
