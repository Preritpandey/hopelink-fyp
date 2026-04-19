import express from 'express';
import {
  addComment,
  getCommentsForPost,
  likePost,
  unlikePost,
} from '../controllers/postInteraction.controller.js';
import {
  authenticate,
  authenticateIfPresent,
} from '../middleware/auth.middleware.js';

const router = express.Router();

router.get('/:postId/comments', authenticateIfPresent, getCommentsForPost);
router.post('/:postId/like', authenticate, likePost);
router.delete('/:postId/unlike', authenticate, unlikePost);
router.post('/:postId/comments', authenticate, addComment);

export default router;
