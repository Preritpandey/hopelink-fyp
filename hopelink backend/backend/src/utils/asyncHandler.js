/**
 * Async error handler wrapper
 * Wraps async functions to catch errors and pass them to the error handling middleware
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export default asyncHandler;