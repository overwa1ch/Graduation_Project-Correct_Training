"use server";

import { db } from "@/lib/db";
import { adminUsers } from "@/lib/schema";
import { and, eq, not, count } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { getCurrentUser } from "@/lib/auth";
import { createHash } from "crypto";

function hashPassword(password: string): string {
  return createHash("sha256").update(password).digest("hex");
}

async function emailExists(email: string): Promise<boolean> {
  const [row] = await db
    .select({ value: count() })
    .from(adminUsers)
    .where(eq(adminUsers.email, email));
  return (row?.value ?? 0) > 0;
}

export type AdminActionResult = {
  error?: string;
  success?: boolean;
};

export async function createAdminUser(_: any, formData: FormData): Promise<AdminActionResult> {
  const current = await getCurrentUser();
  if (!current || !current.isSystemAdmin) {
    return { error: "无权限" };
  }
  const name = String(formData.get("name") || "").trim();
  const email = String(formData.get("email") || "").trim().toLowerCase();
  const password = String(formData.get("password") || "");
  const isSystemAdmin = formData.has("isSystemAdmin");
  const isActive = formData.has("isActive");

  if (!name || !email || !password) return { error: "请填写完整信息" };
  
  // 检查邮箱是否已存在
  if (await emailExists(email)) {
    return { error: "该邮箱已被注册" };
  }
  
  try {
    await db.insert(adminUsers).values({
      name,
      email,
      passwordHash: hashPassword(password),
      isSystemAdmin,
      isActive,
    });
  } catch (e: any) {
    console.error("=== 数据库插入错误 ===");
    console.error("错误信息:", e);
    
    // 处理特定的数据库错误
    if (e.code === '23505') {
      return { error: "该邮箱已被注册" };
    }
    
    return { error: e?.message || "创建失败" };
  }
  revalidatePath("/admin-users");
  return { success: true };
}

export async function updateAdminUser(_: any, formData: FormData): Promise<AdminActionResult> {
  const current = await getCurrentUser();
  if (!current || !current.isSystemAdmin) {
    return { error: "无权限" };
  }
  const id = String(formData.get("id") || "");
  const name = String(formData.get("name") || "").trim();
  const email = String(formData.get("email") || "").trim().toLowerCase();
  const password = String(formData.get("password") || "");
  const isSystemAdmin = formData.has("isSystemAdmin");
  const isActive = formData.has("isActive");

  if (!id || !name || !email) return { error: "缺少必要信息" };

  // 系统管理员不能修改自己的状态和角色
  const canEditOwnRoleOrStatus = id === current.id && (formData.has("isSystemAdmin") || formData.has("isActive"));
  if (canEditOwnRoleOrStatus) {
    return { error: "系统管理员不能修改自己的角色或状态" };
  }

  // 检查邮箱是否已被其他用户使用
  const [existingUser] = await db
    .select({ id: adminUsers.id })
    .from(adminUsers)
    .where(and(eq(adminUsers.email, email), not(eq(adminUsers.id, id))))
    .limit(1);
  
  if (existingUser) {
    return { error: "该邮箱已被其他用户使用" };
  }

  try {
    const update: any = { name, email };
    if (password) update.passwordHash = hashPassword(password);
    if (id !== current.id) {
      update.isSystemAdmin = isSystemAdmin;
      update.isActive = isActive;
    }
    await db.update(adminUsers).set(update).where(eq(adminUsers.id, id));
  } catch (e: any) {
    console.error("=== 数据库更新错误 ===");
    console.error("错误信息:", e);
    
    // 处理特定的数据库错误
    if (e.code === '23505') {
      return { error: "该邮箱已被其他用户使用" };
    }
    
    return { error: e?.message || "更新失败" };
  }
  revalidatePath("/admin-users");
  return { success: true };
}


