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
    campaign: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
      required: [true, 'Please provide a campaign ID'],
    },
    date: {
      type: Date,
      required: [true, 'Please provide an event date'],
    },
    location: {
      type: String,
      required: [true, 'Please provide a location'],
    },
    address: {
      type: String,
      required: [true, 'Please provide an address'],
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
      enum: ['upcoming', 'ongoing', 'completed', 'cancelled'],
      default: 'upcoming',
    },
    maxAttendees: {
      type: Number,
      min: [1, 'Maximum attendees must be at least 1'],
    },
    registrationRequired: {
      type: Boolean,
      default: false,
    },
    registrationDeadline: {
      type: Date,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual for event registrations
eventSchema.virtual('registrations', {
  ref: 'EventRegistration',
  localField: '_id',
  foreignField: 'event',
});

// Check if registration is open
eventSchema.virtual('isRegistrationOpen').get(function () {
  if (!this.registrationRequired) return true;
  if (!this.registrationDeadline) return true;
  return new Date() < this.registrationDeadline;
});

// Check if event is upcoming
eventSchema.virtual('isUpcoming').get(function () {
  return this.status === 'upcoming' && new Date() < this.date;
});

// Check if event is ongoing
eventSchema.virtual('isOngoing').get(function () {
  const now = new Date();
  const endTime = new Date(this.date);
  endTime.setHours(endTime.getHours() + 4); // Assuming 4-hour event duration
  
  return this.status === 'ongoing' || (now >= this.date && now <= endTime);
});

// Check if event is completed
// Check if event is completed
eventSchema.virtual('isCompleted').get(function () {
  const now = new Date();
  const endTime = new Date(this.date);
  endTime.setHours(endTime.getHours() + 4); // Assuming 4-hour event duration
  
  return this.status === 'completed' || now > endTime;
});

// Add text index for search
eventSchema.index({ title: 'text', description: 'text', location: 'text' });

const Event = mongoose.model('Event', eventSchema);

export default Event;
