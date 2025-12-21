import nodemailer from 'nodemailer';
import path from 'path';
import { fileURLToPath } from 'url';
import { readFileSync } from 'fs';
import handlebars from 'handlebars';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL,
    pass: process.env.PASSWORD,
  },
});

// Compile email template
const compileTemplate = (templateName, data) => {
  const filePath = path.join(__dirname, `../emails/${templateName}.hbs`);
  const source = readFileSync(filePath, 'utf-8');
  const template = handlebars.compile(source);
  return template(data);
};

// Send email
const sendEmail = async (options) => {
  try {
    // If options is a direct email config (from emailTemplates)
    if (options.template) {
      const html = compileTemplate(options.template, {
        ...options.context,
        frontendUrl: process.env.FRONTEND_URL,
        supportEmail: process.env.SUPPORT_EMAIL,
        currentYear: new Date().getFullYear(),
      });

      const mailOptions = {
        from: `"HopeLink" <${process.env.EMAIL}>`,
        to: options.to,
        subject: options.subject,
        html,
      };

      await transporter.sendMail(mailOptions);
    } 
    // If options is a direct HTML email
    else if (options.html) {
      const mailOptions = {
        from: `"HopeLink" <${process.env.EMAIL}>`,
        to: options.to,
        subject: options.subject,
        html: options.html,
      };

      await transporter.sendMail(mailOptions);
    } else {
      throw new Error('Invalid email options: must include either template or html');
    }

    console.log(`Email sent to ${options.to}`);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    throw new Error('Failed to send email');
  }
};

// Email templates
const emailTemplates = {
  organizationApproved: (data) => ({
    to: data.email,
    subject: `🎉 Your Organization ${data.organizationName} Has Been Approved`,
    template: 'organization-approved',
    context: {
      organizationName: data.organizationName,
      email: data.email,
      password: data.password,
      representativeName: data.representativeName,
      loginUrl: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`,
    },
  }),
  passwordReset: (data) => ({
    to: data.email,
    subject: 'Password Reset Request',
    template: 'password-reset',
    context: {
      name: data.name,
      resetUrl: `${process.env.FRONTEND_URL}/reset-password?token=${data.resetToken}`,
      expiresIn: '1 hour',
    },
  }),
};

export { sendEmail, emailTemplates };
