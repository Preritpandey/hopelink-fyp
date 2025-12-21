import dotenv from 'dotenv';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';
import { approveOrganization } from '../src/controllers/admin.controller.js';
import Organization from '../src/models/organization.model.js';
import User from '../src/models/user.model.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env from backend root (../.env)
dotenv.config({ path: path.join(__dirname, '../.env') });

const mockRes = () => {
  const res = {};
  res.statusCode = 200;
  res.data = null;
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (data) => {
    res.data = data;
    return res;
  };
  return res;
};

async function run() {
    try {
        const mongoUri = 'mongodb://localhost:27017/charity_platform';
        console.log("Connecting to DB...", mongoUri);
        await mongoose.connect(mongoUri);
        console.log("Connected to DB");

        // Clean up
        const testEmail = "repro_org@example.com";
        const adminEmail = "repro_admin@example.com";
        await Organization.deleteMany({ officialEmail: testEmail });
        await User.deleteMany({ email: testEmail });
        await User.deleteMany({ email: adminEmail });

        // 1. Create Admin
        const admin = await User.create({
            name: "Repro Admin",
            email: adminEmail,
            password: "password123",
            role: "admin",
            isVerified: true
        });
        console.log("Admin created:", admin._id);

        // 2. Create Pending Organization
        const org = await Organization.create({
            organizationName: "Repro Org",
            officialEmail: testEmail,
            status: "pending",
            representativeName: "Rep Name",
            activeMembers: 5,
            registrationNumber: "REG12345",
            organizationType: "NGO"
            // No user linked
        });
        console.log("Org created:", org._id);

        // 3. Mock Request
        // Note: auth middleware sets req.user to the User Document.
        // The User document object usually does NOT have .userId property, only ._id
        const req = {
            params: { id: org._id.toString() },
            user: admin
        };

        // 4. Call Controller
        console.log("Calling approveOrganization...");
        const res = mockRes();
        await approveOrganization(req, res);

        console.log("--------------------------------");
        console.log("Status:", res.statusCode);
        console.log("Response:", JSON.stringify(res.data, null, 2));
        console.log("--------------------------------");

        // Check if user was created and linked correctly
        const orgUser = await User.findOne({ email: testEmail });
        if (orgUser) {
            console.log("SUCCESS: Organization user created:", orgUser._id);
            console.log("User Role:", orgUser.role);
            console.log("User Organization Field:", orgUser.organization);
            
            if (orgUser.organization && orgUser.organization.toString() === org._id.toString()) {
                console.log("SUCCESS: User is correctly linked to Organization (Bidirectional)");
            } else {
                console.log("FAILURE: User.organization field is missing or incorrect!");
                console.log("Expected:", org._id);
                console.log("Actual:", orgUser.organization);
            }
        } else {
            console.log("FAILURE: Organization user NOT created");
        }

    } catch (e) {
        console.error("Error in script:", e);
    } finally {
        await mongoose.disconnect();
    }
}

run();
