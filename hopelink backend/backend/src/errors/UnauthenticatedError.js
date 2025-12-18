import ApiError from './ApiError.js';

class UnauthenticatedError extends ApiError {
  constructor(message = 'Not authenticated') {
    super(401, message);
  }
}

export default UnauthenticatedError;
