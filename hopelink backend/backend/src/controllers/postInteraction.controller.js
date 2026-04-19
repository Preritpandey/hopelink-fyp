import { StatusCodes } from 'http-status-codes';
import PostLike from '../models/postLike.model.js';
import PostComment from '../models/postComment.model.js';
import {
  attachInteractionsToDoc,
  buildInteractionMap,
  resolvePostById,
} from '../services/postInteraction.service.js';
import {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
} from '../errors/index.js';

const buildLikeResponse = async ({ postId, postType, userId }) => {
  const interactionMap = await buildInteractionMap({
    postType,
    postIds: [postId],
    currentUserId: userId,
  });

  return attachInteractionsToDoc({ _id: postId }, interactionMap);
};

export const likePost = async (req, res) => {
  const { postId } = req.params;
  const { postType } = await resolvePostById(postId);

  await PostLike.findOneAndUpdate(
    {
      userId: req.user._id,
      postId,
      postType,
    },
    {
      $setOnInsert: {
        userId: req.user._id,
        postId,
        postType,
      },
    },
    {
      new: true,
      upsert: true,
    },
  );

  const interaction = await buildLikeResponse({
    postId,
    postType,
    userId: req.user._id,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Post liked successfully',
    data: {
      postId,
      postType,
      totalLikes: interaction.totalLikes,
      isLikedByCurrentUser: interaction.isLikedByCurrentUser,
    },
  });
};

export const unlikePost = async (req, res) => {
  const { postId } = req.params;
  const { postType } = await resolvePostById(postId);

  await PostLike.findOneAndDelete({
    userId: req.user._id,
    postId,
    postType,
  });

  const interaction = await buildLikeResponse({
    postId,
    postType,
    userId: req.user._id,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Post unliked successfully',
    data: {
      postId,
      postType,
      totalLikes: interaction.totalLikes,
      isLikedByCurrentUser: interaction.isLikedByCurrentUser,
    },
  });
};

export const addComment = async (req, res) => {
  const { postId } = req.params;
  const { text } = req.body;

  if (!text?.trim()) {
    throw new BadRequestError('Comment text is required');
  }

  const { postType } = await resolvePostById(postId);

  const comment = await PostComment.create({
    userId: req.user._id,
    postId,
    postType,
    text: text.trim(),
  });

  await comment.populate({
    path: 'userId',
    select: 'name profileImage email',
  });

  res.status(StatusCodes.CREATED).json({
    success: true,
    message: 'Comment added successfully',
    data: {
      _id: comment._id,
      postId: comment.postId,
      postType: comment.postType,
      text: comment.text,
      user: comment.userId,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    },
  });
};

export const getCommentsForPost = async (req, res) => {
  const { postId } = req.params;
  const { postType } = await resolvePostById(postId);

  const comments = await PostComment.find({ postId, postType })
    .populate({
      path: 'userId',
      select: 'name profileImage email',
    })
    .sort({ createdAt: -1 })
    .lean();

  res.status(StatusCodes.OK).json({
    success: true,
    count: comments.length,
    data: comments.map((comment) => ({
      _id: comment._id,
      postId: comment.postId,
      postType: comment.postType,
      text: comment.text,
      user: comment.userId,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      isOwner:
        req.user?._id?.toString() === comment.userId?._id?.toString(),
    })),
  });
};

export const deleteComment = async (req, res) => {
  const { commentId } = req.params;
  const comment = await PostComment.findById(commentId);

  if (!comment) {
    throw new NotFoundError('Comment not found');
  }

  if (comment.userId.toString() !== req.user._id.toString()) {
    throw new ForbiddenError('You can only delete your own comments');
  }

  await comment.deleteOne();

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Comment deleted successfully',
    data: {
      _id: commentId,
    },
  });
};
