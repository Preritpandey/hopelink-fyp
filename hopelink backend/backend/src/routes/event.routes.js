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
  getEventApprovedVolunteers,
  getEventRejectedEnrollments,
  updateVolunteerStatus,
  getMyEnrollments,
  getEventsByOrganization,
  grantEventCreditHours,
} from '../controllers/event.controller.js';
import {
  authenticate,
  authenticateIfPresent,
  authorize,
} from '../middleware/auth.middleware.js';
import asyncHandler from '../utils/asyncHandler.js';
import { upload } from '../middleware/multer.js';

const router = express.Router();

// Public routes
router.get('/', authenticateIfPresent, asyncHandler(getEvents));
router.get(
  '/organization/:organizationId',
  authenticateIfPresent,
  asyncHandler(getEventsByOrganization),
);
router.get('/:id', authenticateIfPresent, asyncHandler(getEventById));

// Protected routes (require authentication)
router.use(authenticate);

// User enrollment routes
router.post('/:id/enroll', asyncHandler(enrollInEvent));
router.delete('/enrollments/:enrollmentId', asyncHandler(withdrawEnrollment));
router.get('/me/enrollments', asyncHandler(getMyEnrollments));

// Event management routes (organizers)
router.post(
  '/',
  authorize('user', 'organization'),
  upload.array('images', 5), // Max 5 images
  asyncHandler(createEvent)
);

router
  .route('/:id')
  .put(authorize('user', 'organization', 'admin'), asyncHandler(updateEvent))
  .delete(authorize('user', 'organization', 'admin'), asyncHandler(deleteEvent));

// Volunteer management routes (organizers)
router.get(
  '/:id/volunteers',
  authorize('user', 'organization', 'admin'),
  asyncHandler(getEventVolunteers)
);

router.get(
  '/:id/volunteers/approved',
  authorize('user', 'organization', 'admin'),
  asyncHandler(getEventApprovedVolunteers)
);

router.get(
  '/:id/volunteers/rejected',
  authorize('user', 'organization', 'admin'),
  asyncHandler(getEventRejectedEnrollments)
);

router.put(
  '/volunteers/:enrollmentId',
  authorize('user', 'organization', 'admin'),
  asyncHandler(updateVolunteerStatus)
);

router.patch(
  '/enrollments/:enrollmentId/credit-hours',
  authorize('user', 'organization', 'admin'),
  asyncHandler(grantEventCreditHours)
);

export default router;
