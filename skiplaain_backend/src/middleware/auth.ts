import { Request, Response, NextFunction } from 'express';
import jwtHelper, { JwtPayload } from '../utils/jwtHelper';
import responseHandler from '../utils/responseHandler';

export interface AuthRequest extends Request {
  user?: JwtPayload;
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return responseHandler.unauthorized(res, 'No token provided');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const decoded = jwtHelper.verifyToken(token);

    if (!decoded) {
      return responseHandler.unauthorized(res, 'Invalid or expired token');
    }

    req.user = decoded;
    next();
  } catch (error) {
    return responseHandler.unauthorized(res, 'Authentication failed');
  }
};

// Role-based middleware
export const requireRole = (roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.type)) {
      return responseHandler.forbidden(res, 'Insufficient permissions');
    }
    next();
  };
};

// Owner or admin middleware for partner routes
export const requireOwnerOrAdmin = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user) {
    return responseHandler.unauthorized(res, 'Authentication required');
  }

  // Admin can access any partner
  if (req.user.type === 'admin') {
    return next();
  }

  // Partner can only access their own data
  if (req.user.type === 'partner') {
    const targetPartnerId = req.params.id || req.params.partnerId;
    
    // For /partner/* routes, use the JWT id directly
    if (req.path.startsWith('/partner') || !targetPartnerId) {
      return next();
    }
    
    // For /partners/:id routes, check ownership
    if (targetPartnerId !== req.user.id) {
      return responseHandler.forbidden(res, 'Access denied: you can only access your own data');
    }
    return next();
  }

  return responseHandler.forbidden(res, 'Insufficient permissions');
};
