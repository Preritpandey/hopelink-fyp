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

    // For now assuming req.body contains orgId or we trust it for MVP/Admin
    // Ideally: productData.orgId = req.user.organizationId;
    
    const product = await ProductService.createProduct(productData, variants);
    res.status(StatusCodes.CREATED).json(product);
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

    // Handle New Image Uploads (Append to existing?)
    // Logic: If new images, upload and add to list. 
    // If client wants to replace, they might send a new list of images including old ones?
    // Mongoose update usually overwrites arrays if set.
    // Complex Update Strategy:
    // 1. If `images` in body is empty/undefined but files exist -> Append new files.
    // 2. If `images` in body exists (array of objects/urls) -> Keep those, add new files.
    
    // Simplest for now: Just add new files to whatever is in DB (via $push in service?) or retrieve, merge, save.
    // But ProductService.updateProduct uses findByIdAndUpdate which is simple.
    // Let's assume we append new images to the array passed in productUpdates (if any) or create one.
    
    if (req.files && req.files.length > 0) {
      const uploadResults = await handleMultipleFileUploads(req.files, 'hopelink/products');
      const newImages = uploadResults.map(img => ({
        url: img.url,
        publicId: img.public_id,
        altText: productUpdates.name || 'Product Image'
      }));
      
      // If productUpdates already has images (e.g. kept existing ones), push new ones.
      // Note: productUpdates.images might come as JSON string if multipart, need parsing too?
      // Usually arrays in multipart key[index] or just key.
      
      // We will rely on $push logic or getting current product.
      // To keep it stateless here: we will PUT 'images' into productUpdates using $each if Mongoose allowed,
      // but here we are passing object.
      // If we want to APPEND, we need to know existing. 
      // Decision: Let's fetch product OR assume this is a PATCH-like update where we just construct the array.
      // If ProductService treats `images` as replacement, we lose old ones unless sent.
      // Common pattern: Client sends `existingImages` (JSON) + new files.
      // Let's assume CLIENT sends everything they want to KEEP in `images` (parsed) + new files.

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

    const product = await ProductService.updateProduct(req.params.id, productUpdates, variants);
    res.status(StatusCodes.OK).json(product);
  } catch (error) {
    res.status(StatusCodes.BAD_REQUEST).json({ error: error.message });
  }
};

export const getProduct = async (req, res) => {
  try {
    const product = await ProductService.getProductById(req.params.id);
    if (!product) return res.status(StatusCodes.NOT_FOUND).json({ error: 'Product not found' });
    res.status(StatusCodes.OK).json(product);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const listProducts = async (req, res) => {
  try {
    const { page = 1, limit = 10, ...filters } = req.query;
    const result = await ProductService.listProducts(filters, parseInt(page), parseInt(limit));
    res.status(StatusCodes.OK).json(result);
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};

export const deleteProduct = async (req, res) => {
  try {
    await ProductService.softDeleteProduct(req.params.id);
    res.status(StatusCodes.OK).json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: error.message });
  }
};
