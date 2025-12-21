import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from the root .env file
dotenv.config({ path: path.resolve(__dirname, '.env') });

// Import models to register them with Mongoose
import './src/models/index.js';

import express from 'express';
import connectDB from './src/config/database.config.js';
import mainRouter from './src/routes/index.js';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import cors from 'cors';

const swaggerDocument = YAML.load('./swagger.yaml');

const app = express();

// Connect to DB
connectDB().catch(err => {
  console.error('Failed to connect to MongoDB', err);
  process.exit(1);
});

app.use(cors());

app.use(express.json());

// Main routes
app.use('/api/v1', mainRouter);

// Import error handler
import errorHandler from './src/middleware/errorHandler.js';
import { allowedNodeEnvironmentFlags } from 'process';

// Use error handling middleware (must be after all other middleware and routes)
app.use(errorHandler);

// Handle 404 - Keep this after all other routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      message: 'Not Found',
      code: 404,
      timestamp: new Date().toISOString()
    }
  });
});

// Swagger Documentation Route
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Home Route
app.get('/', (req, res) => {
  res.send('Hello World!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port http://localhost:${PORT}`);
});
