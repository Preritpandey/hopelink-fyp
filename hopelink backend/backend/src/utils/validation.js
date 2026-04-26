const objectIdPattern = /^[0-9a-fA-F]{24}$/;

const getValue = (req, source, field) => req?.[source]?.[field];

const makeError = (field, message, location) => ({
  field,
  message,
  location,
});

export const validateRequest = (rules = []) => (req, res, next) => {
  const errors = rules.flatMap((rule) => rule(req)).filter(Boolean);

  if (errors.length > 0) {
    const error = new Error('Validation failed');
    error.statusCode = 400;
    error.isOperational = true;
    error.details = errors;
    return next(error);
  }

  return next();
};

export const requiredString = (
  field,
  {
    source = 'body',
    label = field,
    minLength = 1,
    maxLength,
  } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (typeof value !== 'string' || value.trim().length < minLength) {
    return [makeError(field, `${label} is required`, source)];
  }

  if (maxLength && value.trim().length > maxLength) {
    return [makeError(field, `${label} cannot exceed ${maxLength} characters`, source)];
  }

  return [];
};

export const optionalString = (
  field,
  { source = 'body', label = field, maxLength } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (value == null || value === '') {
    return [];
  }

  if (typeof value !== 'string') {
    return [makeError(field, `${label} must be a string`, source)];
  }

  if (maxLength && value.trim().length > maxLength) {
    return [makeError(field, `${label} cannot exceed ${maxLength} characters`, source)];
  }

  return [];
};

export const requiredEnum = (
  field,
  values,
  { source = 'body', label = field } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (!values.includes(value)) {
    return [makeError(field, `${label} must be one of: ${values.join(', ')}`, source)];
  }

  return [];
};

export const optionalEnum = (
  field,
  values,
  { source = 'body', label = field } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (value == null || value === '') {
    return [];
  }

  if (!values.includes(value)) {
    return [makeError(field, `${label} must be one of: ${values.join(', ')}`, source)];
  }

  return [];
};

export const requiredObjectId = (
  field,
  { source = 'body', label = field } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (typeof value !== 'string' || !objectIdPattern.test(value)) {
    return [makeError(field, `${label} must be a valid ObjectId`, source)];
  }

  return [];
};

export const requiredDate = (
  field,
  { source = 'body', label = field, allowPast = false } = {},
) => (req) => {
  const value = getValue(req, source, field);
  const parsed = new Date(value);

  if (!value || Number.isNaN(parsed.getTime())) {
    return [makeError(field, `${label} must be a valid date`, source)];
  }

  if (!allowPast && parsed <= new Date()) {
    return [makeError(field, `${label} must be in the future`, source)];
  }

  return [];
};

export const optionalDate = (
  field,
  { source = 'body', label = field } = {},
) => (req) => {
  const value = getValue(req, source, field);

  if (value == null || value === '') {
    return [];
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return [makeError(field, `${label} must be a valid date`, source)];
  }

  return [];
};

export const customRule = (validator) => (req) => {
  const result = validator(req);
  if (!result) {
    return [];
  }

  return Array.isArray(result) ? result : [result];
};

export const isPlainObject = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

export const buildArrayItemError = (field, message, index, location = 'body') =>
  makeError(`${field}[${index}]`, message, location);

