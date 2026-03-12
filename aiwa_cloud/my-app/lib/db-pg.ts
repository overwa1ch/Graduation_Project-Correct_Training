import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

if (!process.env.DATABASE_URL && !process.env.DB_HOST) {
  throw new Error(
    "DATABASE_URL or DB_HOST must be set in environment variables. " +
    "Please configure your database connection in .env file."
  );
}

const client = process.env.DATABASE_URL
  ? postgres(process.env.DATABASE_URL, { ssl: { rejectUnauthorized: false } })
  : postgres({
      host: process.env.DB_HOST!,
      port: parseInt(process.env.DB_PORT || "5432"),
      database: process.env.DB_NAME || "postgres",
      username: process.env.DB_USER || "postgres",
      password: process.env.DB_PASSWORD!,
      ssl: { rejectUnauthorized: false },
    });

export const db = drizzle(client);
