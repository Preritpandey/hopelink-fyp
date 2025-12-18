import ApiError from './ApiError.js';

class BadRequestError extends ApiError {
  constructor(message = 'Bad Request') {
    super(message, 400);
  }
}

export default BadRequestError;
