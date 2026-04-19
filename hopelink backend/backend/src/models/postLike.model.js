import mongoose from 'mongoose';

const supportedPostTypes = ['Campaign', 'Event', 'VolunteerJob'];

const postLikeSchema = new mongoose.Schema(
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
      enum: supportedPostTypes,
      required: true,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

postLikeSchema.index({ userId: 1, postId: 1, postType: 1 }, { unique: true });
postLikeSchema.index({ postId: 1, postType: 1, createdAt: -1 });

const PostLike =
  mongoose.models.PostLike || mongoose.model('PostLike', postLikeSchema);

export { supportedPostTypes };
export default PostLike;
