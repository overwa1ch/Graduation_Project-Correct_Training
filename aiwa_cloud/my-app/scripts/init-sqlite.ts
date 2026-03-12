/**
 * 初始化 SQLite 数据库表结构
 * 运行: pnpm init-sqlite
 */
import { createClient } from "@libsql/client";
import * as fs from "fs";
import * as path from "path";
import { config } from "dotenv";

config({ path: ".env.local" });

const url = process.env.DATABASE_URL ?? "file:./data/admin.db";
const dbPath = url.startsWith("file:") ? url : `file:${path.resolve(process.cwd(), url)}`;

const dir = path.dirname(dbPath.replace(/^file:/, ""));
const absDir = path.isAbsolute(dir) ? dir : path.resolve(process.cwd(), dir);
if (!fs.existsSync(absDir)) {
  fs.mkdirSync(absDir, { recursive: true });
}

const client = createClient({ url: dbPath });

const sql = `
  CREATE TABLE IF NOT EXISTS "admin-users" (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    is_system_admin INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS "admin-session" (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES "admin-users"(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS "admin_login_logs" (
    id TEXT PRIMARY KEY,
    admin_user_id TEXT REFERENCES "admin-users"(id) ON DELETE SET NULL,
    success INTEGER NOT NULL,
    ip_address TEXT,
    email_attempted TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );
  CREATE TABLE IF NOT EXISTS "admin_operation_logs" (
    id TEXT PRIMARY KEY,
    admin_user_id TEXT NOT NULL REFERENCES "admin-users"(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    target_type TEXT,
    target_id TEXT,
    details TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );
`;

async function main() {
  await client.executeMultiple(sql);
  console.log("SQLite 表已创建:", dbPath);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
