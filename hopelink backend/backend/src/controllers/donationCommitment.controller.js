import { StatusCodes } from 'http-status-codes';
import {
  createDonationCommitment,
  getCommitmentsForOrganizationRequest,
  getUserCommitments,
  updateDonationCommitmentStatus,
} from '../services/donationCommitment.service.js';

export const createCommitment = async (req, res) => {
  const commitment = await createDonationCommitment({
    payload: req.body,
    user: req.user,
  });

  res.status(StatusCodes.CREATED).json({
    success: true,
    data: commitment,
  });
};

export const getCurrentUserCommitments = async (req, res) => {
  const commitments = await getUserCommitments(req.user);

  res.status(StatusCodes.OK).json({
    success: true,
    count: commitments.length,
    data: commitments,
  });
};

export const getOrganizationRequestCommitments = async (req, res) => {
  const result = await getCommitmentsForOrganizationRequest({
    requestId: req.params.id,
    user: req.user,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: result,
  });
};

export const updateCommitmentStatus = async (req, res) => {
  const commitment = await updateDonationCommitmentStatus({
    commitmentId: req.params.id,
    payload: req.body,
    user: req.user,
  });

  res.status(StatusCodes.OK).json({
    success: true,
    data: commitment,
  });
};
