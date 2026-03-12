/**
 * 重置管理员密码
 * 运行: pnpm exec tsx scripts/reset-admin-password.ts
 * 用法: pnpm exec tsx scripts/reset-admin-password.ts [新密码]
 * 默认新密码: admin123
 */
import "dotenv/config";
import { config } from "dotenv";
import * as path from "path";
import bcrypt from "bcrypt";
import { createClient } from "@libsql/client";

config({ path: ".env.local" });

const url = process.env.DATABASE_URL ?? "file:./data/admin.db";
const dbPath = url.startsWith("file:") ? url : `file:${path.resolve(process.cwd(), url)}`;
const client = createClient({ url: dbPath });

const newPassword = process.argv[2] || "admin123";
const SALT_ROUNDS = 10;
const hash = bcrypt.hashSync(newPassword, SALT_ROUNDS);

async function main() {
  const result = await client.execute({
    sql: 'UPDATE "admin-users" SET password_hash = ? WHERE email = ?',
    args: [hash, "admin@example.com"],
  });
  if (result.rowsAffected > 0) {
    console.log("密码已重置成功");
    console.log("邮箱: admin@example.com");
    console.log("新密码:", newPassword);
  } else {
    console.log("未找到 admin@example.com，请检查数据库");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
