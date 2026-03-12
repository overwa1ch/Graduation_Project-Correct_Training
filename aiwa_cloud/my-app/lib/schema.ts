import * as pgSchema from "./schema-pg";
import * as sqliteSchema from "./schema-sqlite";

const useSqlite =
  process.env.DATABASE_URL?.startsWith("file:") ||
  process.env.DATABASE_URL?.startsWith("sqlite:");

export const adminUsers = useSqlite ? sqliteSchema.adminUsers : pgSchema.adminUsers;
export const adminSessions = useSqlite ? sqliteSchema.adminSessions : pgSchema.adminSessions;
export const adminLoginLogs = useSqlite ? sqliteSchema.adminLoginLogs : pgSchema.adminLoginLogs;
export const adminOperationLogs = useSqlite ? sqliteSchema.adminOperationLogs : pgSchema.adminOperationLogs;
