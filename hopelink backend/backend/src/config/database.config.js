import mongoose from 'mongoose';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get MongoDB connection string from environment variables
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/charity_platform';

// Log the MongoDB URI (for debugging, remove in production)
console.log('Connecting to MongoDB with URI:', mongoUri);

const connectDB = async () => {
  try {
    // Set mongoose options
    const options = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
      socketTimeoutMS: 45000, // Close sockets after 45 seconds of inactivity
    };

    // Attempt to connect to MongoDB
    const conn = await mongoose.connect(mongoUri, options);
    
    // Log successful connection
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Database Name: ${conn.connection.name}`);
    
    // Handle connection events
    mongoose.connection.on('connected', () => {
      console.log('Mongoose connected to DB');
    });

    mongoose.connection.on('error', (err) => {
      console.error('Mongoose connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('Mongoose disconnected');
    });

    return conn;
  } catch (error) {
    console.error('MongoDB Connection Error:', error.message);
    console.error('Full Error:', error);
    
    // Exit process with failure
    process.exit(1);
  }
};

// Handle process termination
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('MongoDB connection closed through app termination');
  process.exit(0);
});

export default connectDB;
