"use server";

import { redirect } from "next/navigation";
import { adminUsers } from "@/lib/schema";
import { db } from "@/lib/db";
import { createAdmin, getCurrentUser } from "@/lib/auth";
import { eq } from "drizzle-orm";

export type AdminActionState = {
  error?: string;
};

export async function createAdminAction(_: AdminActionState, formData: FormData): Promise<AdminActionState> {
  const user = await getCurrentUser();
  if (!user) redirect("/signin");
  if (!user.isSystemAdmin) return { error: "无权限" };

  const name = String(formData.get("name") || "").trim();
  const email = String(formData.get("email") || "").trim();
  const password = String(formData.get("password") || "");
  const isSystemAdmin = String(formData.get("isSystemAdmin") || "false") === "true";

  if (!name || !email || !password) {
    return { error: "请填写所有字段" };
  }

  try {
    await createAdmin(name, email, password, isSystemAdmin);
  } catch (e: any) {
    return { error: e?.message || "创建失败" };
  }

  redirect("/admin-users");
}

export async function updateAdminAction(_: AdminActionState, formData: FormData): Promise<AdminActionState> {
  const user = await getCurrentUser();
  if (!user) redirect("/signin");
  if (!user.isSystemAdmin) return { error: "无权限" };

  const id = String(formData.get("id") || "");
  const isSystemAdmin = String(formData.get("isSystemAdmin") || "false") === "true";

  if (!id) return { error: "缺少ID" };

  try {
    await db.update(adminUsers).set({ isSystemAdmin }).where(eq(adminUsers.id, id));
  } catch (e: any) {
    return { error: e?.message || "更新失败" };
  }

  redirect("/admin-users");
}


