import Review from '../../models/ecommerce/review.model.js';
import Order from '../../models/ecommerce/order.model.js';

export const addReview = async (userId, productId, rating, reviewText) => {
    // Check if user purchased the product
    const hasPurchased = await Order.findOne({
        userId,
        items: { $elemMatch: { productId: productId } },
        status: { $in: ['delivered', 'shipped', 'paid'] } // Allow revies if paid/shipped? Usually delivered. Let's allowing paid for simplicity as per MVP.
    });

    if (!hasPurchased) {
        throw new Error('You can only review products you have purchased.');
    }

    // Create review
    // The previous index handles uniqueness, so this will throw if duplicate
    const review = await Review.create({
        userId,
        productId,
        rating,
        reviewText
    });
    
    return review;
};

export const getProductReviews = async (productId) => {
    return await Review.find({ productId }).populate('userId', 'name profilePicture'); // Assuming User model has these fields
};
