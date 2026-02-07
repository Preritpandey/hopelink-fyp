import { StatusCodes } from 'http-status-codes';
import mongoose from 'mongoose';
import VolunteerJob from '../models/volunteerJob.model.js';
import Organization from '../models/organization.model.js';
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

export const createVolunteerJob = async (req, res) => {
  const {
    title,
    description,
    category,
    requiredSkills,
    address,
    city,
    state,
    coordinates,
    positionsAvailable,
    applicationDeadline,
    jobType,
    certificateProvided,
    creditHours,
  } = req.body;

  if (!title || !description || !category || !positionsAvailable || !applicationDeadline) {
    throw new BadRequestError('Missing required fields');
  }
  if (new Date(applicationDeadline) < new Date()) {
    throw new BadRequestError('Application deadline must be in the future');
  }

  const orgId = req.user.organization;
  if (!orgId) {
    throw new ForbiddenError('Organization not found on user');
  }

  const organization = await Organization.findById(orgId);
  if (!organization) {
    throw new NotFoundError('Organization not found');
  }

  const job = await VolunteerJob.create({
    organization: orgId,
    organizationName: organization.organizationName,
    title,
    description,
    category,
    requiredSkills: parseSkills(requiredSkills),
    location: {
      address,
      city,
      state,
      coordinates: coordinates
        ? {
            type: 'Point',
            coordinates: coordinates.split(',').map(Number),
          }
        : undefined,
    },
    positionsAvailable: Number(positionsAvailable),
    applicationDeadline: new Date(applicationDeadline),
    jobType: jobType || 'onsite',
    certificateProvided: Boolean(certificateProvided),
    creditHours: Number(creditHours || 0),
    status: 'open',
  });

  return res.status(StatusCodes.CREATED).json({
    success: true,
    message: 'Volunteer job created',
    data: job,
  });
};

export const updateVolunteerJob = async (req, res) => {
  const { jobId } = req.params;
  if (!mongoose.Types.ObjectId.isValid(jobId)) {
    throw new BadRequestError('Invalid job id');
  }

  const job = await VolunteerJob.findById(jobId);
  if (!job) {
    throw new NotFoundError('Volunteer job not found');
  }

  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to update this job');
  }

  const allowedUpdates = [
    'title',
    'description',
    'category',
    'requiredSkills',
    'location',
    'positionsAvailable',
    'applicationDeadline',
    'jobType',
    'certificateProvided',
    'status',
    'creditHours',
  ];

  for (const key of allowedUpdates) {
    if (Object.prototype.hasOwnProperty.call(req.body, key)) {
      if (key === 'requiredSkills') {
        job.requiredSkills = parseSkills(req.body.requiredSkills);
      } else if (key === 'applicationDeadline') {
        const deadline = new Date(req.body.applicationDeadline);
        if (deadline < new Date()) {
          throw new BadRequestError('Application deadline must be in the future');
        }
        job.applicationDeadline = deadline;
      } else if (key === 'positionsAvailable') {
        const positionsAvailable = Number(req.body.positionsAvailable);
        if (positionsAvailable < job.positionsFilled) {
          throw new BadRequestError('positionsAvailable cannot be less than positionsFilled');
        }
        job.positionsAvailable = positionsAvailable;
      } else if (key === 'creditHours') {
        job.creditHours = Number(req.body.creditHours || 0);
      } else {
        job[key] = req.body[key];
      }
    }
  }

  await job.save();

  return res.status(StatusCodes.OK).json({
    success: true,
    message: 'Volunteer job updated',
    data: job,
  });
};

export const closeVolunteerJob = async (req, res) => {
  const { jobId } = req.params;
  if (!mongoose.Types.ObjectId.isValid(jobId)) {
    throw new BadRequestError('Invalid job id');
  }

  const job = await VolunteerJob.findById(jobId);
  if (!job) {
    throw new NotFoundError('Volunteer job not found');
  }

  if (job.organization.toString() !== req.user.organization?.toString()) {
    throw new ForbiddenError('Not authorized to close this job');
  }

  job.status = 'closed';
  await job.save();

  return res.status(StatusCodes.OK).json({
    success: true,
    message: 'Volunteer job closed',
    data: job,
  });
};

export const getVolunteerJobs = async (req, res) => {
  const {
    category,
    city,
    skills,
    jobType,
    page = 1,
    limit = 10,
    sort = 'newest',
    search,
  } = req.query;

  const query = {
    status: 'open',
    applicationDeadline: { $gte: new Date() },
  };

  if (category) query.category = category;
  if (city) query['location.city'] = new RegExp(city, 'i');
  if (jobType) query.jobType = jobType;

  if (skills) {
    const skillsList = parseSkills(skills);
    if (skillsList.length) {
      query.requiredSkills = { $in: skillsList };
    }
  }

  if (search) {
    query.$text = { $search: search.toString() };
  }

  const sortOption = sort === 'newest' ? { createdAt: -1 } : { createdAt: 1 };

  const pageNum = parseInt(page, 10) || 1;
  const limitNum = parseInt(limit, 10) || 10;
  const skip = (pageNum - 1) * limitNum;

  const [jobs, total] = await Promise.all([
    VolunteerJob.find(query).sort(sortOption).skip(skip).limit(limitNum),
    VolunteerJob.countDocuments(query),
  ]);

  return res.status(StatusCodes.OK).json({
    success: true,
    count: jobs.length,
    total,
    page: pageNum,
    pages: Math.ceil(total / limitNum),
    data: jobs,
  });
};

export const getVolunteerJobById = async (req, res) => {
  const { jobId } = req.params;
  if (!mongoose.Types.ObjectId.isValid(jobId)) {
    throw new BadRequestError('Invalid job id');
  }

  const job = await VolunteerJob.findById(jobId);
  if (!job) {
    throw new NotFoundError('Volunteer job not found');
  }

  if (
    job.status === 'closed' &&
    req.user?.role !== 'admin' &&
    job.organization.toString() !== req.user?.organization?.toString()
  ) {
    throw new ForbiddenError('Not authorized to view this job');
  }

  return res.status(StatusCodes.OK).json({
    success: true,
    data: job,
  });
};

export const getMyOrganizationJobs = async (req, res) => {
  const orgId = req.user.organization;
  if (!orgId) {
    throw new ForbiddenError('Organization not found on user');
  }

  const jobs = await VolunteerJob.find({ organization: orgId }).sort({
    createdAt: -1,
  });

  return res.status(StatusCodes.OK).json({
    success: true,
    count: jobs.length,
    data: jobs,
  });
};
