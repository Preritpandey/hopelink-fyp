import ApiError from './ApiError.js';

class UnauthorizedError extends ApiError {
  constructor(message = 'Not authorized to access this route') {
    super(message, 401);
  }
}

export default UnauthorizedError;
