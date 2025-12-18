import { StatusCodes } from 'http-status-codes';
import Category from '../models/category.model.js';
import { BadRequestError, NotFoundError } from '../errors/index.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../services/cloudinary.service.js';

// @desc    Create a new category
// @route   POST /api/v1/categories
// @access  Private (Admin)
export const createCategory = async (req, res) => {
  // Check if category with the same name already exists
  const existingCategory = await Category.findOne({ name: req.body.name });
  if (existingCategory) {
    throw new BadRequestError(`Category with name '${req.body.name}' already exists`);
  }

  // Handle file upload for icon and image
  if (req.files) {
    if (req.files.icon) {
      const result = await uploadToCloudinary(req.files.icon[0].path, 'categories');
      req.body.icon = result.secure_url;
    }
    if (req.files.image) {
      const result = await uploadToCloudinary(req.files.image[0].path, 'categories');
      req.body.image = result.secure_url;
    }
  }

  // Create category
  const category = await Category.create(req.body);

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: category,
  });
};

// @desc    Get all categories
// @route   GET /api/v1/categories
// @access  Public
export const getCategories = async (req, res) => {
  // Filtering
  const queryObj = { ...req.query };
  const excludeFields = ['page', 'sort', 'limit', 'fields'];
  excludeFields.forEach((el) => delete queryObj[el]);

  // Advanced filtering
  let queryStr = JSON.stringify(queryObj);
  queryStr = queryStr.replace(/\b(gte|gt|lte|lt)\b/g, (match) => `$${match}`);

  let query = Category.find(JSON.parse(queryStr));

  // Sorting
  if (req.query.sort) {
    const sortBy = req.query.sort.split(',').join(' ');
    query = query.sort(sortBy);
  } else {
    query = query.sort('name');
  }

  // Field limiting
  if (req.query.fields) {
    const fields = req.query.fields.split(',').join(' ');
    query = query.select(fields);
  } else {
    query = query.select('-__v');
  }

  // Pagination
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;
  const startIndex = (page - 1) * limit;
  const endIndex = page * limit;
  const total = await Category.countDocuments(JSON.parse(queryStr));

  query = query.skip(startIndex).limit(limit);

  // Execute query
  const categories = await query;

  // Pagination result
  const pagination = {};

  if (endIndex < total) {
    pagination.next = {
      page: page + 1,
      limit,
    };
  }

  if (startIndex > 0) {
    pagination.prev = {
      page: page - 1,
      limit,
    };
  }

  res.status(StatusCodes.OK).json({
    success: true,
    count: categories.length,
    pagination,
    data: categories,
  });
};

// @desc    Get single category
// @route   GET /api/v1/categories/:id
// @access  Public
export const getCategory = async (req, res) => {
  const category = await Category.findById(req.params.id);

  if (!category) {
    throw new NotFoundError(`No category with id ${req.params.id}`);
  }

  res.status(StatusCodes.OK).json({
    success: true,
    data: category,
  });
};

// @desc    Update category
// @route   PUT /api/v1/categories/:id
// @access  Private (Admin)
export const updateCategory = async (req, res) => {
  let category = await Category.findById(req.params.id);

  if (!category) {
    throw new NotFoundError(`No category with id ${req.params.id}`);
  }

  // Check if the new name is already taken by another category
  if (req.body.name && req.body.name !== category.name) {
    const existingCategory = await Category.findOne({ name: req.body.name });
    if (existingCategory) {
      throw new BadRequestError(`Category with name '${req.body.name}' already exists`);
    }
  }

  // Handle file upload for icon and image
  if (req.files) {
    if (req.files.icon) {
      // Delete old icon if exists
      if (category.icon) {
        const publicId = category.icon.split('/').pop().split('.')[0];
        await deleteFromCloudinary(publicId);
      }
      const result = await uploadToCloudinary(req.files.icon[0].path, 'categories');
      req.body.icon = result.secure_url;
    }
    if (req.files.image) {
      // Delete old image if exists
      if (category.image) {
        const publicId = category.image.split('/').pop().split('.')[0];
        await deleteFromCloudinary(publicId);
      }
      const result = await uploadToCloudinary(req.files.image[0].path, 'categories');
      req.body.image = result.secure_url;
    }
  }

  // Update category
  category = await Category.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: category,
  });
};

// @desc    Delete category
// @route   DELETE /api/v1/categories/:id
// @access  Private (Admin)
export const deleteCategory = async (req, res) => {
  const category = await Category.findById(req.params.id);

  if (!category) {
    throw new NotFoundError(`No category with id ${req.params.id}`);
  }

  // Check if category has subcategories
  const subcategories = await Category.find({ parent: category._id });
  if (subcategories.length > 0) {
    throw new BadRequestError('Cannot delete category with subcategories. Please delete subcategories first.');
  }

  // Check if category is being used by any campaigns
  const campaignsCount = await Campaign.countDocuments({ category: category._id });
  if (campaignsCount > 0) {
    throw new BadRequestError('Cannot delete category that is being used by campaigns');
  }

  // Delete icon and image from cloudinary
  if (category.icon) {
    const publicId = category.icon.split('/').pop().split('.')[0];
    await deleteFromCloudinary(publicId);
  }
  if (category.image) {
    const publicId = category.image.split('/').pop().split('.')[0];
    await deleteFromCloudinary(publicId);
  }

  // Delete category
  await category.remove();

  res.status(StatusCodes.OK).json({
    success: true,
    data: {},
  });
};

// @desc    Get subcategories
// @route   GET /api/v1/categories/:id/subcategories
// @access  Public
export const getSubcategories = async (req, res) => {
  const subcategories = await Category.find({ parent: req.params.id });

  res.status(StatusCodes.OK).json({
    success: true,
    count: subcategories.length,
    data: subcategories,
  });
};

// @desc    Get category tree
// @route   GET /api/v1/categories/tree
// @access  Public
export const getCategoryTree = async (req, res) => {
  const categories = await Category.find({ isActive: true });
  
  // Function to build category tree
  const buildTree = (categories, parentId = null) => {
    const result = [];
    
    categories
      .filter(category => 
        (parentId === null && !category.parent) || 
        (category.parent && category.parent.toString() === parentId)
      )
      .forEach(category => {
        const children = buildTree(categories, category._id.toString());
        
        result.push({
          _id: category._id,
          name: category.name,
          slug: category.slug,
          icon: category.icon,
          image: category.image,
          order: category.order,
          isActive: category.isActive,
          featured: category.featured,
          children: children.length > 0 ? children : undefined,
        });
      });
    
    // Sort by order if specified
    if (result.some(item => item.order !== undefined)) {
      result.sort((a, b) => (a.order || 0) - (b.order || 0));
    } else {
      // Otherwise sort by name
      result.sort((a, b) => a.name.localeCompare(b.name));
    }
    
    return result;
  };

  const categoryTree = buildTree(categories);

  res.status(StatusCodes.OK).json({
    success: true,
    count: categoryTree.length,
    data: categoryTree,
  });
};
