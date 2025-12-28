import express from 'express';
import {
  createEvent,
  getEvents,
  getEventById,
  updateEvent,
  deleteEvent,
  enrollInEvent,
  withdrawEnrollment,
  getEventVolunteers,
  updateVolunteerStatus,
  getMyEnrollments,
} from '../controllers/event.controller.js';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import { upload } from '../middleware/multer.js';

const router = express.Router();

// Public routes
router.get('/', getEvents);
router.get('/:id', getEventById);

// Protected routes (require authentication)
router.use(authenticate);

// User enrollment routes
router.post('/:id/enroll', enrollInEvent);
router.delete('/enrollments/:enrollmentId', withdrawEnrollment);
router.get('/me/enrollments', getMyEnrollments);

// Event management routes (organizers)
router.post(
  '/',
  authorize('user', 'organization'),
  upload.array('images', 5), // Max 5 images
  createEvent
);

router
  .route('/:id')
  .put(authorize('user', 'organization', 'admin'), updateEvent)
  .delete(authorize('user', 'organization', 'admin'), deleteEvent);

// Volunteer management routes (organizers)
router.get(
  '/:id/volunteers',
  authorize('user', 'organization', 'admin'),
  getEventVolunteers
);

router.put(
  '/volunteers/:enrollmentId',
  authorize('user', 'organization', 'admin'),
  updateVolunteerStatus
);

export default router;
