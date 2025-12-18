import ApiError from './ApiError.js';

class ValidationError extends ApiError {
  constructor(errors = {}) {
    const message = 'Validation failed';
    super(message, 400);
    this.errors = errors;
  }
}

export default ValidationError;
