import ApiError from './ApiError.js';
import BadRequestError from './BadRequestError.js';
import NotFoundError from './NotFoundError.js';
import UnauthorizedError from './UnauthorizedError.js';
import UnauthenticatedError from './UnauthenticatedError.js';
import ForbiddenError from './ForbiddenError.js';
import ValidationError from './ValidationError.js';

// Export all error classes
export {
  ApiError,
  BadRequestError,
  NotFoundError,
  UnauthorizedError,
  UnauthenticatedError,
  ForbiddenError,
  ValidationError
};

// Note: Error handling middleware has been moved to src/middleware/errorHandler.js
// This file now only serves as a central export point for all error classes
