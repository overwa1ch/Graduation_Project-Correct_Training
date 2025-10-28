import { cookies } from "next/headers";
import { createHash, randomUUID } from "crypto";
import { db } from "@/lib/db";
import { adminSessions, adminUsers } from "@/lib/schema";
import { and, count, eq, gt } from "drizzle-orm";

export type SessionUser = {
  id: string;
  name: string;
  email: string;
  isSystemAdmin: boolean;
};

function hashPassword(password: string): string {
  return createHash("sha256").update(password).digest("hex");
}

export async function hasAnyAdmin(): Promise<boolean> {
  const [row] = await db.select({ value: count() }).from(adminUsers);
  return (row?.value ?? 0) > 0;
}

export async function emailExists(email: string): Promise<boolean> {
  const [row] = await db
    .select({ value: count() })
    .from(adminUsers)
    .where(eq(adminUsers.email, email.toLowerCase()));
  return (row?.value ?? 0) > 0;
}

export async function createAdmin(
  name: string,
  email: string,
  password: string,
  isSystemAdmin: boolean,
): Promise<SessionUser> {
  if (!name || !email || !password) {
    throw new Error("缺少必要字段");
  }
  if (await emailExists(email)) {
    throw new Error("邮箱已被注册");
  }
  const [user] = await db
    .insert(adminUsers)
    .values({
      name,
      email: email.toLowerCase(),
      passwordHash: hashPassword(password),
      isSystemAdmin,
    })
    .returning({ id: adminUsers.id, name: adminUsers.name, email: adminUsers.email, isSystemAdmin: adminUsers.isSystemAdmin });
  return user;
}

export async function authenticate(email: string, password: string): Promise<SessionUser | null> {
  const [user] = await db
    .select({ id: adminUsers.id, name: adminUsers.name, email: adminUsers.email, passwordHash: adminUsers.passwordHash, isSystemAdmin: adminUsers.isSystemAdmin, isActive: adminUsers.isActive })
    .from(adminUsers)
    .where(eq(adminUsers.email, email.toLowerCase()))
    .limit(1);
  if (!user) return null;
  if (!user.isActive) return null;
  const isValid = user.passwordHash === hashPassword(password);
  if (!isValid) return null;
  return { id: user.id, name: user.name, email: user.email, isSystemAdmin: user.isSystemAdmin };
}

export async function setSession(userId: string) {
  const cookieStore = await cookies();
  const token = randomUUID();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  await db.insert(adminSessions).values({ userId, sessionToken: token, expiresAt });
  cookieStore.set("session", token, {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    secure: process.env.NODE_ENV === "production",
    expires: expiresAt,
  });
}

export async function clearSession() {
  const cookieStore = await cookies();
  const token = cookieStore.get("session")?.value;
  if (token) {
    await db.delete(adminSessions).where(eq(adminSessions.sessionToken, token));
  }
  cookieStore.delete("session");
}

export async function getCurrentUser(): Promise<SessionUser | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get("session")?.value;
  if (!token) return null;
  const now = new Date();
  const rows = await db
    .select({
      id: adminUsers.id,
      name: adminUsers.name,
      email: adminUsers.email,
      isSystemAdmin: adminUsers.isSystemAdmin,
      expiresAt: adminSessions.expiresAt,
    })
    .from(adminSessions)
    .innerJoin(adminUsers, eq(adminSessions.userId, adminUsers.id))
    .where(and(eq(adminSessions.sessionToken, token), gt(adminSessions.expiresAt, now)))
    .limit(1);
  const row = rows[0];
  if (!row) return null;
  return { id: row.id, name: row.name, email: row.email, isSystemAdmin: row.isSystemAdmin };
}

export async function getCurrentUserEmail(): Promise<string | null> {
  const user = await getCurrentUser();
  return user?.email ?? null;
}

export async function listAdmins(): Promise<Array<{ id: string; name: string; email: string; isSystemAdmin: boolean; isActive: boolean }>> {
  const rows = await db
    .select({ id: adminUsers.id, name: adminUsers.name, email: adminUsers.email, isSystemAdmin: adminUsers.isSystemAdmin, isActive: adminUsers.isActive })
    .from(adminUsers);
  return rows;
}

