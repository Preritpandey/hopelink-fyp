import mongoose from 'mongoose';

const volunteerEnrollmentSchema = new mongoose.Schema({
  event: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Event',
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'withdrawn', 'attended'],
    default: 'pending',
  },
  enrollmentDate: {
    type: Date,
    default: Date.now,
  },
  notes: {
    type: String,
    trim: true,
  },
  attendance: {
    type: Boolean,
    default: false,
  },
  feedback: {
    rating: {
      type: Number,
      min: 1,
      max: 5,
    },
    comment: String,
    submittedAt: Date,
  },
}, {
  timestamps: true,
});

// Compound index to ensure a user can only enroll once per event
volunteerEnrollmentSchema.index({ event: 1, user: 1 }, { unique: true });

// Virtual for event details
volunteerEnrollmentSchema.virtual('eventDetails', {
  ref: 'Event', 
  localField: 'event',
  foreignField: '_id',
  justOne: true,
});

// Virtual for user details (limited fields for privacy)
volunteerEnrollmentSchema.virtual('volunteer', {
  ref: 'User',
  localField: 'user',
  foreignField: '_id',
  justOne: true,
  select: 'name email profileImage',
});

// Pre-save hook to validate event exists and is open for enrollment
volunteerEnrollmentSchema.pre('save', async function(next) {
  const event = await mongoose.model('Event').findById(this.event);
  if (!event) {
    throw new Error('Event not found');
  }
  
  if (event.status !== 'published') {
    throw new Error('Event is not open for enrollment');
  }
  
  if (event.registrationDeadline && new Date() > event.registrationDeadline) {
    throw new Error('Registration deadline has passed');
  }
  
  next();
});

const VolunteerEnrollment = mongoose.model('VolunteerEnrollment', volunteerEnrollmentSchema);

export default VolunteerEnrollment;
