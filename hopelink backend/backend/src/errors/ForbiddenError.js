import ApiError from './ApiError.js';

class ForbiddenError extends ApiError {
  constructor(message = 'Forbidden') {
    super(message, 403);
  }
}

export default ForbiddenError;
