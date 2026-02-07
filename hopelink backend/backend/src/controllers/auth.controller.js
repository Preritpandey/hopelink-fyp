import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import User from '../models/user.model.js';
import Organization from '../models/organization.model.js';
import { StatusCodes } from 'http-status-codes';
import { BadRequestError, UnauthenticatedError, UnauthorizedError, NotFoundError } from '../errors/index.js';
import { sendEmail } from '../services/email.service.js';

// @desc    Register a new user or organization
// @route   POST /api/v1/auth/register
// @access  Public
export const register = async (req, res, next) => {
  const { name, email, password, role = 'user', adminToken, ...userDetails } = req.body;

  try {
    // Check if email already exists in either User or Organization
    const [existingUser, existingOrg] = await Promise.all([
      User.findOne({ email }).exec(),
      Organization.findOne({ officialEmail: email }).exec()
    ]);
    
    // If an organization with this email exists, block immediately
    if (existingOrg) {
      return next(new BadRequestError('Email already in use'));
    }

    // If a user with this email exists
    if (existingUser) {
      // If user is not verified yet, resend OTP and return a response that frontend can use
      if (!existingUser.isVerified) {
        // Generate new OTP and save without validation
        const otp = existingUser.generateVerificationOtp();
        await existingUser.save({ validateBeforeSave: false });

        // Try sending OTP email (non-blocking)
        try {
          await sendEmail({
            to: existingUser.email,
            subject: 'Your Email Verification OTP',
            template: 'otp-verification',
            context: {
              name: existingUser.name,
              otp: otp,
              expiresIn: '10 minutes',
              supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
            }
          });
        } catch (error) {
          console.error('Error sending OTP email (existing unverified user):', error);
        }

        // Issue a token so the user can verify directly
        const token = existingUser.generateAuthToken();

        // Do not leak password
        existingUser.password = undefined;

        return res.status(StatusCodes.OK).json({
          success: true,
          message: 'Account already exists but is not verified. A new OTP has been sent.',
          pendingVerification: true,
          token,
          user: existingUser,
        });
      }

      // If user is already verified, block registration
      return next(new BadRequestError('Email already in use'));
    }

    // Check if trying to register as admin without proper token
    if (role === 'admin') {
      if (!adminToken) {
        return next(new UnauthorizedError('Admin token is required for admin registration'));
      }
      
      if (adminToken !== process.env.ADMIN_CREATION_TOKEN) {
        return next(new UnauthorizedError('Invalid admin token'));
      }
      console.log('Admin token validation successful');
    }

  let user;
  
  // Handle organization registration
  if (role === 'organization') {
    // Create organization first
    const organization = await Organization.create({
      organizationName: name,
      officialEmail: email,
      ...userDetails
    });
    
    // Create user account for organization
    user = await User.create({
      name,
      email,
      password,
      role: 'organization',
      organization: organization._id,
      isVerified: false // Organizations need admin verification
    });
  } else {
    // Handle regular user or admin registration
    user = await User.create({
      name,
      email,
      password,
      role,
      ...userDetails,
      isVerified: role === 'admin' ? true : false // Admin accounts are auto-verified if created with token
    });
  }

  // Generate token
  const token = user.generateAuthToken();

  // Generate and send OTP for email verification
  const otp = user.generateVerificationOtp();
  await user.save({ validateBeforeSave: false });
  
  try {
    await sendEmail({
      to: user.email,
      subject: 'Your Email Verification OTP',
      template: 'otp-verification',
      context: {
        name: user.name,
        otp: otp,
        expiresIn: '10 minutes',
        supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
      }
    });
  } catch (error) {
    console.error('Error sending OTP email:', error);
    // Continue with registration even if email sending fails
  }

  // Remove password from output
  user.password = undefined;

  res.status(StatusCodes.CREATED).json({
    success: true,
    token,
      user,
    });
  } catch (error) {
    console.error('Registration error:', error);
    next(error);
  }
};

// @desc    Login user or organization
// @route   POST /api/v1/auth/login
// @access  Public
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check if email and password are provided
    if (!email || !password) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        error: 'Please provide both email and password'
      });
    }

    // Check if user exists
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(StatusCodes.UNAUTHORIZED).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Check if password is correct
    const isPasswordCorrect = await user.comparePassword(password);
    if (!isPasswordCorrect) {
      return res.status(StatusCodes.UNAUTHORIZED).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(StatusCodes.FORBIDDEN).json({
        success: false,
        error: 'Account is deactivated. Please contact support.'
      });
    }

    // Check if email is verified (for non-admin users)
    if (!user.isVerified && user.role !== 'admin') {
      return res.status(StatusCodes.FORBIDDEN).json({
        success: false,
        error: 'Please verify your email before logging in. Check your inbox for the verification link.'
      });
    }

    // Handle organization-specific checks
    if (user.role === 'organization') {
      const organization = await Organization.findById(user.organization);
      if (!organization) {
        return res.status(StatusCodes.NOT_FOUND).json({
          success: false,
          error: 'Organization not found. Please contact support.'
        });
      }

      // Check organization status
      if (organization.status === 'pending') {
        return res.status(StatusCodes.FORBIDDEN).json({
          success: false,
          error: 'Your organization registration is under review. Please wait for admin approval.'
        });
      } else if (organization.status === 'rejected') {
        const reason = organization.rejectionReason 
          ? `Your organization registration was rejected. Reason: ${organization.rejectionReason}` 
          : 'Your organization registration was rejected. Please contact support for more information.';
        return res.status(StatusCodes.FORBIDDEN).json({
          success: false,
          error: reason
        });
      } else if (organization.status === 'suspended') {
        return res.status(StatusCodes.FORBIDDEN).json({
          success: false,
          error: 'Your organization account has been suspended. Please contact support.'
        });
      }
    }

    // Generate token
    const token = user.generateAuthToken();

    // Remove password from output
    user.password = undefined;

    // Prepare user data for response
    const userData = {
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      isVerified: user.isVerified,
      isActive: user.isActive
    };

    // Add organization data if user is an organization
    if (user.role === 'organization') {
      const organization = await Organization.findById(user.organization)
        .select('organizationName organizationType status');
      
      if (organization) {
        userData.organization = {
          _id: organization._id,
          name: organization.organizationName,
          type: organization.organizationType,
          status: organization.status
        };
      }
    }

    res.status(StatusCodes.OK).json({
      success: true,
      token,
      user: userData
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'An error occurred during login. Please try again.'
    });
  }
};

// @desc    Get current logged in user
// @route   GET /api/v1/auth/me
// @access  Private
export const getMe = async (req, res) => {
  // The user is already attached to the request by the authenticate middleware
  const user = req.user;
  
  // Get organization details if user is an organization
  let organization = null;
  if (user.role === 'organization') {
    organization = await Organization.findById(user.organization);
  }

  // Prepare user data for response
  const userData = {
    _id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    interest: user.interest || [],
    status: user.status,
    gender: user.gender,
    description: user.description,
    bio: user.bio,
    location: user.location ? {
      country: user.location.country,
      city: user.location.city,
      address: user.location.address
    } : null,
    profileImage: user.profileImage,
    cv: user.cv,
    role: user.role,
    isVerified: user.isVerified,
    isActive: user.isActive,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };

  res.status(StatusCodes.OK).json({
    success: true,
    user: userData,
    organization: organization
  });
};

// @desc    Update user details
// @route   PUT /api/v1/auth/update-details
// @access  Private
export const updateDetails = async (req, res) => {
  const fieldsToUpdate = {
    name: req.body.name,
    email: req.body.email,
    phoneNumber: req.body.phoneNumber,
    address: req.body.address,
    gender: req.body.gender,
    age: req.body.age,
  };

  const user = await User.findByIdAndUpdate(req.user.userId, fieldsToUpdate, {
    new: true,
    runValidators: true,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    user,
  });
};

// @desc    Update password
// @route   PUT /api/v1/auth/update-password
// @access  Private
export const updatePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    throw new BadRequestError('Please provide current and new password');
  }

  const user = await User.findById(req.user.userId).select('+password');

  // Check current password
  const isMatch = await user.comparePassword(currentPassword);
  if (!isMatch) {
    throw new BadRequestError('Current password is incorrect');
  }

  user.password = newPassword;
  await user.save();

  // Send email notification
  try {
    await sendEmail({
      to: user.email,
      subject: 'Password Changed',
      html: 'Your password has been changed successfully.',
    });
  } catch (error) {
    console.error('Error sending password change email:', error);
  }

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Password updated successfully',
  });
};


// @desc    Forgot password
// @route   POST /api/v1/auth/forgot-password
// @access  Public
export const forgotPassword = async (req, res) => {
  const { email } = req.body;

  const user = await User.findOne({ email });

  if (!user) {
    throw new NotFoundError('No user found with this email');
  }

  // Generate OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpire = Date.now() + 10 * 60 * 1000; // 10 minutes

  // Save OTP to user
  user.otp = otp;
  user.otpExpire = otpExpire;
  await user.save({ validateBeforeSave: false });

  try {
    await sendEmail({
      to: user.email,
      subject: 'Password Reset OTP',
      template: 'password-reset-otp',
      context: {
        name: user.name,
        otp,
        supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
      }
    });

    res.status(StatusCodes.OK).json({
      success: true,
      message: 'OTP sent to your email',
      data: { email: user.email }
    });
  } catch (error) {
    console.error('Error sending OTP email:', error);
    user.otp = undefined;
    user.otpExpire = undefined;
    await user.save({ validateBeforeSave: false });

    throw new Error('Failed to send OTP email');
  }
};

// @desc    Reset password
// @route   PUT /api/v1/auth/reset-password/:resettoken
// @access  Public
export const resetPassword = async (req, res) => {
  // Get hashed token
  const resetPasswordToken = crypto
    .createHash('sha256')
    .update(req.params.resettoken)
    .digest('hex');

  const user = await User.findOne({
    resetPasswordToken,
    resetPasswordExpire: { $gt: Date.now() },
  });

  if (!user) {
    throw new BadRequestError('Invalid token or token has expired');
  }

  // Set new password
  user.password = req.body.password;
  user.resetPasswordToken = undefined;
  user.resetPasswordExpire = undefined;
  await user.save();

  // Send email notification
  try {
    await sendEmail({
      to: user.email,
      subject: 'Password Reset Confirmation',
      template: 'password-reset-confirmation',
      context: {
        name: user.name,
        loginUrl: `${process.env.FRONTEND_URL || `${req.protocol}://${req.get('host')}`}/login`,
        supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
      }
    });
  } catch (error) {
    console.error('Error sending password reset confirmation email:', error);
  }

  const token = user.generateAuthToken();

  res.status(StatusCodes.OK).json({
    success: true,
    token,
  });
};
// @desc    Reset password with OTP
// @access  Public
export const resetPasswordWithOtp = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    // Input validation
    if (!email || !otp || !newPassword) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        error: 'Validation Error',
        message: 'Email, OTP, and new password are required'
      });
    }

    // Find user with matching email and unexpired OTP
    const user = await User.findOne({
      email,
      otp,
      otpExpire: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        error: 'Invalid or expired OTP',
        message: 'The OTP you entered is invalid or has expired. Please request a new one.'
      });
    }

    // Set new password and clear OTP fields
    user.password = newPassword;
    user.otp = undefined;
    user.otpExpire = undefined;
    await user.save();

    // Send success response
    return res.status(StatusCodes.OK).json({
      success: true,
      message: 'Password has been reset successfully'
    });
  } catch (error) {
    console.error('Error in resetPasswordWithOtp:', error);
    
    // Handle known errors
    if (error.name === 'ValidationError') {
      return res.status(StatusCodes.BAD_REQUEST).json({
        success: false,
        error: 'Validation Error',
        message: error.message
      });
    }

    // Handle other errors
    return res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: 'Server Error',
      message: 'An error occurred while resetting your password. Please try again later.'
    });
  }
};

// @desc    Verify email
// @route   GET /api/v1/auth/verify-email/:verificationToken
// @desc    Resend verification email
// @route   POST /api/v1/auth/resend-verification
export const resendVerificationEmail = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    throw new BadRequestError('Please provide an email');
  }

  const user = await User.findOne({ email });

  if (!user) {
    throw new NotFoundError('No user found with this email');
  }

  if (user.isVerified) {
    throw new BadRequestError('Email is already verified');
  }

  // Generate verification token
  const verificationToken = user.getVerificationToken();
  await user.save({ validateBeforeSave: false });

  try {
    const verificationUrl = `${process.env.FRONTEND_URL}/verify-email/${verificationToken}`;
    
    await sendEmail({
      to: user.email,
      subject: 'Resend: Verify Your Email',
      html: `Please verify your email by clicking on this link: <a href="${verificationUrl}">Verify Email</a>`,
    });

    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Verification email sent',
    });
  } catch (error) {
    console.error('Error resending verification email:', error);
    user.verificationToken = undefined;
    user.verificationExpire = undefined;
    await user.save({ validateBeforeSave: false });

    throw new Error('Email could not be sent');
  }
};

// @desc    Verify email
export const verifyEmail = async (req, res) => {
  const { verificationToken } = req.params;

  // Hash token
  const hashedToken = crypto
    .createHash('sha256')
    .update(verificationToken)
    .digest('hex');

  const user = await User.findOne({
    emailVerificationToken: hashedToken,
    emailVerificationExpire: { $gt: Date.now() },
  });

  if (!user) {
    throw new BadRequestError('Invalid token or token has expired');
  }

  // Update user
  user.isEmailVerified = true;
  user.emailVerificationToken = undefined;
  user.emailVerificationExpire = undefined;
  await user.save();

  // Send welcome email
  try {
    await sendEmail({
      to: user.email,
      subject: 'Welcome to Our Platform',
      text: 'Thank you for verifying your email address. Your account is now active!',
    });
  } catch (error) {
    console.error('Error sending welcome email:', error);
  }

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Email verified successfully',
  });
};

// @desc    Verify OTP
// @route   POST /api/v1/auth/verify-otp
// @access  Public
export const verifyOtp = async (req, res, next) => {
  try {
    console.log('OTP Verification Request:', {
      body: req.body,
      headers: { 
        authorization: req.headers.authorization ? 'Bearer [token]' : 'Not provided',
        'content-type': req.headers['content-type']
      }
    });

    const { otp, email } = req.body;
    
    if (!otp) {
      throw new BadRequestError('Please provide OTP');
    }

    let user;
    const authHeader = req.headers.authorization;

    // First, try to find user by email if provided
    if (email) {
      console.log('Looking up user by email:', email);
      user = await User.findOne({ email });
      
      if (!user) {
        console.error('No user found with email:', email);
        throw new UnauthorizedError('No account found with this email. Please register first.');
      }
    } 
    // If no email but we have a token, try to get user from token
    else if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const token = authHeader.split(' ')[1];
        console.log('Verifying JWT token...');
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        console.log('Decoded token:', decoded);
        
        // Try to find user by ID from token
        if (decoded.userId) {
          console.log('Looking up user by ID from token:', decoded.userId);
          user = await User.findById(decoded.userId);
        }
        
        if (!user) {
          console.error('No user found with ID from token');
          throw new UnauthorizedError('Invalid or expired session. Please log in again.');
        }
      } catch (tokenError) {
        console.error('Token verification failed:', tokenError);
        if (tokenError.name === 'TokenExpiredError') {
          throw new UnauthorizedError('Your session has expired. Please log in again.');
        }
        throw new UnauthorizedError('Invalid authentication token');
      }
    } else {
      throw new BadRequestError('Please provide either an email or an authentication token');
    }
    
    // At this point, we should have a user
    console.log('Found user:', {
      id: user._id,
      email: user.email,
      isVerified: user.isVerified
    });
    
    // Verify OTP exists and is not expired
    if (!user.otp) {
      console.error('No OTP found for user:', user.email);
      throw new BadRequestError('No verification code found. Please request a new one.');
    }
    
    if (!user.otpExpire || new Date() > user.otpExpire) {
      console.error('OTP expired for user:', user.email);
      throw new BadRequestError('Verification code has expired. Please request a new one.');
    }
    
    // Verify OTP is valid
    console.log('Verifying OTP...');
    const isOtpValid = user.verifyOtp(otp);
    
    if (!isOtpValid) {
      console.error('Invalid OTP provided for user:', user.email);
      throw new UnauthorizedError('Invalid verification code. Please try again.');
    }

    // Update user
    user.isVerified = true;
    user.otp = undefined;
    user.otpExpire = undefined;
    await user.save();

    // Generate new token
    const token = user.generateAuthToken();

    // Send welcome email (best-effort)
    try {
      await sendEmail({
        to: user.email,
        subject: 'Welcome to Our Platform',
        template: 'welcome-email',
        context: {
          name: user.name,
          loginUrl: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`,
          supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
        }
      });
    } catch (error) {
      console.error('Error sending welcome email:', error);
    }

    return res.status(StatusCodes.OK).json({
      success: true,
      message: 'Email verified successfully',
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified,
        isActive: user.isActive
      }
    });
  } catch (error) {
    console.error('OTP Verification Error:', error);
    if (error.name === 'JsonWebTokenError') {
      throw new UnauthorizedError('Invalid token. Please try logging in again.');
    } else if (error.name === 'TokenExpiredError') {
      throw new UnauthorizedError('Token has expired. Please try again.');
    }
    throw error; // Re-throw other errors
  }
};

// @desc    Resend OTP
// @route   POST /api/v1/auth/resend-otp
// @access  Public
export const resendOtp = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    throw new BadRequestError('Please provide an email address');
  }

  const user = await User.findOne({ email });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  if (user.isVerified) {
    throw new BadRequestError('Email is already verified');
  }

  // Generate new OTP
  const otp = user.generateVerificationOtp();
  await user.save({ validateBeforeSave: false });

  // Send OTP email
  try {
    await sendEmail({
      to: user.email,
      subject: 'Your New Verification OTP',
      template: 'otp-verification',
      context: {
        name: user.name,
        otp: otp,
        expiresIn: '10 minutes',
        supportEmail: process.env.SUPPORT_EMAIL || 'support@hopelink.com'
      }
    });
  } catch (error) {
    console.error('Error sending OTP email:', error);
    throw new Error('Failed to send OTP. Please try again later.');
  }

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'New OTP has been sent to your email',
    email: user.email // Return masked email for user confirmation
  });
};

// @desc    Logout user / clear cookie

export const logout = async (req, res) => {
  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Logged out successfully',
  });
};
