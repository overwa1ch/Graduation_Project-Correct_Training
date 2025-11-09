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
  userId: string;
  email: string;
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
  async refresh(refreshToken: string): Promise<{ userId: string; email: string }> {
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

    // Return user info for JWT generation
    return { userId: user.id, email: user.email };
  }

  // Generate tokens
  private async generateTokens(userId: string, email: string): Promise<AuthTokens> {
    const refreshToken = await this.generateRefreshToken(userId);

    return { userId, email, refreshToken };
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
  // 注意：此方法当前未使用，保留用于未来实现登出功能
  async revokeRefreshToken(token: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { token },
      data: { revokedAt: new Date() },
    });
  }

  // Revoke all user's refresh tokens (logout all devices)
  // 注意：此方法当前未使用，保留用于未来实现"登出所有设备"功能
  async revokeAllUserTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}

