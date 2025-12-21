// Import and export all models to ensure they're registered
import User from './user.model.js';
import Organization from './organization.model.js';
import Campaign from './campaign.model.js';
import Category from './category.model.js';
import Donation from './donation.model.js';
import Event from './event.model.js';

// Export models for use in controllers
export { User, Organization, Campaign, Category, Donation, Event };

// Also ensure they're available on mongoose.models
export default {
  User,
  Organization,
  Campaign,
  Category,
  Donation,
  Event
};
