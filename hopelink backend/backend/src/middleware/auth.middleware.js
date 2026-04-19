import jwt from 'jsonwebtoken';
import { UnauthorizedError, ForbiddenError } from '../errors/index.js';
import User from '../models/user.model.js';

/**
 * Middleware to authenticate user using JWT
 */
export const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided');
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw new UnauthorizedError('No token provided');
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (!decoded) {
      throw new UnauthorizedError('Invalid token');
    }

    // Get user from token - check both 'id' and 'userId' for backward compatibility
    const userId = decoded.userId || decoded.id;
    if (!userId) {
      throw new UnauthorizedError('Invalid token format');
    }

    const user = await User.findById(userId).select('-password');
    if (!user) {
      throw new UnauthorizedError('User not found');
    }

    // Check if user is active
    if (!user.isActive) {
      throw new ForbiddenError('Account is deactivated');
    }

    // Attach user to request object
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return next(new UnauthorizedError('Token expired'));
    }
    if (error.name === 'JsonWebTokenError') {
      return next(new UnauthorizedError('Invalid token'));
    }
    next(error);
  }
};

/**
 * Middleware to attach the current user if a valid bearer token is provided.
 * Requests without a token continue as public requests.
 */
export const authenticateIfPresent = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded?.userId || decoded?.id;

    if (!userId) {
      return next();
    }

    const user = await User.findById(userId).select('-password');
    if (user && user.isActive) {
      req.user = user;
    }

    next();
  } catch (error) {
    next();
  }
};

/**
 * Middleware to authorize user roles
 * @param {...string} roles - Allowed roles
 */
export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      throw new ForbiddenError('Not authorized to access this route');
    }
    next();
  };
};

/**
 * Middleware to check if user is verified
 */
export const checkVerified = (req, res, next) => {
  if (!req.user.isVerified) {
    throw new ForbiddenError('Please verify your email first');
  }
  next();
};

export default {
  authenticate,
  authenticateIfPresent,
  authorize,
  checkVerified,
};
