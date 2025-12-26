import Product from '../../models/ecommerce/product.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Category from '../../models/category.model.js';
import Organization from '../../models/organization.model.js';

export const createProduct = async (productData, variantsData) => {
  // Transaction removed for standalone MongoDB compatibility
  try {
    const product = new Product(productData);
    await product.save();

    if (variantsData && variantsData.length > 0) {
      const variants = variantsData.map(v => ({
        ...v,
        productId: product._id
      }));
      await ProductVariant.insertMany(variants);
    }

    return product;
  } catch (error) {
    throw error;
  }
};

export const updateProduct = async (productId, productUpdates, variantsUpdates) => {
  // Transaction removed for standalone MongoDB compatibility
  try {
    const product = await Product.findByIdAndUpdate(productId, productUpdates, { new: true });
    
    // Handle variants if provided
    if (variantsUpdates) {
       for (const v of variantsUpdates) {
         if (v._id) {
            await ProductVariant.findByIdAndUpdate(v._id, v);
         } else {
            v.productId = productId;
            await new ProductVariant(v).save();
         }
       }
    }

    return product;
  } catch (error) {
    throw error;
  }
};



// ... (existing imports)

export const getProductById = async (id) => {
  return await Product.findById(id)
    .populate({
      path: 'variants',
      model: ProductVariant
    })
    .populate({
      path: 'category',
      model: Category
    })
    .populate({
      path: 'orgId',
      model: Organization,
      select: 'organizationName'
    });
};

// export const listProducts = async (filters, page = 1, limit = 10) => {
//   const skip = (page - 1) * limit;
//   const query = { isDeleted: false, ...filters };
  
//   const products = await Product.find(query)
//     .populate({
//       path: 'variants',
//       model: ProductVariant
//     })
//     .populate({
//       path: 'orgId',
//       model: Organization,
//       select: 'organizationName'
//     })
//     .skip(skip)
//     .limit(limit)
//     .sort({ createdAt: -1 });
    
//   const total = await Product.countDocuments(query);
  
//   return { products, total, totalPages: Math.ceil(total / limit) };
// };

export const listProducts = async (filters, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;
  const query = { isDeleted: false, ...filters };
  
  const products = await Product.find(query)
    .populate({
      path: 'variants',
      model: ProductVariant,
      match: { isDeleted: false }
    })
    .populate({
      path: 'orgId',
      model: Organization,
      select: 'organizationName'
    })
    .populate({
      path: 'category',
      model: Category,
      select: 'name'
    })
    .skip(skip)
    .limit(limit)
    .sort({ createdAt: -1 })
    .lean(); // Add lean() for better performance
    
  const total = await Product.countDocuments(query);
  
  return { 
    products: products.map(product => {
      // Ensure organization data is properly structured
      if (product.orgId) {
        product.organization = {
          id: product.orgId._id,
          name: product.orgId.organizationName
        };
        delete product.orgId;
      }
      return product;
    }), 
    total, 
    totalPages: Math.ceil(total / limit) 
  };
};

export const softDeleteProduct = async (id) => {
  return await Product.findByIdAndUpdate(id, { isDeleted: true }, { new: true });
};
