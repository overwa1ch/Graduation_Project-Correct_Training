import { sql } from "drizzle-orm";
import {
  boolean,
  jsonb,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";

export const adminUsers = pgTable("admin-users", {
  id: uuid("id").default(sql`gen_random_uuid()`).primaryKey().notNull(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  isSystemAdmin: boolean("is_system_admin").notNull().default(false),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: false }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: false }).notNull().defaultNow(),
});

export const adminSessions = pgTable("admin-session", {
  id: uuid("id").default(sql`gen_random_uuid()`).primaryKey().notNull(),
  userId: uuid("user_id").notNull().references(() => adminUsers.id, { onDelete: "cascade" }),
  sessionToken: text("session_token").notNull().unique(),
  expiresAt: timestamp("expires_at", { withTimezone: false }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: false }).notNull().defaultNow(),
});

export const adminLoginLogs = pgTable("admin_login_logs", {
  id: uuid("id").default(sql`gen_random_uuid()`).primaryKey().notNull(),
  adminUserId: uuid("admin_user_id").references(() => adminUsers.id, { onDelete: "set null" }),
  success: boolean("success").notNull(),
  ipAddress: text("ip_address"),
  emailAttempted: text("email_attempted"),
  createdAt: timestamp("created_at", { withTimezone: false }).defaultNow(),
});

export const adminOperationLogs = pgTable("admin_operation_logs", {
  id: uuid("id").default(sql`gen_random_uuid()`).primaryKey().notNull(),
  adminUserId: uuid("admin_user_id").notNull().references(() => adminUsers.id, { onDelete: "cascade" }),
  action: text("action").notNull(),
  targetType: text("target_type"),
  targetId: text("target_id"),
  details: jsonb("details"),
  createdAt: timestamp("created_at", { withTimezone: false }).defaultNow(),
});
