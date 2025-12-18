class ApiError extends Error {
  constructor(message, statusCode, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    this.details = details;
    this.timestamp = new Date().toISOString();

    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      success: false,
      status: this.status,
      error: {
        message: this.message,
        code: this.statusCode,
        details: this.details,
        timestamp: this.timestamp
      }
    };
  }
}

export default ApiError;
