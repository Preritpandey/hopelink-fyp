import DonationCommitment from '../models/donationCommitment.model.js';
import User from '../models/user.model.js';
import {
  BadRequestError,
  ForbiddenError,
  NotFoundError,
} from '../errors/index.js';
import {
  assertRequestOwnership,
  buildRequestReport,
  getEssentialRequestByIdOrThrow,
  getPledgeAvailability,
  reconcileExpiredRequests,
  syncRequestStatus,
} from './essentialRequest.service.js';
import { notifyOrganizationOnNewCommitment } from './essentialDonationNotification.service.js';

const COMMITMENT_POPULATION = [
  { path: 'userId', select: 'name email phoneNumber phone' },
  {
    path: 'requestId',
    select: 'title category urgencyLevel status createdBy pickupLocations itemsNeeded expiryDate',
    populate: {
      path: 'createdBy',
      select: 'organizationName officialEmail officialPhone',
    },
  },
];

const buildItemKey = (value = '') => value.trim().toLowerCase();

const normalizeItems = (items = []) =>
  Object.entries(
    items.reduce((accumulator, item) => {
      const key = buildItemKey(item.itemName);
      accumulator[key] = {
        itemName: item.itemName.trim(),
        quantity: (accumulator[key]?.quantity || 0) + Number(item.quantity || 0),
      };
      return accumulator;
    }, {}),
  ).map(([, value]) => value);

const canUserManageCommitment = (commitment, user) => {
  const ownerId = commitment.userId?._id?.toString?.() || commitment.userId?.toString?.();
  return user.role === 'admin' || ownerId === user._id.toString();
};

const assertUserRole = async (user) => {
  if (user.role !== 'user') {
    throw new ForbiddenError('Only users can commit essential donations');
  }

  const freshUser = await User.findById(user._id);
  if (!freshUser || !freshUser.isActive) {
    throw new ForbiddenError('User account is not active');
  }
};

const validateCommitmentItemsAgainstRequest = async (request, items) => {
  const availability = await getPledgeAvailability(request);
  const normalizedItems = normalizeItems(items);

  normalizedItems.forEach((item) => {
    const key = buildItemKey(item.itemName);
    const requestItem = availability[key];

    if (!requestItem) {
      throw new BadRequestError(
        `Item "${item.itemName}" is not listed on this request`,
      );
    }

    if (item.quantity > requestItem.quantityAvailable) {
      throw new BadRequestError(
        `Requested quantity for "${item.itemName}" exceeds the remaining available quantity`,
      );
    }
  });

  return normalizedItems;
};

const getPickupLocationOrThrow = (request, pickupLocationId) => {
  const pickupLocation = request.pickupLocations.find(
    (location) => location._id.toString() === pickupLocationId.toString(),
  );

  if (!pickupLocation) {
    throw new BadRequestError('Selected pickup location does not belong to this request');
  }

  return pickupLocation;
};

export const createDonationCommitment = async ({ payload, user }) => {
  await reconcileExpiredRequests();
  await assertUserRole(user);

  const request = await getEssentialRequestByIdOrThrow(payload.requestId);
  if (request.status !== 'active') {
    throw new BadRequestError('This essential request is not accepting commitments');
  }

  if (request.expiryDate < new Date()) {
    throw new BadRequestError('This essential request has already expired');
  }

  const itemsDonating = await validateCommitmentItemsAgainstRequest(
    request,
    payload.itemsDonating,
  );
  getPickupLocationOrThrow(request, payload.selectedPickupLocationId);

  const commitment = await DonationCommitment.create({
    userId: user._id,
    requestId: request._id,
    itemsDonating,
    selectedPickupLocationId: payload.selectedPickupLocationId,
    deliveryDate: payload.deliveryDate,
    proofImage: payload.proofImage,
    status: 'pledged',
  });

  await notifyOrganizationOnNewCommitment({
    organizationId: request.createdBy?._id || request.createdBy,
    requestId: request._id,
    commitmentId: commitment._id,
    userId: user._id,
  });

  return DonationCommitment.findById(commitment._id).populate(COMMITMENT_POPULATION);
};

export const getUserCommitments = async (user) => {
  const commitments = await DonationCommitment.find({ userId: user._id })
    .populate(COMMITMENT_POPULATION)
    .sort({ createdAt: -1 });

  return commitments.map((commitment) => {
    const commitmentObject = commitment.toObject();
    const location =
      commitmentObject.requestId?.pickupLocations?.find(
        (pickupLocation) =>
          pickupLocation._id.toString() ===
          commitmentObject.selectedPickupLocationId.toString(),
      ) || null;

    return {
      ...commitmentObject,
      selectedPickupLocation: location,
    };
  });
};

export const getCommitmentsForOrganizationRequest = async ({ requestId, user }) => {
  const request = await getEssentialRequestByIdOrThrow(requestId);
  assertRequestOwnership(request, user);

  const commitments = await DonationCommitment.find({ requestId })
    .populate(COMMITMENT_POPULATION)
    .sort({ createdAt: -1 });

  return {
    request: {
      ...request.toObject(),
      reporting: await buildRequestReport(request),
    },
    summary: {
      totalCommitments: commitments.length,
      pledged: commitments.filter((commitment) => commitment.status === 'pledged').length,
      delivered: commitments.filter((commitment) => commitment.status === 'delivered').length,
      verified: commitments.filter((commitment) => commitment.status === 'verified').length,
      rejected: commitments.filter((commitment) => commitment.status === 'rejected').length,
    },
    commitments,
  };
};

const applyFulfillment = async (request, commitment) => {
  if (commitment.fulfillmentApplied) {
    return;
  }

  commitment.itemsDonating.forEach((item) => {
    const requestItem = request.itemsNeeded.find(
      (neededItem) => buildItemKey(neededItem.itemName) === buildItemKey(item.itemName),
    );

    if (!requestItem) {
      throw new BadRequestError(
        `Request item "${item.itemName}" no longer exists on the request`,
      );
    }

    const nextValue = requestItem.quantityFulfilled + Number(item.quantity || 0);
    if (nextValue > requestItem.quantityRequired) {
      throw new BadRequestError(
        `Verifying "${item.itemName}" would exceed the required quantity`,
      );
    }

    requestItem.quantityFulfilled = nextValue;
  });

  commitment.fulfillmentApplied = true;
};

export const updateDonationCommitmentStatus = async ({
  commitmentId,
  payload,
  user,
}) => {
  const commitment = await DonationCommitment.findById(commitmentId).populate(
    COMMITMENT_POPULATION,
  );

  if (!commitment) {
    throw new NotFoundError('Donation commitment not found');
  }

  const request = await getEssentialRequestByIdOrThrow(
    commitment.requestId?._id || commitment.requestId,
  );

  const nextStatus = payload.status;

  if (nextStatus === 'delivered') {
    if (!canUserManageCommitment(commitment, user)) {
      throw new ForbiddenError('You are not allowed to update this commitment');
    }

    if (commitment.status !== 'pledged') {
      throw new BadRequestError('Only pledged commitments can be marked as delivered');
    }

    commitment.status = 'delivered';
    commitment.deliveryDate = payload.deliveryDate || new Date();
    if (payload.proofImage) {
      commitment.proofImage = payload.proofImage;
    }

    await commitment.save();
    return DonationCommitment.findById(commitment._id).populate(COMMITMENT_POPULATION);
  }

  assertRequestOwnership(request, user);

  if (nextStatus === 'verified') {
    if (commitment.status !== 'delivered') {
      throw new BadRequestError('Only delivered commitments can be verified');
    }

    await applyFulfillment(request, commitment);
    commitment.status = 'verified';
    await request.save();
    await commitment.save();
    await syncRequestStatus(request);
  }

  if (nextStatus === 'rejected') {
    if (!['pledged', 'delivered'].includes(commitment.status)) {
      throw new BadRequestError('Only pledged or delivered commitments can be rejected');
    }

    commitment.status = 'rejected';
    await commitment.save();
  }

  return DonationCommitment.findById(commitment._id).populate(COMMITMENT_POPULATION);
};

export default {
  createDonationCommitment,
  getCommitmentsForOrganizationRequest,
  getUserCommitments,
  updateDonationCommitmentStatus,
};
