import express from 'express';
import { deleteComment } from '../controllers/postInteraction.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

router.delete('/:commentId', authenticate, deleteComment);

export default router;
