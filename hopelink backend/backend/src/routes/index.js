import express from 'express';
import authRoutes from './auth.routes.js';
import organizationRoutes from './organization.routes.js';
import adminRoutes from './admin.routes.js';
import categoryRoutes from './category.routes.js';
import donationRoutes from './donation.routes.js';
import campaignRoutes from './campaign.routes.js';
import profileRoutes from './profile.routes.js';

const router = express.Router();

/**
 * @api {get} /api/health-check Health Check
 * @apiName HealthCheck
 * @apiGroup Health
 * @apiSuccess {String} status Status of the API
 * @apiSuccessExample {json} Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "status": "ok",
 *       "message": "API is running"
 *     }
 */
router.get('/health-check', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'API is running',
    timestamp: new Date().toISOString(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/organizations', organizationRoutes);
router.use('/admin', adminRoutes);
router.use('/categories', categoryRoutes);
router.use('/donations', donationRoutes);
router.use('/campaigns', campaignRoutes);
router.use('/user/profile', profileRoutes);

// E-commerce Routes
import productRoutes from './ecommerce/product.routes.js';
import cartRoutes from './ecommerce/cart.routes.js';
import orderRoutes from './ecommerce/order.routes.js';
import reviewRoutes from './ecommerce/review.routes.js';

router.use('/products', productRoutes);
router.use('/cart', cartRoutes);
router.use('/orders', orderRoutes);
router.use('/reviews', reviewRoutes);

export default router;
