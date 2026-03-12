"use server";

import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { updateUserStatus } from "@/lib/core-api";
import { db } from "@/lib/db";
import { adminOperationLogs } from "@/lib/schema";

export type UserActionState = { error?: string };

export async function updateUserStatusAction(
  _: UserActionState,
  formData: FormData
): Promise<UserActionState> {
  const user = await getCurrentUser();
  if (!user) redirect("/signin");

  const userId = String(formData.get("userId") || "");
  const status = String(formData.get("status") || "") as "active" | "inactive" | "suspended";

  if (!userId || !["active", "inactive", "suspended"].includes(status)) {
    return { error: "参数无效" };
  }

  try {
    await updateUserStatus(userId, status);

    await db.insert(adminOperationLogs).values({
      adminUserId: user.id,
      action: "user_status_update",
      targetType: "user",
      targetId: userId,
      details: { status },
    });
  } catch (e: unknown) {
    return { error: e instanceof Error ? e.message : "更新失败" };
  }

  redirect("/users");
}
