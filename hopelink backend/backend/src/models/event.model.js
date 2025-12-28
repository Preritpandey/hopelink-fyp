import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Please provide a title for the event'],
      trim: true,
      maxlength: [100, 'Title cannot be more than 100 characters'],
    },
    description: {
      type: String,
      required: [true, 'Please provide a description'],
    },
    category: {
      type: String,
      required: [true, 'Please provide a category'],
      enum: [
        'cleaning', 
        'education', 
        'awareness', 
        'health', 
        'environment',
        'animals',
        'community',
        'other'
      ],
    },
    eventType: {
      type: String,
      enum: ['one-day', 'multi-day', 'recurring'],
      default: 'one-day',
    },
    location: {
      address: {
        type: String,
        required: [true, 'Please provide an address'],
      },
      city: {
        type: String,
        required: [true, 'Please provide a city'],
      },
      state: {
        type: String,
        required: [true, 'Please provide a state'],
      },
      coordinates: {
        // GeoJSON Point
        type: {
          type: String,
          enum: ['Point'],
        },
        coordinates: {
          type: [Number],
          index: '2dsphere',
        },
      },
    },
    startDate: {
      type: Date,
      required: [true, 'Please provide a start date'],
    },
    endDate: {
      type: Date,
      required: [
        function() { return this.eventType === 'multi-day' || this.eventType === 'recurring'; },
        'End date is required for multi-day or recurring events'
      ],
    },
    images: [
      {
        url: String,
        publicId: String,
        isPrimary: {
          type: Boolean,
          default: false,
        },
      },
    ],
    status: {
      type: String,
      enum: ['draft', 'published', 'ongoing', 'completed', 'cancelled'],
      default: 'draft',
    },
    maxVolunteers: {
      type: Number,
      min: [1, 'Maximum volunteers must be at least 1'],
    },
    requiredSkills: [
      {
        type: String,
        trim: true,
      },
    ],
    eligibility: {
      type: String,
      enum: ['Anyone', '18+', 'Students', 'Adults', 'Seniors'],
      default: 'Anyone',
    },
    organizerType: {
      type: String,
      enum: ['User', 'Organization'],
      required: true,
    },
    organizer: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      refPath: 'organizerType',
    },
    volunteers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    registrationDeadline: {
      type: Date,
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    tags: [String],
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Indexes
eventSchema.index({ title: 'text', description: 'text' });
eventSchema.index({ 'location.coordinates': '2dsphere' });
eventSchema.index({ startDate: 1, endDate: 1 });
eventSchema.index({ organizerType: 1, organizer: 1 });

// Virtual for event enrollments
eventSchema.virtual('enrollments', {
  ref: 'VolunteerEnrollment',
  localField: '_id',
  foreignField: 'event',
});

// Virtual for event organizer details
// eventSchema.virtual('organizerDetails', {
//   ref: function() {
//     return this.organizerType === 'user' ? 'User' : 'Organization';
//   },
//   localField: 'organizer',
//   foreignField: '_id',
//   justOne: true,
// });
// In event.model.js, update the virtual properties to use proper function syntax
eventSchema.virtual('isCompleted').get(function() {
  const now = new Date();
  const endTime = this.endDate || new Date(this.startDate.getTime() + (4 * 60 * 60 * 1000));
  return this.status === 'completed' || now > endTime;
});

// Check if registration is open
eventSchema.virtual('isRegistrationOpen').get(function () {
  if (this.status !== 'published') return false;
  if (!this.registrationDeadline) return true;
  return new Date() < this.registrationDeadline;
});

// Check available spots
eventSchema.virtual('availableSpots').get(async function() {
  if (!this.maxVolunteers) return 'Unlimited';
  const enrolledCount = await mongoose.model('VolunteerEnrollment').countDocuments({
    event: this._id,
    status: { $in: ['pending', 'approved'] },
  });
  return Math.max(0, this.maxVolunteers - enrolledCount);
});

// Check if event is upcoming
eventSchema.virtual('isUpcoming').get(function () {
  return this.status === 'published' && new Date() < this.startDate;
});

// Check if event is ongoing
eventSchema.virtual('isOngoing').get(function () {
  const now = new Date();
  const endTime = this.endDate || new Date(this.startDate.getTime() + (4 * 60 * 60 * 1000)); // Default 4 hours
  
  return this.status === 'published' && now >= this.startDate && now <= endTime;
});

// Check if event is completed
eventSchema.virtual('isCompleted').get(function () {
  const now = new Date();
  const endTime = this.endDate || new Date(this.startDate.getTime() + (4 * 60 * 60 * 1000)); // Default 4 hours
  
  return this.status === 'completed' || now > endTime;
});

// Pre-save hook to update status based on dates
eventSchema.pre('save', function(next) {
  const now = new Date();
  const endTime = this.endDate || new Date(this.startDate.getTime() + (4 * 60 * 60 * 1000));
  
  if (this.status !== 'cancelled' && this.status !== 'completed') {
    if (now > endTime) {
      this.status = 'completed';
    } else if (now >= this.startDate && now <= endTime) {
      this.status = 'ongoing';
    } else if (this.status === 'draft' && this.isPublished) {
      this.status = 'published';
    }
  }
  
  next();
});

// Instance method to check if user is enrolled
eventSchema.methods.isUserEnrolled = async function(userId) {
  const enrollment = await mongoose.model('VolunteerEnrollment').findOne({
    event: this._id,
    user: userId,
    status: { $in: ['pending', 'approved'] },
  });
  return !!enrollment;
};

// Static method to get events by organizer
eventSchema.statics.findByOrganizer = function(organizerId, organizerType = 'user') {
  return this.find({ organizer: organizerId, organizerType });
};

// Static method to get upcoming events
eventSchema.statics.getUpcomingEvents = function(limit = 10) {
  return this.find({
    status: 'published',
    startDate: { $gte: new Date() },
  })
  .sort({ startDate: 1 })
  .limit(limit)
  .populate('organizer', 'name logo');
};

// Text search index for full-text search
eventSchema.index(
  { title: 'text', description: 'text', 'location.address': 'text', 'location.city': 'text' },
  { weights: { title: 10, description: 5, 'location.address': 3, 'location.city': 2 } }
);
  // return this.status === 'completed' || now > endTime;

// Add text index for search
eventSchema.index({ title: 'text', description: 'text', location: 'text' });

const Event = mongoose.model('Event', eventSchema);

export default Event;
