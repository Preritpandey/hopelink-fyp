import mongoose from "mongoose";

const fileSchema = new mongoose.Schema({
  url: { type: String, required: true },
  publicId: { type: String },
  originalName: { type: String },
  mimeType: { type: String },
  size: { type: Number },
  uploadedAt: { type: Date, default: Date.now },
});

const bankDetailsSchema = new mongoose.Schema({
  bankName: { type: String, required: true },
  accountHolderName: { type: String, required: true },
  accountNumber: { type: String, required: true },
  bankBranch: { type: String },
  voidCheque: fileSchema, // nested document
});

const socialMediaSchema = new mongoose.Schema({
  facebook: String,
  instagram: String,
  linkedin: String,
});

const organizationSchema = new mongoose.Schema(
  {
    organizationName: { type: String, required: true },
    organizationType: { type: String, required: true },
    registrationNumber: { type: String, required: true },
    dateOfRegistration: { type: Date },
    officialEmail: { type: String },
    officialPhone: { type: String },
    website: { type: String },
    country: { type: String },
    city: { type: String },
    registeredAddress: { type: String },
    representativeName: { type: String },
    designation: { type: String },
    primaryCause: { type: String },
    missionStatement: { type: String },
    activeMembers: { type: Number, required: true },
    recentCampaigns: [{ type: String }],
    logo: fileSchema,
    registrationCertificate: fileSchema,
    taxCertificate: fileSchema,
    constitutionFile: fileSchema,
    proofOfAddress: fileSchema,
    bankDetails: bankDetailsSchema,
    socialMedia: socialMediaSchema,
    status: { 
      type: String, 
      default: "pending",
      enum: ['pending', 'approved', 'rejected', 'suspended']
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false
    },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false
    },
    approvedAt: {
      type: Date,
      required: false
    },
    rejectionReason: {
      type: String,
      required: false
    },
    isVerified: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Check if the model has already been registered
let Organization;
if (mongoose.models.Organization) {
  Organization = mongoose.model('Organization');
} else {
  Organization = mongoose.model('Organization', organizationSchema);
}

export default Organization;
