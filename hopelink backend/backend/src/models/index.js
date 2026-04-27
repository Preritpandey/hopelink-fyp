import mongoose from 'mongoose';

// Import models
import User from './user.model.js';
import Organization from './organization.model.js';
import Campaign from './campaign.model.js';
import Category from './category.model.js';
import Donation from './donation.model.js';
import Event from './event.model.js';
import CampaignReport from './campaignReport.model.js';
import EssentialRequest from './essentialRequest.model.js';
import DonationCommitment from './donationCommitment.model.js';
import VolunteerEnrollment from './volunteerEnrollment.model.js';
import VolunteerJob from './volunteerJob.model.js';
import VolunteerApplication from './volunteerApplication.model.js';
import VolunteerCertification from './volunteerCertification.model.js';
import UserActivity from './userActivity.model.js';
import PostLike from './postLike.model.js';
import PostComment from './postComment.model.js';
import SavedCause from './savedCause.model.js';

// E-commerce Models
import Product from './ecommerce/product.model.js';
import ProductVariant from './ecommerce/productVariant.model.js';
import Cart from './ecommerce/cart.model.js';
import Order from './ecommerce/order.model.js';
import Review from './ecommerce/review.model.js';
import Wishlist from './ecommerce/wishlist.model.js';

// Register models with Mongoose if they don't exist
const models = {
  User: mongoose.models.User || User,
  Organization: mongoose.models.Organization || Organization,
  Campaign: mongoose.models.Campaign || Campaign,
  Category: mongoose.models.Category || Category,
  Donation: mongoose.models.Donation || Donation,
  Event: mongoose.models.Event || Event,
  CampaignReport: mongoose.models.CampaignReport || CampaignReport,
  EssentialRequest: mongoose.models.EssentialRequest || EssentialRequest,
  DonationCommitment:
    mongoose.models.DonationCommitment || DonationCommitment,
  VolunteerEnrollment: mongoose.models.VolunteerEnrollment || VolunteerEnrollment,
  VolunteerJob: mongoose.models.VolunteerJob || VolunteerJob,
  VolunteerApplication:
    mongoose.models.VolunteerApplication || VolunteerApplication,
  VolunteerCertification:
    mongoose.models.VolunteerCertification || VolunteerCertification,
  UserActivity: mongoose.models.UserActivity || UserActivity,
  PostLike: mongoose.models.PostLike || PostLike,
  PostComment: mongoose.models.PostComment || PostComment,
  SavedCause: mongoose.models.SavedCause || SavedCause,
  Product: mongoose.models.Product || Product,
  ProductVariant: mongoose.models.ProductVariant || ProductVariant,
  Cart: mongoose.models.Cart || Cart,
  Order: mongoose.models.Order || Order,
  Review: mongoose.models.Review || Review,
  Wishlist: mongoose.models.Wishlist || Wishlist
};

// Export models for use in controllers
export {
  User,
  Organization,
  Campaign,
  Category,
  Donation,
  Event,
  CampaignReport,
  EssentialRequest,
  DonationCommitment,
  VolunteerEnrollment,
  VolunteerJob,
  VolunteerApplication,
  VolunteerCertification,
  UserActivity,
  PostLike,
  PostComment,
  SavedCause,
  Product,
  ProductVariant,
  Cart,
  Order,
  Review,
  Wishlist
};

export default models;
