const useSqlite =
  process.env.DATABASE_URL?.startsWith("file:") ||
  process.env.DATABASE_URL?.startsWith("sqlite:");

export const db = useSqlite
  ? (await import("./db-sqlite")).db
  : (await import("./db-pg")).db;
