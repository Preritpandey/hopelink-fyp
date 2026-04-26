import EssentialRequest from '../models/essentialRequest.model.js';
import DonationCommitment from '../models/donationCommitment.model.js';
import Organization from '../models/organization.model.js';
import {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
} from '../errors/index.js';
import { notifyUsersOnRequestClosed } from './essentialDonationNotification.service.js';

const REQUEST_POPULATION = {
  path: 'createdBy',
  select: 'organizationName officialEmail officialPhone',
};

const buildItemKey = (value = '') => value.trim().toLowerCase();

const sumItems = (items = [], quantityField = 'quantity') =>
  items.reduce((accumulator, item) => {
    const key = buildItemKey(item.itemName);
    accumulator[key] = (accumulator[key] || 0) + Number(item[quantityField] || 0);
    return accumulator;
  }, {});

export const reconcileExpiredRequests = async () => {
  await EssentialRequest.updateMany(
    {
      status: 'active',
      expiryDate: { $lt: new Date() },
    },
    {
      $set: { status: 'expired' },
    },
  );
};

export const ensureOrganizationAccess = async (user) => {
  if (!user?.organization) {
    throw new ForbiddenError('Organization account is not linked to an organization');
  }

  const organization = await Organization.findById(user.organization);
  if (!organization) {
    throw new NotFoundError('Organization not found');
  }

  if (organization.status !== 'approved') {
    throw new ForbiddenError('Only approved organizations can manage essential requests');
  }

  return organization;
};

export const getEssentialRequestByIdOrThrow = async (requestId) => {
  await reconcileExpiredRequests();
  const request = await EssentialRequest.findById(requestId).populate(REQUEST_POPULATION);

  if (!request) {
    throw new NotFoundError('Essential request not found');
  }

  return request;
};

export const assertRequestOwnership = (request, user) => {
  const ownerId = request.createdBy?._id?.toString?.() || request.createdBy?.toString?.();
  const userOrgId = user?.organization?.toString?.();

  if (user.role !== 'admin' && ownerId !== userOrgId) {
    throw new ForbiddenError('You are not allowed to manage this essential request');
  }
};

export const getPendingReservedMap = async (requestId) => {
  const commitments = await DonationCommitment.find({
    requestId,
    status: { $in: ['pledged', 'delivered'] },
  }).lean();

  return commitments.reduce((accumulator, commitment) => {
    commitment.itemsDonating.forEach((item) => {
      const key = buildItemKey(item.itemName);
      accumulator[key] = (accumulator[key] || 0) + Number(item.quantity || 0);
    });
    return accumulator;
  }, {});
};

export const buildRequestReport = async (request) => {
  const allActiveCommitments = await DonationCommitment.find({
    requestId: request._id,
    status: { $in: ['pledged', 'delivered', 'verified'] },
  }).lean();

  const pledgedMap = allActiveCommitments.reduce((accumulator, commitment) => {
    commitment.itemsDonating.forEach((item) => {
      const key = buildItemKey(item.itemName);
      accumulator[key] = (accumulator[key] || 0) + Number(item.quantity || 0);
    });
    return accumulator;
  }, {});

  const items = request.itemsNeeded.map((item) => {
    const key = buildItemKey(item.itemName);
    return {
      itemName: item.itemName,
      unit: item.unit,
      quantityRequired: item.quantityRequired,
      quantityPledged: pledgedMap[key] || 0,
      quantityFulfilled: item.quantityFulfilled,
      quantityRemaining: Math.max(
        item.quantityRequired - item.quantityFulfilled,
        0,
      ),
    };
  });

  const totals = items.reduce(
    (accumulator, item) => ({
      quantityRequired: accumulator.quantityRequired + item.quantityRequired,
      quantityPledged: accumulator.quantityPledged + item.quantityPledged,
      quantityFulfilled: accumulator.quantityFulfilled + item.quantityFulfilled,
      quantityRemaining: accumulator.quantityRemaining + item.quantityRemaining,
    }),
    {
      quantityRequired: 0,
      quantityPledged: 0,
      quantityFulfilled: 0,
      quantityRemaining: 0,
    },
  );

  return { items, totals };
};

export const syncRequestStatus = async (request) => {
  const allFulfilled = request.itemsNeeded.every(
    (item) => item.quantityFulfilled >= item.quantityRequired,
  );

  const nextStatus = allFulfilled
    ? 'fulfilled'
    : request.expiryDate < new Date()
      ? 'expired'
      : 'active';

  const previousStatus = request.status;
  if (previousStatus !== nextStatus) {
    request.status = nextStatus;
    await request.save();

    if (nextStatus === 'fulfilled') {
      await notifyUsersOnRequestClosed({
        requestId: request._id,
        organizationId: request.createdBy?._id || request.createdBy,
      });
    }
  }

  return request;
};

export const createEssentialRequest = async ({ payload, user }) => {
  const organization = await ensureOrganizationAccess(user);

  const request = await EssentialRequest.create({
    ...payload,
    createdBy: organization._id,
    itemsNeeded: payload.itemsNeeded.map((item) => ({
      ...item,
      quantityFulfilled: 0,
    })),
  });

  return EssentialRequest.findById(request._id).populate(REQUEST_POPULATION);
};

export const listEssentialRequests = async ({ filters = {} }) => {
  await reconcileExpiredRequests();

  const query = {
    status: 'active',
  };

  if (filters.category) {
    query.category = filters.category;
  }

  if (filters.urgency) {
    query.urgencyLevel = filters.urgency;
  }

  const requests = await EssentialRequest.find(query)
    .populate(REQUEST_POPULATION)
    .sort({ urgencyLevel: -1, createdAt: -1 });

  const enriched = await Promise.all(
    requests.map(async (request) => ({
      ...request.toObject(),
      reporting: await buildRequestReport(request),
    })),
  );

  return enriched;
};

export const getEssentialRequestDetails = async (requestId) => {
  const request = await getEssentialRequestByIdOrThrow(requestId);
  return {
    ...request.toObject(),
    reporting: await buildRequestReport(request),
  };
};

export const updateEssentialRequest = async ({ requestId, payload, user }) => {
  const request = await getEssentialRequestByIdOrThrow(requestId);
  assertRequestOwnership(request, user);

  if (request.status === 'fulfilled') {
    throw new BadRequestError('Fulfilled requests cannot be updated');
  }

  const updates = { ...payload };
  delete updates.status;
  delete updates.createdBy;

  Object.assign(request, updates);
  await request.save();
  await syncRequestStatus(request);

  return {
    ...request.toObject(),
    reporting: await buildRequestReport(request),
  };
};

export const deleteEssentialRequest = async ({ requestId, user }) => {
  const request = await getEssentialRequestByIdOrThrow(requestId);
  assertRequestOwnership(request, user);

  const activeCommitments = await DonationCommitment.countDocuments({
    requestId,
    status: { $in: ['pledged', 'delivered', 'verified'] },
  });

  if (activeCommitments > 0) {
    throw new BadRequestError(
      'This request has active commitments and cannot be deleted',
    );
  }

  await request.deleteOne();
};

export const getPledgeAvailability = async (request) => {
  const reservedMap = await getPendingReservedMap(request._id);
  const fulfilledMap = sumItems(request.itemsNeeded, 'quantityFulfilled');

  return request.itemsNeeded.reduce((accumulator, item) => {
    const key = buildItemKey(item.itemName);
    accumulator[key] = {
      itemName: item.itemName,
      unit: item.unit,
      quantityRequired: item.quantityRequired,
      quantityFulfilled: fulfilledMap[key] || 0,
      quantityReserved: reservedMap[key] || 0,
      quantityAvailable: Math.max(
        item.quantityRequired -
          (fulfilledMap[key] || 0) -
          (reservedMap[key] || 0),
        0,
      ),
    };
    return accumulator;
  }, {});
};

export default {
  assertRequestOwnership,
  buildRequestReport,
  createEssentialRequest,
  deleteEssentialRequest,
  ensureOrganizationAccess,
  getEssentialRequestByIdOrThrow,
  getPledgeAvailability,
  listEssentialRequests,
  reconcileExpiredRequests,
  syncRequestStatus,
  updateEssentialRequest,
};
