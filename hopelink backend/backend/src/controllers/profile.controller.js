import { StatusCodes } from 'http-status-codes';
import User from '../models/user.model.js';
import { BadRequestError, UnauthorizedError } from '../errors/index.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';

// @desc    Update user profile
// @route   PUT /api/v1/user/profile
// @access  Private (User role only)
// export const updateProfile = async (req, res) => {
//   // Check if user has the correct role
//   if (req.user.role !== 'user') {
//     throw new UnauthorizedError('Only regular users can update their profile');
//   }

//   const { name, phone, interest, status, gender, description, bio, location } = req.body;
  
//   // Create update object with only the fields that are provided
//   const updateFields = {};
//       if (name) updateData.name = name;

//   if (phone !== undefined) updateFields.phone = phone;
//   if (interest !== undefined) updateFields.interest = Array.isArray(interest) ? interest : [interest];
//   if (status !== undefined) updateFields.status = status;
//   if (gender !== undefined) updateFields.gender = gender;
//   if (description !== undefined) updateFields.description = description;
//   if (bio !== undefined) updateFields.bio = bio;
  
//   // Handle location updates
//   if (location) {
//     // Create a new location object with only the fields that are provided
//     const locationUpdate = {};
//     if (location.country !== undefined) locationUpdate.country = location.country;
//     if (location.city !== undefined) locationUpdate.city = location.city;
//     if (location.address !== undefined) locationUpdate.address = location.address;
    
//     // Set the entire location object at once
//     updateFields.location = locationUpdate;
//   }

//   // Update user
//   const user = await User.findByIdAndUpdate(
//     req.user._id,
//     { $set: updateFields },
//     { new: true, runValidators: true }
//   );

//   res.status(StatusCodes.OK).json({
//     success: true,
//     user: {
//       _id: user._id,
//       name: user.name,
//       email: user.email,
//       phone: user.phone,
//       interest: user.interest,
//       status: user.status,
//       gender: user.gender,
//       description: user.description,
//       profileImage: user.profileImage,
//       cv: user.cv,
//       role: user.role,
//       isVerified: user.isVerified,
//       isActive: user.isActive,
//       createdAt: user.createdAt,
//       updatedAt: user.updatedAt
//     }
//   });
// };
////--------------------------new code with name update
// In profile.controller.js
export const updateProfile = async (req, res) => {
  try {
   if (req.user.role !== 'user') {
    throw new UnauthorizedError('Only regular users can update their profile');
  }
    

    const { name, phone, interest, status, gender, description, bio, location } = req.body;
    
    // Create update object with only the fields that are provided
    const updateFields = {};
    
    // Add name to the update fields
    if (name !== undefined) updateFields.name = name;
    if (phone !== undefined) updateFields.phone = phone;
    if (interest !== undefined) updateFields.interest = Array.isArray(interest) ? interest : [interest];
    if (status !== undefined) updateFields.status = status;
    if (gender !== undefined) updateFields.gender = gender;
    if (description !== undefined) updateFields.description = description;
    if (bio !== undefined) updateFields.bio = bio;
    
    // Handle location updates
    if (location) {
      // Create a new location object with only the fields that are provided
      const locationUpdate = {};
      if (location.country !== undefined) locationUpdate.country = location.country;
      if (location.city !== undefined) locationUpdate.city = location.city;
      if (location.address !== undefined) locationUpdate.address = location.address;
      
      // Only add location to update if there are fields to update
      if (Object.keys(locationUpdate).length > 0) {
        updateFields.location = locationUpdate;
      }
    }

    // Update the user in the database
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateFields },
      { new: true, runValidators: true }
    ).select('-password -__v -resetPasswordToken -resetPasswordExpire');

    if (!updatedUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      user: updatedUser
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error updating profile',
      error: error.message 
    });
  }
};
// @desc    Upload profile photo
// @route   POST /api/v1/user/profile/photo
// @access  Private (User role only)
export const uploadProfilePhoto = async (req, res) => {
  if (req.user.role !== 'user') {
    throw new UnauthorizedError('Only regular users can upload profile photos');
  }

  if (!req.file) {
    throw new BadRequestError('Please upload a file');
  }

  // Upload to Cloudinary
  const result = await uploadToCloudinary(req.file, 'profile_photos');

  // Update user's profileImage
  const user = await User.findByIdAndUpdate(
    req.user._id,
    { profileImage: result.url },
    { new: true, runValidators: true }
  );

  res.status(StatusCodes.OK).json({
    success: true,
    profileImage: user.profileImage
  });
};

// @desc    Upload CV
// @route   POST /api/v1/user/profile/cv
// @access  Private (User role only)
export const uploadCV = async (req, res) => {
  if (req.user.role !== 'user') {
    throw new UnauthorizedError('Only regular users can upload CVs');
  }

  if (!req.file) {
    throw new BadRequestError('Please upload a PDF file');
  }

  // Upload to Cloudinary
  const result = await uploadToCloudinary(req.file, 'cvs');

  // Update user's CV
  const user = await User.findByIdAndUpdate(
    req.user._id,
    { cv: result.url },
    { new: true, runValidators: true }
  );

  res.status(StatusCodes.OK).json({
    success: true,
    cv: user.cv
  });
};
