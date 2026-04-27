import express from 'express';
import { authenticate } from '../middleware/auth.middleware.js';
import {
  getSavedCauses,
  saveCause,
  unsaveCause,
} from '../controllers/savedCause.controller.js';

const router = express.Router();

router.use(authenticate);

router.get('/', getSavedCauses);
router.post('/:postId', saveCause);
router.delete('/:postId', unsaveCause);

export default router;
