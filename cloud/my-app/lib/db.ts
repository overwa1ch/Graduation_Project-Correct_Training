import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';

// 使用环境变量或回退到硬编码配置
const client = process.env.DATABASE_URL 
	? postgres(process.env.DATABASE_URL, { ssl: { rejectUnauthorized: false } })
	: postgres({
		host: process.env.DB_HOST || 'db.wnobgdvinewicxgswtng.supabase.co',
		port: parseInt(process.env.DB_PORT || '5432'),
		database: process.env.DB_NAME || 'postgres',
		username: process.env.DB_USER || 'postgres',
		password: process.env.DB_PASSWORD || 'a-2087632828',
		ssl: { rejectUnauthorized: false },
	});

export const db = drizzle(client);


