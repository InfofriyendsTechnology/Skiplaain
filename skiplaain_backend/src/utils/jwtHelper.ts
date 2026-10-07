import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'default_secret_change_in_production';

export interface JwtPayload {
  id: string;
  phone: string;
  type: 'customer' | 'partner' | 'admin';
}

class JwtHelper {
  // Generate JWT token
  generateToken(payload: JwtPayload, expiresIn: string = '30d'): string {
    return jwt.sign(payload, JWT_SECRET, { expiresIn });
  }

  // Verify JWT token
  verifyToken(token: string): JwtPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
      return decoded;
    } catch (error) {
      return null;
    }
  }
}

export default new JwtHelper();
