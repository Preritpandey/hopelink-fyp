import mongoose from 'mongoose';

// Import models
import User from './user.model.js';
import Organization from './organization.model.js';
import Campaign from './campaign.model.js';
import Category from './category.model.js';
import Donation from './donation.model.js';
import Event from './event.model.js';
import VolunteerEnrollment from './volunteerEnrollment.model.js';
import VolunteerJob from './volunteerJob.model.js';
import VolunteerApplication from './volunteerApplication.model.js';
import VolunteerCertification from './volunteerCertification.model.js';

// E-commerce Models
import Product from './ecommerce/product.model.js';
import ProductVariant from './ecommerce/productVariant.model.js';
import Cart from './ecommerce/cart.model.js';
import Order from './ecommerce/order.model.js';
import Review from './ecommerce/review.model.js';

// Register models with Mongoose if they don't exist
const models = {
  User: mongoose.models.User || User,
  Organization: mongoose.models.Organization || Organization,
  Campaign: mongoose.models.Campaign || Campaign,
  Category: mongoose.models.Category || Category,
  Donation: mongoose.models.Donation || Donation,
  Event: mongoose.models.Event || Event,
  VolunteerEnrollment: mongoose.models.VolunteerEnrollment || VolunteerEnrollment,
  VolunteerJob: mongoose.models.VolunteerJob || VolunteerJob,
  VolunteerApplication:
    mongoose.models.VolunteerApplication || VolunteerApplication,
  VolunteerCertification:
    mongoose.models.VolunteerCertification || VolunteerCertification,
  Product: mongoose.models.Product || Product,
  ProductVariant: mongoose.models.ProductVariant || ProductVariant,
  Cart: mongoose.models.Cart || Cart,
  Order: mongoose.models.Order || Order,
  Review: mongoose.models.Review || Review
};

// Export models for use in controllers
export {
  User,
  Organization,
  Campaign,
  Category,
  Donation,
  Event,
  VolunteerEnrollment,
  VolunteerJob,
  VolunteerApplication,
  VolunteerCertification,
  Product,
  ProductVariant,
  Cart,
  Order,
  Review
};

export default models;
