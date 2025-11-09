import { config } from 'dotenv';

config();

export const CONFIG = {
  port: parseInt(process.env.PORT || '8080', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  
  database: {
    url: process.env.DATABASE_URL!,
  },
  
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET!,
    // 注意：refreshSecret 当前未使用（refresh token 是随机字符串存储在数据库中）
    // 保留此配置以便未来可能需要 JWT 签名的 refresh token
    refreshSecret: process.env.JWT_REFRESH_SECRET!,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },
  
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
  
  // 注意：rateLimit 配置当前未使用（未实现 rate limiting 中间件）
  // 如需启用，请安装 @fastify/rate-limit 并在 main.ts 中注册
  rateLimit: {
    max: parseInt(process.env.RATE_LIMIT_MAX || '60', 10),
    timeWindow: process.env.RATE_LIMIT_WINDOW || '1m',
  },

  // 阿里云配置（可选，用于后续扩展文件存储功能）
  aliyun: {
    enabled: process.env.USE_ALIYUN_OSS === 'true',
    region: process.env.ALIYUN_REGION || 'oss-cn-hangzhou',
    accessKeyId: process.env.ALIYUN_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.ALIYUN_SECRET_ACCESS_KEY || '',
    oss: {
      bucket: process.env.ALIYUN_OSS_BUCKET || '',
      presignedUrlExpiration: parseInt(process.env.ALIYUN_OSS_PRESIGNED_EXPIRATION || '900', 10),
    },
  },
} as const;

// Validate required environment variables
const requiredEnvVars = [
  'DATABASE_URL',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
];

// 如果启用阿里云 OSS，验证相关配置
if (CONFIG.aliyun.enabled) {
  requiredEnvVars.push(
    'ALIYUN_ACCESS_KEY_ID',
    'ALIYUN_SECRET_ACCESS_KEY',
    'ALIYUN_OSS_BUCKET'
  );
}

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`);
  }
}

