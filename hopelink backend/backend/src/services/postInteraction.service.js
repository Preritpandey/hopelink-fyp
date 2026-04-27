import mongoose from 'mongoose';
import Campaign from '../models/campaign.model.js';
import Event from '../models/event.model.js';
import VolunteerJob from '../models/volunteerJob.model.js';
import PostLike from '../models/postLike.model.js';
import PostComment from '../models/postComment.model.js';
import SavedCause from '../models/savedCause.model.js';
import { BadRequestError, NotFoundError } from '../errors/index.js';

const POST_MODELS = {
  Campaign,
  Event,
  VolunteerJob,
};

const normalizeId = (value) => value?.toString();

export const validatePostObjectId = (postId) => {
  if (!mongoose.Types.ObjectId.isValid(postId)) {
    throw new BadRequestError('Invalid post id');
  }
};

export const resolvePostById = async (postId) => {
  validatePostObjectId(postId);

  const matches = await Promise.all(
    Object.entries(POST_MODELS).map(async ([postType, Model]) => {
      const doc = await Model.findById(postId).select('_id');
      return doc ? { postType, post: doc } : null;
    }),
  );

  const found = matches.filter(Boolean);

  if (found.length === 0) {
    throw new NotFoundError('Post not found');
  }

  if (found.length > 1) {
    throw new BadRequestError(
      'Ambiguous post id. Please ensure post ids are unique across post types.',
    );
  }

  return found[0];
};

export const buildInteractionMap = async ({
  postType,
  postIds = [],
  currentUserId = null,
}) => {
  const normalizedIds = [...new Set(postIds.map(normalizeId).filter(Boolean))];

  if (!normalizedIds.length) {
    return new Map();
  }

  const objectIds = normalizedIds.map((id) => new mongoose.Types.ObjectId(id));

  const [likeCounts, commentCounts, likedRows, savedRows] = await Promise.all([
    PostLike.aggregate([
      { $match: { postType, postId: { $in: objectIds } } },
      { $group: { _id: '$postId', totalLikes: { $sum: 1 } } },
    ]),
    PostComment.aggregate([
      { $match: { postType, postId: { $in: objectIds } } },
      { $group: { _id: '$postId', commentsCount: { $sum: 1 } } },
    ]),
    currentUserId
      ? PostLike.find({
          postType,
          postId: { $in: objectIds },
          userId: currentUserId,
        })
          .select('postId')
          .lean()
      : [],
    currentUserId
      ? SavedCause.find({
          postType,
          postId: { $in: objectIds },
          userId: currentUserId,
        })
          .select('postId')
          .lean()
      : [],
  ]);

  const map = new Map(
    normalizedIds.map((id) => [
      id,
      {
        totalLikes: 0,
        isLikedByCurrentUser: false,
        commentsCount: 0,
        isSavedByCurrentUser: false,
      },
    ]),
  );

  likeCounts.forEach(({ _id, totalLikes }) => {
    const key = normalizeId(_id);
    map.set(key, {
      ...(map.get(key) || {}),
      totalLikes,
    });
  });

  commentCounts.forEach(({ _id, commentsCount }) => {
    const key = normalizeId(_id);
    map.set(key, {
      ...(map.get(key) || {}),
      commentsCount,
    });
  });

  likedRows.forEach(({ postId }) => {
    const key = normalizeId(postId);
    map.set(key, {
      ...(map.get(key) || {}),
      isLikedByCurrentUser: true,
    });
  });

  savedRows.forEach(({ postId }) => {
    const key = normalizeId(postId);
    map.set(key, {
      ...(map.get(key) || {}),
      isSavedByCurrentUser: true,
    });
  });

  return map;
};

export const attachInteractionsToDoc = (doc, interactionMap) => {
  const plain = doc?.toObject ? doc.toObject() : { ...doc };
  const interaction =
    interactionMap.get(normalizeId(plain._id)) || {
      totalLikes: 0,
      isLikedByCurrentUser: false,
      commentsCount: 0,
      isSavedByCurrentUser: false,
    };

  return {
    ...plain,
    ...interaction,
  };
};

export const attachInteractionsToDocs = (docs, postType, currentUserId = null) =>
  buildInteractionMap({
    postType,
    postIds: docs.map((doc) => doc._id),
    currentUserId,
  }).then((interactionMap) =>
    docs.map((doc) => attachInteractionsToDoc(doc, interactionMap)),
  );

export const deleteInteractionsForPost = async ({ postId, postType }) => {
  await Promise.all([
    PostLike.deleteMany({ postId, postType }),
    PostComment.deleteMany({ postId, postType }),
    SavedCause.deleteMany({ postId, postType }),
  ]);
};
