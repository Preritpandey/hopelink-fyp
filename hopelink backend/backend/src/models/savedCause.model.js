import mongoose from 'mongoose';

const savedCauseSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    postType: {
      type: String,
      enum: ['Campaign', 'Event', 'VolunteerJob'],
      required: true,
    },
  },
  {
    timestamps: true,
  },
);

savedCauseSchema.index(
  { userId: 1, postId: 1, postType: 1 },
  { unique: true },
);

const SavedCause =
  mongoose.models.SavedCause ||
  mongoose.model('SavedCause', savedCauseSchema);

export default SavedCause;
