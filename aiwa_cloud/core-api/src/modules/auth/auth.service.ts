import { prisma } from '../../lib/prisma';
import { hashPassword, verifyPassword } from '../../lib/crypto';
import crypto from 'crypto';

export interface RegisterInput {
  email: string;
  password: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export class AuthService {
  // Register new user
  async register(input: RegisterInput): Promise<AuthTokens> {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    if (existingUser) {
      throw new Error('User already exists');
    }

    // Hash password
    const passwordHash = await hashPassword(input.password);

    // Create user
    const user = await prisma.user.create({
      data: {
        email: input.email.toLowerCase(),
        passwordHash,
        status: 'active',
      },
    });

    // Generate tokens
    return this.generateTokens(user.id, user.email);
  }

  // Login user
  async login(input: LoginInput): Promise<AuthTokens> {
    // Find user
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase() },
    });

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Check if user is active
    if (user.status !== 'active') {
      throw new Error('Account is not active');
    }

    // Verify password
    const isValid = await verifyPassword(input.password, user.passwordHash);
    if (!isValid) {
      throw new Error('Invalid credentials');
    }

    // Generate tokens
    return this.generateTokens(user.id, user.email);
  }

  // Refresh access token
  async refresh(refreshToken: string): Promise<{ accessToken: string }> {
    // Find refresh token
    const token = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });

    if (!token || token.revokedAt) {
      throw new Error('Invalid refresh token');
    }

    // Check if expired
    if (token.expiresAt < new Date()) {
      throw new Error('Refresh token expired');
    }

    // Get user
    const user = await prisma.user.findUnique({
      where: { id: token.userId },
    });

    if (!user || user.status !== 'active') {
      throw new Error('User not found or inactive');
    }

    // Generate new access token
    const accessToken = this.generateAccessToken(user.id, user.email);

    return { accessToken };
  }

  // Generate tokens
  private async generateTokens(userId: string, email: string): Promise<AuthTokens> {
    const accessToken = this.generateAccessToken(userId, email);
    const refreshToken = await this.generateRefreshToken(userId);

    return { accessToken, refreshToken };
  }

  // Generate access token (JWT)
  private generateAccessToken(userId: string, email: string): string {
    // In production, use RS256 with private key
    // For now, using HS256 with secret
    const payload = {
      sub: userId,
      email,
      type: 'access',
    };

    // This would be signed with RS256 in production
    // For simplicity, we'll use the JWT library in the controller
    return JSON.stringify(payload); // Placeholder - actual signing happens in controller
  }

  // Generate refresh token
  private async generateRefreshToken(userId: string): Promise<string> {
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days

    await prisma.refreshToken.create({
      data: {
        userId,
        token,
        expiresAt,
      },
    });

    return token;
  }

  // Revoke refresh token (logout)
  async revokeRefreshToken(token: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { token },
      data: { revokedAt: new Date() },
    });
  }

  // Revoke all user's refresh tokens (logout all devices)
  async revokeAllUserTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}

