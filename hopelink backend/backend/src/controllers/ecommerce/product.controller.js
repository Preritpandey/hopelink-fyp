import * as ProductService from '../../services/ecommerce/product.service.js';
import { handleMultipleFileUploads } from '../../services/cloudinary.service.js';
import { StatusCodes } from 'http-status-codes';

export const createProduct = async (req, res) => {
  try {
    let { variants, ...productData } = req.body;

    // Parse variants if sent as string (multipart/form-data)
    if (typeof variants === 'string') {
      try {
        variants = JSON.parse(variants);
      } catch (e) {
        return res.status(StatusCodes.BAD_REQUEST).json({ error: 'Invalid variants JSON format' });
      }
    }

    // Handle Image Uploads
    if (req.files && req.files.length > 0) {
      const uploadResults = await handleMultipleFileUploads(req.files, 'hopelink/products');
      const newImages = uploadResults.map(img => ({
        url: img.url,
        publicId: img.public_id,
        altText: productData.name // Default alt text
      }));
      productData.images = newImages; // Assign to product data
    }

    if (req.user.role === 'organization') {
      productData.orgId = req.user.organization;
    }

    productData.beneficiaryDescription =
      productData.beneficiaryDescription || productData.description;
    
    const product = await ProductService.createProduct(
      productData,
      variants,
      req.user,
    );
    res.status(StatusCodes.CREATED).json({
      success: true,
      data: product,
    });
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const updateProduct = async (req, res) => {
  try {
    let { variants, ...productUpdates } = req.body;

    // Parse variants if needed
    if (typeof variants === 'string') {
      try {
        variants = JSON.parse(variants);
      } catch (e) {
        return res.status(StatusCodes.BAD_REQUEST).json({ error: 'Invalid variants JSON format' });
      }
    }

    
    if (req.files && req.files.length > 0) {
      const uploadResults = await handleMultipleFileUploads(req.files, 'hopelink/products');
      const newImages = uploadResults.map(img => ({
        url: img.url,
        publicId: img.public_id,
        altText: productUpdates.name || 'Product Image'
      }));
      
    
      if (productUpdates.images && typeof productUpdates.images === 'string') {
          productUpdates.images = JSON.parse(productUpdates.images);
      }
      
      const currentImages = Array.isArray(productUpdates.images) ? productUpdates.images : [];
      productUpdates.images = [...currentImages, ...newImages];
    } else {
       // If no new files, but images field exists (reordering/deleting), parse it
       if (productUpdates.images && typeof productUpdates.images === 'string') {
          productUpdates.images = JSON.parse(productUpdates.images);
      }
    }

    productUpdates.beneficiaryDescription =
      productUpdates.beneficiaryDescription || productUpdates.description;

    const product = await ProductService.updateProduct(
      req.params.id,
      productUpdates,
      variants,
      req.user,
    );
    res.status(StatusCodes.OK).json({
      success: true,
      data: product,
    });
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const getProduct = async (req, res) => {
  try {
    const product = await ProductService.getProductById(req.params.id);
    if (!product) return res.status(StatusCodes.NOT_FOUND).json({ error: 'Product not found' });
    res.status(StatusCodes.OK).json({
      success: true,
      data: product,
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const listProducts = async (req, res) => {
  try {
    const { page = 1, limit = 10, ...filters } = req.query;
    const result = await ProductService.listProducts(filters, parseInt(page), parseInt(limit));
    res.status(StatusCodes.OK).json({
      success: true,
      ...result,
    });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const deleteProduct = async (req, res) => {
  try {
    await ProductService.softDeleteProduct(req.params.id, req.user);
    res.status(StatusCodes.OK).json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};
