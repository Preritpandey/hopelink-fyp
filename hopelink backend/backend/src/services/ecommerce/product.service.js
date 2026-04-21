import Product from '../../models/ecommerce/product.model.js';
import ProductVariant from '../../models/ecommerce/productVariant.model.js';
import Category from '../../models/category.model.js';
import Organization from '../../models/organization.model.js';
import { BadRequestError, ForbiddenError, NotFoundError } from '../../errors/index.js';

const normalizeVariantSummary = (variantsData = [], fallback = {}) => {
  if (!Array.isArray(variantsData) || !variantsData.length) {
    return {
      price: fallback.price,
      stock: fallback.stock,
    };
  }

  const activeVariants = variantsData.filter((variant) => !variant.isDeleted);
  if (!activeVariants.length) {
    return {
      price: fallback.price,
      stock: fallback.stock,
    };
  }

  return {
    price: Math.min(...activeVariants.map((variant) => Number(variant.price || 0))),
    stock: activeVariants.reduce(
      (sum, variant) => sum + Number(variant.stock || 0),
      0,
    ),
  };
};

const ensureCategoryExists = async (categoryId) => {
  const category = await Category.findById(categoryId);
  if (!category) {
    throw new NotFoundError('Category not found');
  }
};

const normalizeOptionalSku = (value) => {
  if (value == null) {
    return undefined;
  }

  const normalized = `${value}`.trim().toUpperCase();
  return normalized.length ? normalized : undefined;
};

const ensureUniqueProductFields = async ({ productId, slug, sku }) => {
  if (slug) {
    const slugOwner = await Product.findOne({
      slug: slug.toLowerCase(),
      ...(productId ? { _id: { $ne: productId } } : {}),
    }).select('_id');

    if (slugOwner) {
      throw new BadRequestError('Slug is already in use');
    }
  }

  if (sku) {
    const productSkuOwner = await Product.findOne({
      sku,
      ...(productId ? { _id: { $ne: productId } } : {}),
    }).select('_id');

    if (productSkuOwner) {
      throw new BadRequestError('SKU is already in use');
    }
  }
};

const assertProductAccess = (product, actor) => {
  if (!actor || actor.role === 'admin') {
    return;
  }

  if (
    actor.role === 'organization' &&
    product.orgId.toString() !== actor.organization?.toString()
  ) {
    throw new ForbiddenError('You are not allowed to manage this product');
  }
};

const buildStockHistoryEntry = ({
  previousStock = 0,
  newStock,
  note,
  source = 'manual',
}) => ({
  previousStock,
  newStock,
  note,
  source,
  changedAt: new Date(),
});

export const createProduct = async (productData, variantsData) => {
  const organization = await Organization.findById(productData.orgId);
  if (!organization) {
    throw new NotFoundError('Organization not found');
  }

  await ensureCategoryExists(productData.category);
  await ensureUniqueProductFields({
    slug: productData.slug,
    sku: normalizeOptionalSku(productData.sku),
  });

  const summary = normalizeVariantSummary(variantsData, productData);
  const payload = {
    ...productData,
    beneficiaryDescription:
      productData.beneficiaryDescription || productData.description,
    sku: normalizeOptionalSku(productData.sku),
    price: Number(summary.price ?? productData.price ?? 0),
    stock: Number(summary.stock ?? productData.stock ?? 0),
    stockHistory: [
      buildStockHistoryEntry({
        previousStock: 0,
        newStock: Number(summary.stock ?? productData.stock ?? 0),
        note: 'Initial stock',
        source: 'create',
      }),
    ],
  };

  const product = new Product(payload);
  await product.save();

  if (variantsData && variantsData.length > 0) {
    const variants = variantsData.map((variant) => ({
      ...variant,
      sku: normalizeOptionalSku(variant.sku),
      productId: product._id,
    }));
    await ProductVariant.insertMany(variants);
  }

  return await getProductById(product._id);
};

export const updateProduct = async (
  productId,
  productUpdates,
  variantsUpdates,
  actor,
) => {
  const product = await Product.findById(productId);
  if (!product || product.isDeleted) {
    throw new NotFoundError('Product not found');
  }
  assertProductAccess(product, actor);

  if (productUpdates.category) {
    await ensureCategoryExists(productUpdates.category);
  }

  const normalizedSku = normalizeOptionalSku(productUpdates.sku);
  await ensureUniqueProductFields({
    productId,
    slug: productUpdates.slug,
    sku: normalizedSku,
  });

  if (productUpdates.sku != null) {
    productUpdates.sku = normalizedSku;
  }

  if (variantsUpdates) {
    for (const variant of variantsUpdates) {
      if (variant._id) {
        await ProductVariant.findByIdAndUpdate(variant._id, {
          ...variant,
          sku: normalizeOptionalSku(variant.sku),
        }, {
          new: true,
          runValidators: true,
        });
      } else {
        await new ProductVariant({
          ...variant,
          sku: normalizeOptionalSku(variant.sku),
          productId,
        }).save();
      }
    }

    const allVariants = await ProductVariant.find({
      productId,
      isDeleted: false,
      isActive: true,
    });
    const summary = normalizeVariantSummary(allVariants, {
      price: productUpdates.price ?? product.price,
      stock: productUpdates.stock ?? product.stock,
    });
    productUpdates.price = summary.price;
    productUpdates.stock = summary.stock;
  }

  if (productUpdates.beneficiaryDescription == null &&
      productUpdates.description != null) {
    productUpdates.beneficiaryDescription = productUpdates.description;
  }

  if (productUpdates.stock != null &&
      Number(productUpdates.stock) != Number(product.stock)) {
    const nextStock = Number(productUpdates.stock);
    const historyEntry = buildStockHistoryEntry({
      previousStock: Number(product.stock),
      newStock: nextStock,
      note: productUpdates.stockNote || 'Manual stock update',
      source: variantsUpdates != null ? 'variant-sync' : 'manual',
    });

    productUpdates.stockHistory = [...(product.stockHistory || []), historyEntry];
  }

  delete productUpdates.stockNote;

  if (productUpdates.isActive != null) {
    productUpdates.archivedAt = productUpdates.isActive
      ? null
      : (product.archivedAt || new Date());
  }

  await Product.findByIdAndUpdate(productId, productUpdates, {
    new: true,
    runValidators: true,
  });

  return await getProductById(productId);
};

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

export const listProducts = async (filters, page = 1, limit = 10) => {
  const skip = (page - 1) * limit;
  const {
    search,
    category,
    minPrice,
    maxPrice,
    sort = 'newest',
    includeInactive,
    ...restFilters
  } = filters;

  const query = {
    isDeleted: false,
    ...restFilters,
  };

  if (`${includeInactive}` !== 'true') {
    query.isActive = true;
  }

  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
      { beneficiaryDescription: { $regex: search, $options: 'i' } },
    ];
  }

  if (category) {
    if (category.match(/^[0-9a-fA-F]{24}$/)) {
      query.category = category;
    } else {
      const matchingCategories = await Category.find({
        $or: [
          { slug: category.toLowerCase() },
          { name: { $regex: `^${category}$`, $options: 'i' } },
        ],
      }).select('_id');

      query.category = { $in: matchingCategories.map((item) => item._id) };
    }
  }

  if (minPrice != null || maxPrice != null) {
    query.price = {};
    if (minPrice != null) {
      query.price.$gte = Number(minPrice);
    }
    if (maxPrice != null) {
      query.price.$lte = Number(maxPrice);
    }
  }

  const sortMap = {
    newest: { createdAt: -1 },
    price_asc: { price: 1, createdAt: -1 },
    price_desc: { price: -1, createdAt: -1 },
    most_reviewed: { ratingCount: -1, ratingAverage: -1, createdAt: -1 },
  };

  if (!sortMap[sort]) {
    throw new BadRequestError(
      'Invalid sort option. Use newest, price_asc, price_desc, or most_reviewed',
    );
  }

  const products = await Product.find(query)
    .populate({
      path: 'variants',
      model: ProductVariant
    })
    .populate({
      path: 'orgId',
      model: Organization,
      select: 'organizationName'
    })
    .populate({
      path: 'category',
      model: Category,
      select: 'name slug',
    })
    .select('-createdAt -updatedAt -__v -images.publicId -images.altText')
    .skip(skip)
    .limit(limit)
    .sort(sortMap[sort]);

  const total = await Product.countDocuments(query);

  return { products, total, totalPages: Math.ceil(total / limit) };
};


export const softDeleteProduct = async (id, actor) => {
  const product = await Product.findById(id);
  if (!product || product.isDeleted) {
    throw new NotFoundError('Product not found');
  }

  assertProductAccess(product, actor);

  return await Product.findByIdAndUpdate(
    id,
    {
      isDeleted: true,
      isActive: false,
      archivedAt: new Date(),
    },
    { new: true },
  );
};
