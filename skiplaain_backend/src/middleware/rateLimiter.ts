import { Request, Response, NextFunction } from 'express';

// Simple in-memory rate limiter (for production, use Redis)
const requestCounts = new Map<string, { count: number; resetTime: number }>();

const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const MAX_REQUESTS = 10; // 10 requests per minute

export const rateLimiter = (req: Request, res: Response, next: NextFunction) => {
  const identifier = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  
  const record = requestCounts.get(identifier);
  
  if (!record || now > record.resetTime) {
    // New window
    requestCounts.set(identifier, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW,
    });
    return next();
  }
  
  if (record.count >= MAX_REQUESTS) {
    return res.status(429).json({
      success: false,
      message: 'Too many requests. Please try again later.',
      retryAfter: Math.ceil((record.resetTime - now) / 1000),
    });
  }
  
  record.count++;
  next();
};

// Stricter rate limit for auth endpoints
export const authRateLimiter = (req: Request, res: Response, next: NextFunction) => {
  const identifier = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  
  const record = requestCounts.get(`auth_${identifier}`);
  
  if (!record || now > record.resetTime) {
    requestCounts.set(`auth_${identifier}`, {
      count: 1,
      resetTime: now + RATE_LIMIT_WINDOW,
    });
    return next();
  }
  
  if (record.count >= 5) {
    return res.status(429).json({
      success: false,
      message: 'Too many authentication attempts. Please try again in a minute.',
      retryAfter: Math.ceil((record.resetTime - now) / 1000),
    });
  }
  
  record.count++;
  next();
};

// Cleanup old entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of requestCounts.entries()) {
    if (now > value.resetTime) {
      requestCounts.delete(key);
    }
  }
}, 5 * 60 * 1000);
