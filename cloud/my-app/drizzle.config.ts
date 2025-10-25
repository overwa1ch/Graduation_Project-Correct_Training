import 'dotenv/config';
import type { Config } from 'drizzle-kit';

// Parse DATABASE_URL manually to avoid URI parsing issues
function parseDatabaseUrl() {
	const url = process.env.DATABASE_URL;
	console.log('DATABASE_URL from env:', url ? 'SET' : 'NOT SET');
	
	if (!url) throw new Error('DATABASE_URL is not set');
	
	// Extract components using regex to avoid URL parsing issues
	const match = url.match(/postgres(?:ql)?:\/\/([^:]+):([^@]+)@([^:]+):(\d+)\/(.+)/);
	if (!match) throw new Error('Invalid DATABASE_URL format');
	
	const [, username, password, host, port, database] = match;
	console.log('Parsed credentials:', { username, host, port, database });
	
	return {
		host,
		port: parseInt(port),
		database,
		username,
		password,
		ssl: { rejectUnauthorized: false },
	};
}

export default {
	schema: './lib/schema.ts',
	out: './drizzle',
	dialect: 'postgresql',
	dbCredentials: process.env.DATABASE_URL ? {
		url: process.env.DATABASE_URL,
	} : {
		host: process.env.DB_HOST!,
		port: parseInt(process.env.DB_PORT || '5432'),
		database: process.env.DB_NAME || 'postgres',
		username: process.env.DB_USER || 'postgres',
		password: process.env.DB_PASSWORD!,
		ssl: { rejectUnauthorized: false },
	},
	verbose: true,
	strict: true,
} satisfies Config;


