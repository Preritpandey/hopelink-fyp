import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Uploads a file (buffer or temp path) to Cloudinary
 * Supports multer memoryStorage by using data URI when buffer is provided.
 * @param {Object|string} fileOrPath - Multer file object (with buffer) or a string path
 * @param {string} folder - Cloudinary folder
 * @param {Object} options - Additional cloudinary options
 * @returns {Promise<Object>} - Normalized upload result
 */
export const uploadToCloudinary = async (fileOrPath, folder = 'hopelink', options = {}) => {
  try {
    let uploadSource;

    if (typeof fileOrPath === 'string') {
      uploadSource = fileOrPath;
    } else if (fileOrPath && fileOrPath.buffer && fileOrPath.mimetype) {
      // Build a data URI from the buffer (avoids needing a tmp file)
      const base64 = fileOrPath.buffer.toString('base64');
      uploadSource = `data:${fileOrPath.mimetype};base64,${base64}`;
    } else if (fileOrPath && fileOrPath.path) {
      uploadSource = fileOrPath.path;
    } else {
      throw new Error('Invalid file input for Cloudinary upload');
    }

    const result = await cloudinary.uploader.upload(uploadSource, {
      folder,
      resource_type: 'auto',
      ...options,
    });

    // Clean up only if a real path string exists
    if (typeof uploadSource === 'string' && fs.existsSync(uploadSource)) {
      try { fs.unlinkSync(uploadSource); } catch (_) {}
    }

    return {
      public_id: result.public_id,
      url: result.secure_url,
      format: result.format,
      width: result.width,
      height: result.height,
      bytes: result.bytes,
    };
  } catch (error) {
    console.error('Error uploading to Cloudinary:', error);
    throw new Error('Failed to upload file to Cloudinary');
  }
};





/**
 * Deletes a file from Cloudinary
 * @param {string} publicId - Public ID of the file to delete
 * @param {Object} options - Additional options for the deletion
 * @returns {Promise<Object>} - Deletion result from Cloudinary
 */
export const deleteFromCloudinary = async (publicId, options = {}) => {
  try {
    if (!publicId) return null;
    
    const result = await cloudinary.uploader.destroy(publicId, {
      invalidate: true, // Invalidate CDN cache
      ...options,
    });

    return result;
  } catch (error) {
    console.error('Error deleting from Cloudinary:', error);
    throw new Error('Failed to delete file from Cloudinary');
  }
};

/**
 * Handles file upload from a form data field
 * Works with memoryStorage by passing the file object directly
 */
export const handleFileUpload = async (file, folder = 'hopelink') => {
  if (!file) return null;
  try {
    return await uploadToCloudinary(file, folder);
  } catch (error) {
    console.error('Error handling file upload:', error);
    throw error;
  }
};

/**
 * Handles multiple file uploads
 * @param {Array} files - Array of file objects from multer
 * @param {string} folder - Folder in Cloudinary to upload to
 * @returns {Promise<Array>} - Array of upload results
 */
export const handleMultipleFileUploads = async (files = [], folder = 'hopelink') => {
  if (!files.length) return [];

  try {
    const uploadPromises = files.map(file => handleFileUpload(file, folder));
    return await Promise.all(uploadPromises);
  } catch (error) {
    console.error('Error handling multiple file uploads:', error);
    throw error;
  }
};

export default cloudinary;
