import { StatusCodes } from 'http-status-codes';
import crypto from 'crypto';
import mongoose from 'mongoose';
import VolunteerCertification from '../models/volunteerCertification.model.js';
import VolunteerApplication from '../models/volunteerApplication.model.js';
import User from '../models/user.model.js';
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
} from '../errors/index.js';

const generateVerificationCode = () =>
  crypto.randomBytes(16).toString('hex');

const parseSkills = (skills) => {
  if (!skills) return [];
  if (Array.isArray(skills)) return skills.map((s) => s.toString().trim());
  return skills
    .toString()
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
};

export const issueVolunteerCertification = async (req, res) => {
  const { applicationId, certificateUrl, skillsGained, duration } = req.body;

  if (!applicationId || !mongoose.Types.ObjectId.isValid(applicationId)) {
    throw new BadRequestError('Valid applicationId is required');
  }
  if (!certificateUrl) {
    throw new BadRequestError('certificateUrl is required');
  }

  const application = await VolunteerApplication.findById(applicationId).populate(
    'job',
  );
  if (!application) {
    throw new NotFoundError('Application not found');
  }

  const job = application.job;
  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to issue certification');
  }

  if (application.status !== 'approved') {
    throw new BadRequestError('Certification can only be issued for approved applications');
  }

  if (!job.certificateProvided) {
    throw new BadRequestError('This job does not provide certification');
  }

  const existing = await VolunteerCertification.findOne({
    user: application.user,
    job: job._id,
  });
  if (existing) {
    return res.status(StatusCodes.OK).json({
      success: true,
      message: 'Certification already issued',
      data: existing,
    });
  }

  const verificationCode = generateVerificationCode();

  const certification = await VolunteerCertification.create({
    user: application.user,
    organization: job.organization,
    job: job._id,
    jobTitle: job.title,
    organizationName: job.organizationName,
    certificateUrl: certificateUrl.toString().trim(),
    verificationCode,
    skillsGained: parseSkills(skillsGained),
    duration: duration ? duration.toString().trim() : '',
  });

  await User.findByIdAndUpdate(application.user, {
    $addToSet: { certifications: certification._id },
  });

  return res.status(StatusCodes.CREATED).json({
    success: true,
    message: 'Certification issued',
    data: certification,
  });
};

export const getMyCertifications = async (req, res) => {
  const certifications = await VolunteerCertification.find({
    user: req.user._id,
  }).sort({ createdAt: -1 });

  return res.status(StatusCodes.OK).json({
    success: true,
    count: certifications.length,
    data: certifications,
  });
};
