import crypto from 'crypto';

/**
 * Generates a random string of the specified length
 * @param {number} length - Length of the random string
 * @returns {string} Random string
 */
/**
 * Generates a random password with the specified length
 * @param {number} length - Length of the password (default: 12)
 * @returns {string} Randomly generated password
 */
export const generateRandomPassword = (length = 12) => {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  const values = new Uint32Array(length);
  crypto.getRandomValues(values);
  
  for (let i = 0; i < length; i++) {
    password += charset[values[i] % charset.length];
  }
  
  // Ensure password has at least one of each required character type
  if (!/[a-z]/.test(password)) {
    password = password.slice(0, -1) + 'a';
  }
  if (!/[A-Z]/.test(password)) {
    password = password.slice(0, -1) + 'A';
  }
  if (!/[0-9]/.test(password)) {
    password = password.slice(0, -1) + '1';
  }
  if (!/[!@#$%^&*]/.test(password)) {
    password = password.slice(0, -1) + '!';
  }
  
  return password;
};

/**
 * Generates a random string of the specified length
 * @param {number} length - Length of the random string
 * @returns {string} Random string
 */
export const generateRandomString = (length = 10) => {
  return crypto.randomBytes(Math.ceil(length / 2))
    .toString('hex')
    .slice(0, length);
};

/**
 * Generates a random number between min and max (inclusive)
 * @param {number} min - Minimum value (inclusive)
 * @param {number} max - Maximum value (inclusive)
 * @returns {number} Random number between min and max
 */
export const getRandomInt = (min, max) => {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min + 1)) + min;
};

/**
 * Formats a date to a readable string
 * @param {Date} date - Date object to format
 * @returns {string} Formatted date string (e.g., "January 1, 2023")
 */
export const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
};

/**
 * Truncates a string to the specified length and adds an ellipsis if needed
 * @param {string} str - String to truncate
 * @param {number} maxLength - Maximum length of the string
 * @returns {string} Truncated string with ellipsis if needed
 */
export const truncateString = (str, maxLength = 100) => {
  if (!str) return '';
  return str.length > maxLength ? `${str.substring(0, maxLength)}...` : str;
};

/**
 * Validates if a string is a valid email address
 * @param {string} email - Email address to validate
 * @returns {boolean} True if the email is valid, false otherwise
 */
export const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Converts a string to title case
 * @param {string} str - String to convert
 * @returns {string} String in title case
 */
export const toTitleCase = (str) => {
  if (!str) return '';
  return str.replace(/\w\S*/g, (txt) => 
    txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
  );
};

/**
 * Generates a slug from a string
 * @param {string} str - String to convert to a slug
 * @returns {string} Generated slug
 */
export const slugify = (str) => {
  if (!str) return '';
  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
};

export default {
  generateRandomString,
  getRandomInt,
  formatDate,
  truncateString,
  isValidEmail,
  toTitleCase,
  slugify,
};
