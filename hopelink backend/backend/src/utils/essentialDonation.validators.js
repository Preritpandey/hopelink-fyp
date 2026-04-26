import {
  buildArrayItemError,
  customRule,
  isPlainObject,
  optionalDate,
  optionalEnum,
  optionalString,
  requiredDate,
  requiredEnum,
  requiredObjectId,
  requiredString,
} from './validation.js';

const validateItemsNeeded = customRule((req) => {
  const items = req.body.itemsNeeded;

  if (!Array.isArray(items) || items.length === 0) {
    return {
      field: 'itemsNeeded',
      message: 'itemsNeeded must be a non-empty array',
      location: 'body',
    };
  }

  return items.flatMap((item, index) => {
    const errors = [];
    if (!isPlainObject(item)) {
      return [buildArrayItemError('itemsNeeded', 'Each item must be an object', index)];
    }

    if (typeof item.itemName !== 'string' || !item.itemName.trim()) {
      errors.push(buildArrayItemError('itemsNeeded', 'itemName is required', index));
    }

    if (typeof item.quantityRequired !== 'number' || item.quantityRequired <= 0) {
      errors.push(
        buildArrayItemError(
          'itemsNeeded',
          'quantityRequired must be a number greater than 0',
          index,
        ),
      );
    }

    if (typeof item.unit !== 'string' || !item.unit.trim()) {
      errors.push(buildArrayItemError('itemsNeeded', 'unit is required', index));
    }

    return errors;
  });
});

const validatePickupLocations = customRule((req) => {
  const locations = req.body.pickupLocations;

  if (!Array.isArray(locations) || locations.length === 0) {
    return {
      field: 'pickupLocations',
      message: 'pickupLocations must be a non-empty array',
      location: 'body',
    };
  }

  return locations.flatMap((location, index) => {
    const errors = [];
    if (!isPlainObject(location)) {
      return [
        buildArrayItemError('pickupLocations', 'Each location must be an object', index),
      ];
    }

    if (typeof location.address !== 'string' || !location.address.trim()) {
      errors.push(buildArrayItemError('pickupLocations', 'address is required', index));
    }

    if (typeof location.latitude !== 'number') {
      errors.push(buildArrayItemError('pickupLocations', 'latitude must be a number', index));
    }

    if (typeof location.longitude !== 'number') {
      errors.push(buildArrayItemError('pickupLocations', 'longitude must be a number', index));
    }

    if (typeof location.contactPerson !== 'string' || !location.contactPerson.trim()) {
      errors.push(
        buildArrayItemError('pickupLocations', 'contactPerson is required', index),
      );
    }

    if (typeof location.contactPhone !== 'string' || !location.contactPhone.trim()) {
      errors.push(
        buildArrayItemError('pickupLocations', 'contactPhone is required', index),
      );
    }

    if (
      typeof location.availableTimeSlots !== 'string' ||
      !location.availableTimeSlots.trim()
    ) {
      errors.push(
        buildArrayItemError(
          'pickupLocations',
          'availableTimeSlots is required',
          index,
        ),
      );
    }

    return errors;
  });
});

const validateImages = customRule((req) => {
  const { images } = req.body;

  if (images == null) {
    return [];
  }

  if (!Array.isArray(images)) {
    return {
      field: 'images',
      message: 'images must be an array of strings',
      location: 'body',
    };
  }

  return images.flatMap((image, index) => {
    if (typeof image !== 'string' || !image.trim()) {
      return [buildArrayItemError('images', 'Each image must be a non-empty string', index)];
    }

    return [];
  });
});

const validateItemsDonating = customRule((req) => {
  const items = req.body.itemsDonating;

  if (!Array.isArray(items) || items.length === 0) {
    return {
      field: 'itemsDonating',
      message: 'itemsDonating must be a non-empty array',
      location: 'body',
    };
  }

  return items.flatMap((item, index) => {
    const errors = [];
    if (!isPlainObject(item)) {
      return [buildArrayItemError('itemsDonating', 'Each item must be an object', index)];
    }

    if (typeof item.itemName !== 'string' || !item.itemName.trim()) {
      errors.push(buildArrayItemError('itemsDonating', 'itemName is required', index));
    }

    if (typeof item.quantity !== 'number' || item.quantity <= 0) {
      errors.push(
        buildArrayItemError(
          'itemsDonating',
          'quantity must be a number greater than 0',
          index,
        ),
      );
    }

    return errors;
  });
});

export const createEssentialRequestRules = [
  requiredString('title', { maxLength: 150, label: 'title' }),
  optionalString('description', { maxLength: 2000, label: 'description' }),
  requiredEnum('category', ['food', 'clothes', 'medicine', 'other'], {
    label: 'category',
  }),
  requiredEnum('urgencyLevel', ['low', 'medium', 'high'], {
    label: 'urgencyLevel',
  }),
  requiredDate('expiryDate', { label: 'expiryDate' }),
  validateItemsNeeded,
  validatePickupLocations,
  validateImages,
];

export const updateEssentialRequestRules = [
  requiredObjectId('id', { source: 'params', label: 'request id' }),
  optionalString('title', { maxLength: 150, label: 'title' }),
  optionalString('description', { maxLength: 2000, label: 'description' }),
  optionalEnum('category', ['food', 'clothes', 'medicine', 'other'], {
    label: 'category',
  }),
  optionalEnum('urgencyLevel', ['low', 'medium', 'high'], {
    label: 'urgencyLevel',
  }),
  optionalDate('expiryDate', { label: 'expiryDate' }),
  customRule((req) => {
    if (req.body.itemsNeeded == null) {
      return [];
    }
    return validateItemsNeeded(req);
  }),
  customRule((req) => {
    if (req.body.pickupLocations == null) {
      return [];
    }
    return validatePickupLocations(req);
  }),
  validateImages,
];

export const listEssentialRequestsRules = [
  optionalEnum('category', ['food', 'clothes', 'medicine', 'other'], {
    source: 'query',
    label: 'category',
  }),
  optionalEnum('urgency', ['low', 'medium', 'high'], {
    source: 'query',
    label: 'urgency',
  }),
];

export const requestIdParamRules = [
  requiredObjectId('id', { source: 'params', label: 'request id' }),
];

export const createCommitmentRules = [
  requiredObjectId('requestId', { label: 'requestId' }),
  requiredObjectId('selectedPickupLocationId', { label: 'selectedPickupLocationId' }),
  validateItemsDonating,
  optionalDate('deliveryDate', { label: 'deliveryDate' }),
  optionalString('proofImage', { maxLength: 500, label: 'proofImage' }),
];

export const commitmentIdParamRules = [
  requiredObjectId('id', { source: 'params', label: 'commitment id' }),
];

export const orgRequestCommitmentsRules = [
  requiredObjectId('id', { source: 'params', label: 'request id' }),
];

export const updateCommitmentStatusRules = [
  requiredObjectId('id', { source: 'params', label: 'commitment id' }),
  requiredEnum('status', ['delivered', 'verified', 'rejected'], {
    label: 'status',
  }),
  optionalDate('deliveryDate', { label: 'deliveryDate' }),
  optionalString('proofImage', { maxLength: 500, label: 'proofImage' }),
];
