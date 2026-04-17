// DATABASE SCHEMA REFERENCE
// Volunteer Credits System

// ============================================================================
// 1. USER COLLECTION - UPDATED
// ============================================================================

// Added Field:
{
  totalPoints: {
    type: Number,
    default: 0,
    min: 0,
  }
}

// Complete User Schema with new field:
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  password: String (hashed),
  phoneNumber: String,
  role: String (enum: 'user', 'organization', 'admin'),
  organization: ObjectId (ref: Organization),
  gender: String (enum: 'male', 'female', 'other', null),
  phone: String,
  interest: [String],
  status: String (enum: 'student', 'employed', 'not working', null),
  description: String,
  bio: String,
  skills: [String],
  certifications: [ObjectId] (ref: VolunteerCertification),
  totalVolunteerHours: Number,  // EXISTING
  totalPoints: Number,           // NEW - Calculated (totalVolunteerHours / 4)
  rating: Number,
  location: {
    country: String,
    city: String,
    address: String
  },
  profileImage: String,
  cv: String,
  age: Number,
  isVerified: Boolean,
  isActive: Boolean,
  emailVerificationToken: String,
  emailVerificationExpire: Date,
  otp: String,
  otpExpire: Date,
  resetPasswordToken: String,
  resetPasswordExpire: Date,
  createdAt: Date,
  updatedAt: Date
}

// ============================================================================
// 2. VOLUNTEER CREDIT HOURS COLLECTION - NEW
// ============================================================================

{
  _id: ObjectId,
  user: ObjectId (ref: User, required, indexed),
  creditHours: Number (required, min: 0),
  source: String (enum: ['volunteer_application', 'volunteer_enrollment', 'event_participation', 'manual_grant']),
  sourceId: ObjectId (required),
  sourceModel: String (enum: ['VolunteerApplication', 'VolunteerEnrollment', 'Event', 'Organization']),
  description: String,
  isApplied: Boolean (default: false, indexed),
  appliedAt: Date,
  createdAt: Date (indexed with user),
  updatedAt: Date
}

// ============================================================================
// 3. INDEXES CREATED
// ============================================================================

// Single field indexes:
db.volunteercredithours.createIndex({ user: 1 })
db.volunteercredithours.createIndex({ isApplied: 1 })

// Compound indexes:
db.volunteercredithours.createIndex({ user: 1, createdAt: -1 })
db.volunteercredithours.createIndex({ user: 1, isApplied: 1 })
db.volunteercredithours.createIndex({ source: 1, sourceId: 1 })
db.volunteercredithours.createIndex({ user: 1, source: 1, sourceId: 1 }, { unique: true })

// ============================================================================
// 4. EXAMPLE DOCUMENTS
// ============================================================================

// Example User Document
{
  _id: ObjectId("603c1f4e8f5a4c001234abcd"),
  name: "John Doe",
  email: "john@example.com",
  role: "user",
  totalVolunteerHours: 32,
  totalPoints: 8,           // NEW FIELD
  rating: 4.5,
  location: {
    country: "USA",
    city: "New York"
  },
  profileImage: "https://cloudinary.com/john.jpg",
  isActive: true,
  isVerified: true,
  createdAt: ISODate("2024-01-15T10:30:00Z"),
  updatedAt: ISODate("2024-04-17T15:45:00Z")
}

// Example VolunteerCreditHours Documents
{
  _id: ObjectId("604c1f4e8f5a4c001234abe1"),
  user: ObjectId("603c1f4e8f5a4c001234abcd"),
  creditHours: 8,
  source: "volunteer_application",
  sourceId: ObjectId("605d2e5f9f6b5d001234bcde"),
  sourceModel: "VolunteerApplication",
  description: "Volunteer work at community center",
  isApplied: true,
  appliedAt: ISODate("2024-04-10T10:30:00Z"),
  createdAt: ISODate("2024-04-10T10:30:00Z"),
  updatedAt: ISODate("2024-04-10T10:30:00Z")
}

{
  _id: ObjectId("604c1f4e8f5a4c001234abe2"),
  user: ObjectId("603c1f4e8f5a4c001234abcd"),
  creditHours: 12,
  source: "volunteer_enrollment",
  sourceId: ObjectId("605d2e5f9f6b5d001234bcdf"),
  sourceModel: "VolunteerEnrollment",
  description: "Beach cleanup event - 3 hours",
  isApplied: true,
  appliedAt: ISODate("2024-04-12T15:45:00Z"),
  createdAt: ISODate("2024-04-12T15:45:00Z"),
  updatedAt: ISODate("2024-04-12T15:45:00Z")
}

{
  _id: ObjectId("604c1f4e8f5a4c001234abe3"),
  user: ObjectId("603c1f4e8f5a4c001234abcd"),
  creditHours: 12,
  source: "volunteer_enrollment",
  sourceId: ObjectId("605d2e5f9f6b5d001234bdg0"),
  sourceModel: "VolunteerEnrollment",
  description: "Tree planting event - 4 hours",
  isApplied: true,
  appliedAt: ISODate("2024-04-15T14:20:00Z"),
  createdAt: ISODate("2024-04-15T14:20:00Z"),
  updatedAt: ISODate("2024-04-15T14:20:00Z")
}

// ============================================================================
// 5. USEFUL MONGODB QUERIES
// ============================================================================

// Get total credits for a user
db.volunteercredithours.aggregate([
  {
    $match: {
      user: ObjectId("603c1f4e8f5a4c001234abcd"),
      isApplied: true
    }
  },
  {
    $group: {
      _id: "$user",
      totalHours: { $sum: "$creditHours" },
      count: { $sum: 1 }
    }
  }
])

// Get top 10 users by points
db.users.find({ role: "user" })
  .sort({ totalPoints: -1 })
  .limit(10)

// Get credits by source
db.volunteercredithours.aggregate([
  {
    $match: { isApplied: true }
  },
  {
    $group: {
      _id: "$source",
      totalHours: { $sum: "$creditHours" },
      count: { $sum: 1 }
    }
  },
  {
    $sort: { totalHours: -1 }
  }
])

// Get user's credit breakdown
db.volunteercredithours.find({
  user: ObjectId("603c1f4e8f5a4c001234abcd"),
  isApplied: true
}).sort({ appliedAt: -1 })

// Get users with specific point range
db.users.find({
  role: "user",
  totalPoints: { $gte: 10, $lte: 50 }
}).sort({ totalPoints: -1 })

// Get credits granted in last month
db.volunteercredithours.find({
  appliedAt: {
    $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  },
  isApplied: true
}).count()

// Get duplicate credit attempts (unapplied)
db.volunteercredithours.find({
  isApplied: false
}).count()

// Update user points (bulk)
db.users.updateMany(
  { role: "user" },
  [
    {
      $lookup: {
        from: "volunteercredithours",
        localField: "_id",
        foreignField: "user",
        as: "credits"
      }
    },
    {
      $addFields: {
        totalHours: {
          $sum: {
            $filter: {
              input: "$credits",
              as: "credit",
              cond: "$$credit.isApplied"
            }
          }
        }
      }
    },
    {
      $set: {
        totalVolunteerHours: "$totalHours",
        totalPoints: { $floor: { $divide: ["$totalHours", 4] } }
      }
    },
    {
      $unset: ["credits", "totalHours"]
    }
  ]
)

// ============================================================================
// 6. DATA MIGRATION (if upgrading existing system)
// ============================================================================

// Initialize totalPoints field for all users
db.users.updateMany(
  { totalPoints: { $exists: false } },
  { $set: { totalPoints: 0 } }
)

// If you have existing credit data in VolunteerApplication
db.users.find().forEach(function(user) {
  var totalHours = 0;
  
  // Sum from VolunteerApplication
  db.volunteerapplications.find({
    user: user._id,
    creditHoursGranted: { $gt: 0 }
  }).forEach(function(app) {
    totalHours += app.creditHoursGranted;
  });
  
  // Sum from VolunteerEnrollment
  db.volunteerenrollments.find({
    user: user._id,
    creditHoursGranted: { $gt: 0 }
  }).forEach(function(enrollment) {
    totalHours += enrollment.creditHoursGranted;
  });
  
  // Update user
  db.users.updateOne(
    { _id: user._id },
    {
      $set: {
        totalVolunteerHours: totalHours,
        totalPoints: Math.floor(totalHours / 4)
      }
    }
  );
});

// ============================================================================
// 7. BACKUP & RESTORE
// ============================================================================

// Backup collections
// mongodump --db hopelink --collection users --out /backup/users.bson
// mongodump --db hopelink --collection volunteercredithours --out /backup/credits.bson

// Restore collections
// mongorestore --db hopelink --collection users /backup/users.bson
// mongorestore --db hopelink --collection volunteercredithours /backup/credits.bson

// ============================================================================
// 8. COLLECTION STATISTICS
// ============================================================================

// Get collection sizes
db.users.stats()
db.volunteercredithours.stats()

// Get index information
db.users.getIndexes()
db.volunteercredithours.getIndexes()

// Get total data size
db.getSiblingDB('hopelink').getCollection('users').dataSize()
db.getSiblingDB('hopelink').getCollection('volunteercredithours').dataSize()

// ============================================================================
// 9. PERFORMANCE TUNING
// ============================================================================

// Rebuild indexes (if they get fragmented)
db.volunteercredithours.reIndex()

// Analyze query performance
db.volunteercredithours.find({
  user: ObjectId("603c1f4e8f5a4c001234abcd"),
  isApplied: true
}).explain("executionStats")

// Enable/disable indexing for maintenance
db.volunteercredithours.dropIndex("user_1")  // Drop if needed
db.volunteercredithours.createIndex({ user: 1 })  // Recreate

// ============================================================================
// 10. MONITORING & ALERTS
// ============================================================================

// Monitor for duplicate credit attempts
db.volunteercredithours.find({
  isApplied: false
}).count()

// Monitor orphaned records (credits with non-existent users)
db.volunteercredithours.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "user",
      foreignField: "_id",
      as: "userInfo"
    }
  },
  {
    $match: {
      userInfo: { $eq: [] }
    }
  }
])

// Check for users with inconsistent point calculations
db.users.find({
  role: "user",
  $expr: {
    $ne: [
      "$totalPoints",
      { $floor: { $divide: ["$totalVolunteerHours", 4] } }
    ]
  }
})

// ============================================================================

Version: 1.0.0
Last Updated: April 17, 2024
