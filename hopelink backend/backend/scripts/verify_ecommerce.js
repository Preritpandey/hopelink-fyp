import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load env
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../.env') });

import User from '../src/models/user.model.js';
import Organization from '../src/models/organization.model.js';
import Category from '../src/models/category.model.js';
import Product from '../src/models/ecommerce/product.model.js';
import ProductVariant from '../src/models/ecommerce/productVariant.model.js';
import Cart from '../src/models/ecommerce/cart.model.js';
import Order from '../src/models/ecommerce/order.model.js';
import Review from '../src/models/ecommerce/review.model.js';
import * as ProductService from '../src/services/ecommerce/product.service.js';
import * as CartService from '../src/services/ecommerce/cart.service.js';
import * as OrderService from '../src/services/ecommerce/order.service.js';
import * as ReviewService from '../src/services/ecommerce/review.service.js';

const runVerification = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/charity-db');
    console.log('Connected to DB');

    // 1. Setup Data
    console.log('\n--- Setting up Test Data ---');
    let user = await User.findOne();
    if (!user) {
        console.log('Creating test user...');
        user = await User.create({
            name: 'Test User',
            username: 'testuser',
            email: `test${Date.now()}@example.com`,
            password: 'password123', 
            role: 'user',
            isVerified: true
        });
    }
    console.log('Test User:', user.email);

    let org = await Organization.findOne();
    if (!org) {
        console.log('Creating test organization...');
        org = await Organization.create({
            organizationName: 'Test Org',
            organizationType: 'Non-Profit',
            registrationNumber: 'REG123',
            activeMembers: 10,
            user: user._id, // Link to user
            status: 'approved'
        });
    }
    console.log('Test Organization:', org.organizationName);

    // 2. Create Product
    console.log('\n--- Testing Product Creation ---');
    const productData = {
      orgId: org._id,
      name: `Handmade Scarf ${Date.now()}`,
      description: 'Beautiful wool scarf',
      beneficiaryDescription: 'Made by elderly artisans',
      category: new mongoose.Types.ObjectId(), // Fake category ID
      images: [{ url: 'http://example.com/scarf.jpg' }]
    };
    
    const variantsData = [
      { attributes: { color: 'Red' }, price: 20, sku: `SCARF-RED-${Date.now()}`, stock: 10 },
      { attributes: { color: 'Blue' }, price: 20, sku: `SCARF-BLUE-${Date.now()}`, stock: 5 }
    ];

    const product = await ProductService.createProduct(productData, variantsData);
    console.log('Product Created:', product.name);
    console.log('Product Slug:', product.slug);

    const fetchedProduct = await ProductService.getProductById(product._id);
    console.log(`Product has ${fetchedProduct.variants.length} variants`);

    // 3. Cart Operations
    console.log('\n--- Testing Cart Operations ---');
    const variantId = fetchedProduct.variants[0]._id;
    
    await CartService.addToCart(user._id, product._id, variantId, 2);
    console.log('Added 2 items to cart');
    
    let cart = await CartService.getCart(user._id);
    console.log(`Cart has ${cart.items.length} item(s)`);
    console.log(`Item quantity: ${cart.items[0].quantity}`);

    await CartService.updateCartItem(user._id, variantId, 3);
    cart = await CartService.getCart(user._id);
    console.log(`Updated quantity to: ${cart.items[0].quantity}`);
    
    // 4. Checkout
    console.log('\n--- Testing Checkout ---');
    const shippingAddress = {
      fullName: 'John Doe',
      street: '123 Main St',
      city: 'Test City',
      country: 'Test Country'
    };
    const paymentData = { paymentReference: 'pay_123' };

    const orders = await OrderService.createOrderFromCart(user._id, shippingAddress, paymentData);
    console.log(`Created ${orders.length} order(s)`);
    console.log(`Order Status: ${orders[0].status}`);
    console.log(`Order SubTotal: ${orders[0].subTotal}`);

    // 5. Verify Stock Reduction
    const variantAfterOrder = await ProductVariant.findById(variantId);
    console.log(`Old Stock: 10, Bought: 3, New Stock: ${variantAfterOrder.stock}`);
    if (variantAfterOrder.stock !== 7) throw new Error('Stock not reduced correctly!');
    console.log('Stock verification PASSED');

    // 6. Review
    console.log('\n--- Testing Review ---');
    await ReviewService.addReview(user._id, product._id, 5, 'Great scarf!');
    console.log('Review added');

    const productWithReview = await Product.findById(product._id);
    console.log(`Product Rating: ${productWithReview.ratingAverage} (${productWithReview.ratingCount} reviews)`);

    console.log('\n=== VERIFICATION SUCCESSFUL ===');

  } catch (error) {
    console.error('Verification Failed:', error);
  } finally {
    // Cleanup - optional, or keep for manual inspection
    // await Product.deleteOne({ _id: product._id });
    // await ProductVariant.deleteMany({ productId: product._id });
    await mongoose.disconnect();
  }
};

runVerification();
