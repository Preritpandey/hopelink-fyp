import ApiError from './ApiError.js';

class NotFoundError extends ApiError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404);
  }
}

export default NotFoundError;
