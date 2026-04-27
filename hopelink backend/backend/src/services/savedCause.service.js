import Campaign from '../models/campaign.model.js';
import Event from '../models/event.model.js';
import VolunteerJob from '../models/volunteerJob.model.js';
import Organization from '../models/organization.model.js';
import User from '../models/user.model.js';
import SavedCause from '../models/savedCause.model.js';
import {
  attachInteractionsToDoc,
  buildInteractionMap,
  resolvePostById,
} from './postInteraction.service.js';
import { NotFoundError } from '../errors/index.js';

const FRONTEND_POST_TYPES = {
  Campaign: 'campaign',
  Event: 'event',
  VolunteerJob: 'volunteerJob',
};

const CAMPAIGN_ORG_POPULATE = {
  path: 'organization',
  select: 'organizationName',
  model: Organization,
};

const normalizeEventOrganizer = async (eventDoc) => {
  const event = eventDoc?.toObject ? eventDoc.toObject() : { ...eventDoc };

  if (!event.organizer) {
    return event;
  }

  if (event.organizerType === 'Organization') {
    const organizer = await Organization.findById(event.organizer)
      .select('organizationName officialEmail logo')
      .lean();

    event.organizer = organizer || {
      _id: event.organizer,
      organizationName: '',
      officialEmail: '',
    };
    return event;
  }

  const organizer = await User.findById(event.organizer)
    .select('name email profileImage')
    .lean();

  event.organizer = organizer
    ? {
        _id: organizer._id,
        organizationName: organizer.name || '',
        officialEmail: organizer.email || '',
        logo: organizer.profileImage || '',
      }
    : {
        _id: event.organizer,
        organizationName: '',
        officialEmail: '',
      };

  return event;
};

const buildEntry = ({ savedDoc, postType, post }) => ({
  id: savedDoc._id,
  postId: savedDoc.postId,
  postType: FRONTEND_POST_TYPES[postType] || postType,
  savedAt: savedDoc.createdAt,
  post,
});

export const saveCause = async (userId, postId) => {
  const { postType, post } = await resolvePostById(postId);

  const savedCause = await SavedCause.findOneAndUpdate(
    { userId, postId: post._id, postType },
    {
      $setOnInsert: {
        userId,
        postId: post._id,
        postType,
      },
    },
    {
      upsert: true,
      new: true,
      setDefaultsOnInsert: true,
    },
  ).lean();

  return {
    id: savedCause._id,
    postId: post._id,
    postType: FRONTEND_POST_TYPES[postType] || postType,
    savedAt: savedCause.createdAt,
    isSavedByCurrentUser: true,
  };
};

export const unsaveCause = async (userId, postId) => {
  const { postType, post } = await resolvePostById(postId);

  const removed = await SavedCause.findOneAndDelete({
    userId,
    postId: post._id,
    postType,
  }).lean();

  return {
    postId: post._id,
    postType: FRONTEND_POST_TYPES[postType] || postType,
    isSavedByCurrentUser: false,
    removed: Boolean(removed),
  };
};

export const getSavedCauses = async (userId) => {
  const savedDocs = await SavedCause.find({ userId }).sort({ createdAt: -1 }).lean();

  if (!savedDocs.length) {
    return [];
  }

  const idsByType = savedDocs.reduce((acc, item) => {
    acc[item.postType] = acc[item.postType] || [];
    acc[item.postType].push(item.postId);
    return acc;
  }, {});

  const [campaignDocs, eventDocs, jobDocs] = await Promise.all([
    idsByType.Campaign?.length
      ? Campaign.find({ _id: { $in: idsByType.Campaign } })
          .populate(CAMPAIGN_ORG_POPULATE)
      : [],
    idsByType.Event?.length
      ? Event.find({ _id: { $in: idsByType.Event } })
      : [],
    idsByType.VolunteerJob?.length
      ? VolunteerJob.find({ _id: { $in: idsByType.VolunteerJob } })
      : [],
  ]);

  const normalizedEventDocs = await Promise.all(
    eventDocs.map((eventDoc) => normalizeEventOrganizer(eventDoc)),
  );

  const [campaignInteractionMap, eventInteractionMap, jobInteractionMap] =
    await Promise.all([
      buildInteractionMap({
        postType: 'Campaign',
        postIds: campaignDocs.map((item) => item._id),
        currentUserId: userId,
      }),
      buildInteractionMap({
        postType: 'Event',
        postIds: normalizedEventDocs.map((item) => item._id),
        currentUserId: userId,
      }),
      buildInteractionMap({
        postType: 'VolunteerJob',
        postIds: jobDocs.map((item) => item._id),
        currentUserId: userId,
      }),
    ]);

  const postLookup = new Map();

  campaignDocs.forEach((item) => {
    postLookup.set(
      `Campaign:${item._id.toString()}`,
      attachInteractionsToDoc(item, campaignInteractionMap),
    );
  });
  normalizedEventDocs.forEach((item) => {
    postLookup.set(
      `Event:${item._id.toString()}`,
      attachInteractionsToDoc(item, eventInteractionMap),
    );
  });
  jobDocs.forEach((item) => {
    postLookup.set(
      `VolunteerJob:${item._id.toString()}`,
      attachInteractionsToDoc(item, jobInteractionMap),
    );
  });

  return savedDocs
    .map((savedDoc) => {
      const key = `${savedDoc.postType}:${savedDoc.postId.toString()}`;
      const post = postLookup.get(key);
      if (!post) return null;
      return buildEntry({
        savedDoc,
        postType: savedDoc.postType,
        post,
      });
    })
    .filter(Boolean);
};

export const assertSavedCauseExists = async (userId, postId) => {
  const { postType, post } = await resolvePostById(postId);

  const saved = await SavedCause.findOne({
    userId,
    postId: post._id,
    postType,
  }).lean();

  if (!saved) {
    throw new NotFoundError('Saved cause not found');
  }

  return saved;
};
