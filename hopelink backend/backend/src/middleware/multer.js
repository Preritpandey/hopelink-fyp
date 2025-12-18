import multer from 'multer';
import { BadRequestError } from '../errors/index.js';

// Configure storage
const storage = multer.memoryStorage();

// File filter function factory for multer
const fileFilter = (fileType) => (req, file, cb) => {
  if (fileType === 'image') {
    if (file.mimetype && file.mimetype.startsWith('image/')) {
      return cb(null, true);
    }
    return cb(new BadRequestError('Please upload an image file (jpg, jpeg, png)'), false);
  }

  if (fileType === 'pdf') {
    // keeping this slightly tolerant and accept common pdf mimetypes to prevent issues for testing in postman.
    if (file.mimetype === 'application/pdf' || (file.mimetype && file.mimetype.startsWith('application/pdf'))) {
      return cb(null, true);
    }
    return cb(new BadRequestError('Please upload a PDF file'), false);
  }

  return cb(new BadRequestError('Unsupported file type'), false);
};

// Helpers to create typed uploaders with proper fileFilter
const createUploader = ({ maxSizeMB, fileType }) =>
  multer({
    storage,
    limits: { fileSize: maxSizeMB * 1024 * 1024 },
    fileFilter: fileFilter(fileType),
  });

// Preconfigured uploaders
const uploadImage = createUploader({ maxSizeMB: 5, fileType: 'image' });
const uploadPdf = createUploader({ maxSizeMB: 10, fileType: 'pdf' });

// Backward-compatible generic upload (no type filter, 10MB)
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB default limit
});

// File size limit middleware (kept for other routes if needed)
const fileSizeLimit = (mb) => (req, res, next) => {
  const limiter = multer({
    storage,
    limits: { fileSize: mb * 1024 * 1024 },
  }).single(Object.keys(req.files || {}).length ? 'file' : 'file');

  limiter(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return next(new BadRequestError(`File too large. Maximum size is ${mb}MB`));
      }
      return next(new BadRequestError(err.message));
    }
    if (err) return next(err);
    return next();
  });
};

export { upload, uploadImage, uploadPdf, fileFilter, fileSizeLimit };
