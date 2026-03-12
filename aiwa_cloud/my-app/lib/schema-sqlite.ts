import { sql } from "drizzle-orm";
import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

export const adminUsers = sqliteTable("admin-users", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  isSystemAdmin: integer("is_system_admin", { mode: "boolean" }).notNull().default(false),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  createdAt: text("created_at").default(sql`(datetime('now'))`).notNull(),
  updatedAt: text("updated_at").default(sql`(datetime('now'))`).notNull(),
});

export const adminSessions = sqliteTable("admin-session", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  userId: text("user_id").notNull().references(() => adminUsers.id, { onDelete: "cascade" }),
  sessionToken: text("session_token").notNull().unique(),
  expiresAt: text("expires_at").notNull(),
  createdAt: text("created_at").default(sql`(datetime('now'))`).notNull(),
});

export const adminLoginLogs = sqliteTable("admin_login_logs", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  adminUserId: text("admin_user_id").references(() => adminUsers.id, { onDelete: "set null" }),
  success: integer("success", { mode: "boolean" }).notNull(),
  ipAddress: text("ip_address"),
  emailAttempted: text("email_attempted"),
  createdAt: text("created_at").default(sql`(datetime('now'))`),
});

export const adminOperationLogs = sqliteTable("admin_operation_logs", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  adminUserId: text("admin_user_id").notNull().references(() => adminUsers.id, { onDelete: "cascade" }),
  action: text("action").notNull(),
  targetType: text("target_type"),
  targetId: text("target_id"),
  details: text("details"),
  createdAt: text("created_at").default(sql`(datetime('now'))`),
});
