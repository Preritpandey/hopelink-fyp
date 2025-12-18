import { StatusCodes } from 'http-status-codes';

/**
 * Global error handler middleware
 * Handles all errors in a consistent format
 */
const errorHandler = (err, req, res, next) => {
  // Default error response
  let errorResponse = {
    success: false,
    error: {
      message: err.message || 'Internal Server Error',
      code: err.statusCode || StatusCodes.INTERNAL_SERVER_ERROR,
      details: err.details || null,
      timestamp: new Date().toISOString()
    }
  };

  // Handle specific error types
  if (err.name === 'ValidationError') {
    // Mongoose validation error
    errorResponse.error.message = 'Validation Error';
    errorResponse.error.code = StatusCodes.BAD_REQUEST;
    errorResponse.error.details = Object.values(err.errors).map(e => ({
      field: e.path,
      message: e.message,
      type: e.kind,
      value: e.value
    }));
    
    console.error(`[${errorResponse.error.timestamp}] Validation Error:`, errorResponse.error.details);
    return res.status(errorResponse.error.code).json(errorResponse);
  }

  // Handle duplicate key errors (MongoDB)
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    errorResponse.error.message = `${field} already exists`;
    errorResponse.error.code = StatusCodes.CONFLICT;
    errorResponse.error.details = {
      field,
      value: err.keyValue[field],
      suggestion: `Please use a different ${field} or try to log in.`
    };
    
    console.error(`[${errorResponse.error.timestamp}] Duplicate Key Error:`, errorResponse.error);
    return res.status(errorResponse.error.code).json(errorResponse);
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    errorResponse.error.message = 'Invalid or expired token';
    errorResponse.error.code = StatusCodes.UNAUTHORIZED;
    errorResponse.error.details = {
      action: 'Please log in again',
      code: 'AUTH_REQUIRED'
    };
    
    console.error(`[${errorResponse.error.timestamp}] Authentication Error:`, errorResponse.error);
    return res.status(errorResponse.error.code).json(errorResponse);
  }

  // Handle CastError (invalid ObjectId)
  if (err.name === 'CastError') {
    errorResponse.error.message = 'Invalid resource identifier';
    errorResponse.error.code = StatusCodes.BAD_REQUEST;
    errorResponse.error.details = {
      resource: err.path,
      value: err.value,
      message: 'The provided ID is not valid'
    };
    return res.status(errorResponse.error.code).json(errorResponse);
  }

  // Handle custom API errors
  if (err.isOperational) {
    console.error(`[${errorResponse.error.timestamp}] Operational Error:`, errorResponse.error);
    return res.status(errorResponse.error.code).json(errorResponse);
  }

  // Log unexpected errors
  console.error(`[${errorResponse.error.timestamp}] Unexpected Error:`, err);
  
  // In production, don't leak error details
  if (process.env.NODE_ENV === 'production') {
    errorResponse.error.message = 'Something went wrong';
    errorResponse.error.details = null;
  } else {
    errorResponse.error.stack = err.stack;
  }

  // Send the final error response
  return res.status(errorResponse.error.code).json(errorResponse);
};

export default errorHandler;
