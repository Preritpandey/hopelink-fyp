import { StatusCodes } from 'http-status-codes';
import mongoose from 'mongoose';
import fs from 'fs';
import VolunteerJob from '../models/volunteerJob.model.js';
import VolunteerApplication from '../models/volunteerApplication.model.js';
import User from '../models/user.model.js';
import { sendEmail } from '../services/email.service.js';
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
} from '../errors/index.js';

const parseSkills = (skills) => {
  if (!skills) return [];
  if (Array.isArray(skills)) return skills.map((s) => s.toString().trim());
  return skills
    .toString()
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
};

export const applyToVolunteerJob = async (req, res) => {
  const { jobId } = req.params;
  const { whyHire, skills, experience } = req.body;

  if (!mongoose.Types.ObjectId.isValid(jobId)) {
    throw new BadRequestError('Invalid job id');
  }
  if (!whyHire || !whyHire.toString().trim()) {
    throw new BadRequestError('Why should we hire you? is required');
  }
  if (!req.file) {
    throw new BadRequestError('Resume PDF is required');
  }
  const parsedSkills = parseSkills(skills);
  if (!parsedSkills.length) {
    throw new BadRequestError('Skills are required');
  }

  const job = await VolunteerJob.findById(jobId);
  if (!job) {
    throw new NotFoundError('Volunteer job not found');
  }

  if (job.status !== 'open') {
    throw new BadRequestError('This job is closed');
  }

  if (new Date() > new Date(job.applicationDeadline)) {
    throw new BadRequestError('Application deadline has passed');
  }

  if (job.positionsFilled >= job.positionsAvailable) {
    throw new BadRequestError('No positions available');
  }

  const existing = await VolunteerApplication.findOne({
    job: jobId,
    user: req.user._id,
  });
  if (existing) {
    throw new BadRequestError('You have already applied to this job');
  }

  const user = await User.findById(req.user._id);
  if (!user) {
    throw new NotFoundError('User not found');
  }

  const snapshot = {
    fullName: user.name,
    email: user.email,
    profileImage: user.profileImage,
    bio: user.bio,
    skills: user.skills || [],
    certifications: user.certifications || [],
    totalVolunteerHours: user.totalVolunteerHours || 0,
    rating: user.rating || 0,
  };

  const application = await VolunteerApplication.create({
    job: jobId,
    organization: job.organization,
    user: req.user._id,
    resumePath: req.file.path,
    resumeOriginalName: req.file.originalname,
    whyHire: whyHire.toString().trim(),
    skills: parsedSkills,
    experience: experience ? experience.toString().trim() : '',
    applicantSnapshot: snapshot,
  });

  return res.status(StatusCodes.CREATED).json({
    success: true,
    message: 'Application submitted',
    data: application,
  });
};

export const getMyVolunteerApplications = async (req, res) => {
  const applications = await VolunteerApplication.find({
    user: req.user._id,
  })
    .populate('job', 'title category jobType status applicationDeadline')
    .sort({ createdAt: -1 });

  return res.status(StatusCodes.OK).json({
    success: true,
    count: applications.length,
    data: applications,
  });
};

export const getApplicationsByJob = async (req, res) => {
  return getApplicationsByJobByStatus(req, res, 'pending');
};

export const getApprovedApplicationsByJob = async (req, res) => {
  return getApplicationsByJobByStatus(req, res, 'approved');
};

export const getRejectedApplicationsByJob = async (req, res) => {
  return getApplicationsByJobByStatus(req, res, 'rejected');
};

const getApplicationsByJobByStatus = async (req, res, status) => {
  const { jobId } = req.params;
  if (!mongoose.Types.ObjectId.isValid(jobId)) {
    throw new BadRequestError('Invalid job id');
  }

  const job = await VolunteerJob.findById(jobId);
  if (!job) {
    throw new NotFoundError('Volunteer job not found');
  }

  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to view applications for this job');
  }

  const applications = await VolunteerApplication.find({
    job: jobId,
    status,
  }).sort({ createdAt: -1 });

  return res.status(StatusCodes.OK).json({
    success: true,
    count: applications.length,
    data: applications,
  });
};

export const approveVolunteerApplication = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new BadRequestError('Invalid application id');
  }

  const application = await VolunteerApplication.findById(id).populate('job');
  if (!application) {
    throw new NotFoundError('Application not found');
  }

  const job = application.job;
  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to approve this application');
  }

  if (application.status === 'approved') {
    return res.status(StatusCodes.OK).json({
      success: true,
      message: 'Application already approved',
      data: application,
    });
  }
  if (application.status === 'rejected') {
    throw new BadRequestError('Cannot approve a rejected application');
  }

  // Check if positions are available before approving
  const updatedJob = await VolunteerJob.findOneAndUpdate(
    {
      _id: job._id,
      status: 'open',
      $expr: { $lt: ['$positionsFilled', '$positionsAvailable'] },
    },
    { $inc: { positionsFilled: 1 } },
    { new: true },
  );

  if (!updatedJob) {
    throw new BadRequestError('No positions available');
  }

  application.status = 'approved';
  application.rejectionReason = undefined;
  application.approvedAt = new Date();
  await application.save();

  // Best-effort email notification
  try {
    await sendEmail({
      to: application.applicantSnapshot?.email,
      subject: `Volunteer Application Approved - ${job.title}`,
      template: 'volunteer-application-approved',
      context: {
        name: application.applicantSnapshot?.fullName || 'Volunteer',
        jobTitle: job.title,
        organizationName: job.organizationName,
      },
    });
  } catch (emailError) {
    console.error('Error sending approval email:', emailError);
  }

  return res.status(StatusCodes.OK).json({
    success: true,
    message: 'Application approved',
    data: application,
  });
};

export const rejectVolunteerApplication = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new BadRequestError('Invalid application id');
  }
  if (!reason || !reason.toString().trim()) {
    throw new BadRequestError('Rejection reason is required');
  }

  const application = await VolunteerApplication.findById(id).populate('job');
  if (!application) {
    throw new NotFoundError('Application not found');
  }

  const job = application.job;
  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to reject this application');
  }

  if (application.status === 'approved') {
    throw new BadRequestError('Cannot reject an approved application');
  }

  application.status = 'rejected';
  application.rejectionReason = reason.toString().trim();
  application.rejectedAt = new Date();
  await application.save();

  // Best-effort email notification
  try {
    await sendEmail({
      to: application.applicantSnapshot?.email,
      subject: `Volunteer Application Rejected - ${job.title}`,
      template: 'volunteer-application-rejected',
      context: {
        name: application.applicantSnapshot?.fullName || 'Volunteer',
        jobTitle: job.title,
        organizationName: job.organizationName,
        reason: application.rejectionReason,
      },
    });
  } catch (emailError) {
    console.error('Error sending rejection email:', emailError);
  }

  return res.status(StatusCodes.OK).json({
    success: true,
    message: 'Application rejected',
    data: application,
  });
};

export const downloadApplicationResume = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new BadRequestError('Invalid application id');
  }

  const application = await VolunteerApplication.findById(id).populate('job');
  if (!application) {
    throw new NotFoundError('Application not found');
  }

  const job = application.job;
  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to access this resume');
  }

  const filePath = application.resumePath;
  if (!filePath || !fs.existsSync(filePath)) {
    throw new NotFoundError('Resume file not found');
  }

  return res.download(filePath, application.resumeOriginalName || 'resume.pdf');
};

export const grantVolunteerCreditHours = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new BadRequestError('Invalid application id');
  }

  const application = await VolunteerApplication.findById(id).populate('job');
  if (!application) {
    throw new NotFoundError('Application not found');
  }

  const job = application.job;
  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to grant credit hours');
  }

  if (application.status !== 'approved') {
    throw new BadRequestError('Only approved applications can receive credits');
  }

  if (!job.creditHours || job.creditHours <= 0) {
    throw new BadRequestError('Job does not define credit hours');
  }

  if (application.creditHoursGranted && application.creditHoursGranted > 0) {
    return res.status(StatusCodes.OK).json({
      success: true,
      message: 'Credit hours already granted',
      data: application,
    });
  }

  application.creditHoursGranted = job.creditHours;
  application.creditGrantedAt = new Date();
  await application.save();

  await User.findByIdAndUpdate(
    application.user,
    { $inc: { totalVolunteerHours: job.creditHours } },
  );

  return res.status(StatusCodes.OK).json({
    success: true,
    message: 'Credit hours granted',
    data: application,
  });
};
