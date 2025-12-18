import express from 'express';
import { authenticate, authorize } from '../middleware/auth.middleware.js';
import {
  getAllOrganizations,
  getPendingOrganizations,
  approveOrganization,
  rejectOrganization,
} from '../controllers/admin.controller.js';

const router = express.Router();

// Protect all routes with authentication and admin authorization
router.use(authenticate);
router.use(authorize('admin'));

// Organization management routes
router.get('/orgs', getAllOrganizations);
router.get('/orgs/pending', getPendingOrganizations);
router.put('/orgs/approve/:id', approveOrganization);
router.put('/orgs/reject/:id', rejectOrganization);

export default router;
