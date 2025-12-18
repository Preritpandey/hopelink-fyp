import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

// Validate required Cloudinary environment variables
const requiredEnvVars = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET'];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);

if (missingVars.length > 0) {
  throw new Error(`Missing required Cloudinary environment variables: ${missingVars.join(', ')}`);
}

// Configure Cloudinary with timeout and keep-alive
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
  timeout: 30000, // 30 seconds timeout
});

// File size limit: 10MB
const MAX_FILE_SIZE = 10 * 1024 * 1024;

// Allowed file types
const ALLOWED_FILE_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

/**
 * Upload a file to Cloudinary with retry logic
 * @param {string} filePath - Path to the file to upload
 * @param {string} [folder='hopelink'] - Folder in Cloudinary
 * @param {number} [retryCount=0] - Current retry attempt
 * @returns {Promise<Object>} Cloudinary upload result
 */
export const uploadToCloudinary = async (filePath, folder = 'hopelink', retryCount = 0) => {
  const MAX_RETRIES = 3;
  const RETRY_DELAY = 1000; // 1 second

  try {
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      throw new Error(`File not found: ${filePath}`);
    }

    // Check file size
    const stats = fs.statSync(filePath);
    if (stats.size > MAX_FILE_SIZE) {
      throw new Error(`File size exceeds maximum limit of ${MAX_FILE_SIZE / (1024 * 1024)}MB`);
    }

    // Check file type
    const fileExt = path.extname(filePath).toLowerCase();
    const mimeType = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    }[fileExt];

    if (!mimeType || !ALLOWED_FILE_TYPES.includes(mimeType)) {
      throw new Error(`File type not allowed. Allowed types: ${ALLOWED_FILE_TYPES.join(', ')}`);
    }

    const result = await cloudinary.uploader.upload(filePath, {
      folder,
      resource_type: 'auto',
      use_filename: true,
      unique_filename: true,
      chunk_size: 20 * 1024 * 1024, // 20MB chunks
      timeout: 60000, // 60 seconds
    });

    return result;
  } catch (error) {
    console.error(`Cloudinary upload error (attempt ${retryCount + 1}):`, error.message);
    
    // If we have retries left and it's a network error, retry
    if (retryCount < MAX_RETRIES && 
        (error.code === 'ECONNRESET' || 
         error.code === 'ETIMEDOUT' || 
         error.http_code === 429)) {
      console.log(`Retrying upload (${retryCount + 1}/${MAX_RETRIES})...`);
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY * (retryCount + 1)));
      return uploadToCloudinary(filePath, folder, retryCount + 1);
    }

    throw new Error(`Failed to upload file to Cloudinary after ${retryCount + 1} attempts: ${error.message}`);
  }
};

/**
 * Delete a file from Cloudinary
 * @param {string} publicId - The public ID of the file to delete
 * @returns {Promise<void>}
 */
export const deleteFromCloudinary = async (publicId) => {
  if (!publicId) return;
  
  try {
    await cloudinary.uploader.destroy(publicId, {
      invalidate: true,
      resource_type: 'auto',
    });
  } catch (error) {
    console.error('Error deleting from Cloudinary:', error.message);
    // Don't throw error for failed deletes to avoid blocking the main operation
  }
};

/**
 * Delete multiple files from Cloudinary
 * @param {string[]} publicIds - Array of public IDs to delete
 * @returns {Promise<void>}
 */
export const deleteMultipleFromCloudinary = async (publicIds) => {
  if (!publicIds || !publicIds.length) return;
  
  await Promise.all(publicIds.map(id => deleteFromCloudinary(id)));
};

export default cloudinary;
