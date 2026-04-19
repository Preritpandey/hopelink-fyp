import mongoose from 'mongoose';
import { supportedPostTypes } from './postLike.model.js';

const postCommentSchema = new mongoose.Schema(
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
    text: {
      type: String,
      required: [true, 'Comment text is required'],
      trim: true,
      maxlength: [1000, 'Comment cannot exceed 1000 characters'],
    },
  },
  {
    timestamps: true,
  },
);

postCommentSchema.index({ postId: 1, postType: 1, createdAt: -1 });

const PostComment =
  mongoose.models.PostComment ||
  mongoose.model('PostComment', postCommentSchema);

export default PostComment;
