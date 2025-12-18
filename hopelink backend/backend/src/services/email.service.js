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
const sendEmail = async ({ to, subject, template, context }) => {
  try {
    const html = compileTemplate(template, {
      ...context,
      frontendUrl: process.env.FRONTEND_URL,
      supportEmail: process.env.SUPPORT_EMAIL,
      currentYear: new Date().getFullYear(),
    });

    const mailOptions = {
      from: `"HopeLink" <${process.env.EMAIL}>`,
      to,
      subject,
      html,
    };

    await transporter.sendMail(mailOptions);
    console.log(`Email sent to ${to}`);
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
    subject: 'Your Organization Has Been Approved',
    template: 'organization-approved',
    context: {
      organizationName: data.organizationName,
      email: data.email,
      password: data.password,
      loginUrl: `${process.env.FRONTEND_URL}/login`,
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
