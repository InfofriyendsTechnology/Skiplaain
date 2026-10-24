import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET environment variable is not set');
  process.exit(1);
}

export interface JwtPayload {
  id: string;
  phone: string;
  type: 'customer' | 'partner' | 'admin';
  name?: string;
}

class JwtHelper {
  // Generate JWT token
  generateToken(payload: JwtPayload, expiresIn: string = '30d'): string {
    return jwt.sign(payload, JWT_SECRET!, { expiresIn } as jwt.SignOptions);
  }

  // Verify JWT token
  verifyToken(token: string): JwtPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET!) as jwt.JwtPayload;
      return decoded as JwtPayload;
    } catch (error) {
      return null;
    }
  }
}

export default new JwtHelper();
