import { StatusCodes } from 'http-status-codes';
import * as SavedCauseService from '../services/savedCause.service.js';

export const getSavedCauses = async (req, res, next) => {
  try {
    const data = await SavedCauseService.getSavedCauses(req.user._id);
    res.status(StatusCodes.OK).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    next(error);
  }
};

export const saveCause = async (req, res, next) => {
  try {
    const data = await SavedCauseService.saveCause(req.user._id, req.params.postId);
    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Cause saved successfully',
      data,
    });
  } catch (error) {
    next(error);
  }
};

export const unsaveCause = async (req, res, next) => {
  try {
    const data = await SavedCauseService.unsaveCause(req.user._id, req.params.postId);
    res.status(StatusCodes.OK).json({
      success: true,
      message: 'Cause removed from saved items',
      data,
    });
  } catch (error) {
    next(error);
  }
};
