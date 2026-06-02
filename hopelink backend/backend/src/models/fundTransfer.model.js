import mongoose from 'mongoose';

const fundTransferSchema = new mongoose.Schema(
  {
    // Transfer identification
    transferId: {
      type: String,
      unique: true,
      required: true,
      index: true,
    },
    
    // Organization receiving funds
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
      index: true,
    },
    
    // Amount details
    amount: {
      type: Number,
      required: true,
      min: 0,
      validate: {
        validator: function (v) {
          return v > 0;
        },
        message: 'Amount must be greater than 0',
      },
    },
    
    // Transfer method
    transferMethod: {
      type: String,
      enum: ['bank_transfer', 'stripe', 'khalti', 'cash', 'cheque'],
      default: 'bank_transfer',
      required: true,
    },
    
    // Bank details at time of transfer (snapshot)
    bankDetails: {
      bankName: String,
      accountHolderName: String,
      accountNumber: String,
      bankBranch: String,
    },
    
    // Status tracking
    status: {
      type: String,
      enum: ['initiated', 'processing', 'completed', 'failed', 'cancelled'],
      default: 'initiated',
      index: true,
    },
    
    // Transfer details
    reason: {
      type: String,
      required: true,
      maxlength: 500,
    },
    
    reference: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    
    // Audit information
    initiatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    
    completedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      sparse: true,
    },
    
    // Timestamps
    initiatedAt: {
      type: Date,
      default: Date.now,
    },
    
    completedAt: {
      type: Date,
      sparse: true,
    },
    
    expectedCompletionDate: {
      type: Date,
    },
    
    // Additional information
    notes: {
      type: String,
      maxlength: 1000,
    },
    
    transactionHash: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    
    failureReason: {
      type: String,
      sparse: true,
    },
    
    // Links to related records
    relatedCampaigns: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Campaign',
    }],
    
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Index for common queries
fundTransferSchema.index({ organization: 1, status: 1 });
fundTransferSchema.index({ initiatedAt: -1 });
fundTransferSchema.index({ status: 1, initiatedAt: -1 });

// Pre-save hook to generate transferId if not exists
fundTransferSchema.pre('save', async function (next) {
  if (!this.transferId) {
    const count = await mongoose.model('FundTransfer').countDocuments();
    const timestamp = Date.now().toString().slice(-6);
    this.transferId = `FT-${timestamp}-${count + 1}`;
  }
  next();
});

let FundTransfer;
if (mongoose.models.FundTransfer) {
  FundTransfer = mongoose.model('FundTransfer');
} else {
  FundTransfer = mongoose.model('FundTransfer', fundTransferSchema);
}

export default FundTransfer;
