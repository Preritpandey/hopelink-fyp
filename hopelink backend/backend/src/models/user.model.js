import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide a name'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Please provide an email'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/,
        'Please provide a valid email',
      ],
    },
    password: {
      type: String,
      required: [true, 'Please provide a password'],
      minlength: 6,
      select: false,
    },
    phoneNumber: {
      type: String,
      trim: true,
    },
    role: {
      type: String,
      enum: ['user', 'organization', 'admin'],
      default: 'user',
    },
    organization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
    },
    gender: {
      type: String,
      enum: ['male', 'female', 'other', null],
      default: null,
    },
    phone: {
      type: String,
      trim: true,
    },
    interest: [{
      type: String,
      trim: true
    }],
    status: {
      type: String,
      enum: ['student', 'employed', 'not working', null],
      default: null,
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, 'Description cannot be more than 500 characters']
    },
    bio: {
      type: String,
      trim: true,
      maxlength: [1000, 'Bio cannot be more than 1000 characters']
    },
    skills: [{
      type: String,
      trim: true
    }],
    certifications: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'VolunteerCertification',
    }],
    totalVolunteerHours: {
      type: Number,
      default: 0,
      min: 0,
    },
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },
    location: {
      country: {
        type: String,
        trim: true
      },
      city: {
        type: String,
        trim: true
      },
      address: {
        type: String,
        trim: true
      }
    },
    profileImage: {
      type: String,
      default: ''
    },
    cv: {
      type: String,
      default: ''
    },
    age: {
      type: Number,
      min: 1,
      default: '',
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    emailVerificationToken: String,
    emailVerificationExpire: Date,
    otp: String,
    otpExpire: Date,
    resetPasswordToken: String,
    resetPasswordExpire: Date,
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Method to compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Generate OTP for email verification
userSchema.methods.generateVerificationOtp = function() {
  // Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Hash OTP before saving to DB
  this.otp = crypto.createHash('sha256').update(otp).digest('hex');
  
  // Set OTP expiration (10 minutes)
  this.otpExpire = Date.now() + 10 * 60 * 1000;
  
  return otp;
};

// Verify OTP
userSchema.methods.verifyOtp = function(enteredOtp) {
  const hashedOtp = crypto.createHash('sha256').update(enteredOtp).digest('hex');
  return this.otp === hashedOtp && this.otpExpire > Date.now();
};

// Generate password reset token
userSchema.methods.getResetPasswordToken = function () {
  // Generate token
  const resetToken = crypto.randomBytes(20).toString('hex');

  // Hash and set to resetPasswordToken field
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  // Set expire (10 minutes)
  this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

  return resetToken;
};

// Method to generate JWT token
userSchema.methods.generateAuthToken = function () {
  return jwt.sign(
    { 
      userId: this._id, 
      role: this.role,
      organization: this.organization || null
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '30d' }
  );
};

// Check if the model has already been registered
let User;
if (mongoose.models.User) {
  User = mongoose.model('User');
} else {
  User = mongoose.model('User', userSchema);
}

export default User;
