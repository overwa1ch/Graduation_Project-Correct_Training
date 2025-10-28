"use server";

import { redirect } from "next/navigation";
import {
  authenticate,
  clearSession,
  createAdmin,
  emailExists,
  setSession,
  hasAnyAdmin,
} from "@/lib/auth";

export type ActionState = {
  error?: string;
};

export async function signupAction(_: ActionState, formData: FormData): Promise<ActionState> {
  const alreadyHasAdmin = await hasAnyAdmin();
  if (alreadyHasAdmin) {
    redirect("/signin");
  }

  const name = String(formData.get("name") || "").trim();
  const email = String(formData.get("email") || "").trim();
  const password = String(formData.get("password") || "");
  const confirm = String(formData.get("confirm") || "");

  if (!name || !email || !password || !confirm) {
    return { error: "请填写所有字段" };
  }
  if (password.length < 6) {
    return { error: "密码长度至少为6位" };
  }
  if (password !== confirm) {
    return { error: "两次输入的密码不一致" };
  }
  if (await emailExists(email)) {
    return { error: "邮箱已被注册" };
  }

  try {
    const user = await createAdmin(name, email, password, true);
    await setSession(user.id);
  } catch (e: any) {
    return { error: e?.message || "注册失败" };
  }

  redirect("/books");
}

export async function signinAction(_: ActionState, formData: FormData): Promise<ActionState> {
  const alreadyHasAdmin = await hasAnyAdmin();
  if (!alreadyHasAdmin) {
    redirect("/signup");
  }

  const email = String(formData.get("email") || "").trim();
  const password = String(formData.get("password") || "");

  if (!email || !password) {
    return { error: "请输入邮箱和密码" };
  }
  const user = await authenticate(email, password);
  if (!user) {
    return { error: "邮箱或密码错误" };
  }
  await setSession(user.id);
  redirect("/books");
}

export async function signoutAction() {
  await clearSession();
  redirect("/signin");
}


