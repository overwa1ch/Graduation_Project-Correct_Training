/**
 * 调用 core-api 的 admin 接口
 * 服务端使用，携带 ADMIN_API_KEY 鉴权
 */

const API_BASE = process.env.API_BASE_URL || "http://localhost:3001";

function getHeaders(): HeadersInit {
  const key = process.env.ADMIN_API_KEY;
  if (!key) {
    throw new Error("ADMIN_API_KEY is not set");
  }
  return {
    "Content-Type": "application/json",
    "X-Admin-Key": key,
  };
}

export type AppUser = {
  id: string;
  email: string;
  name: string | null;
  status: string;
  createdAt: string;
  lastLoginAt: string | null;
};

export type ListUsersResponse = {
  data: AppUser[];
  meta: { total: number; page: number; limit: number; totalPages: number };
};

export async function listUsers(params: {
  search?: string;
  page?: number;
  limit?: number;
}): Promise<ListUsersResponse> {
  const sp = new URLSearchParams();
  if (params.search) sp.set("search", params.search);
  if (params.page) sp.set("page", String(params.page));
  if (params.limit) sp.set("limit", String(params.limit));
  const qs = sp.toString();
  const url = `${API_BASE}/v1/admin/users${qs ? `?${qs}` : ""}`;
  const res = await fetch(url, { headers: getHeaders(), cache: "no-store" });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message || `API error: ${res.status}`);
  }
  return res.json();
}

export async function updateUserStatus(
  userId: string,
  status: "active" | "inactive" | "suspended"
): Promise<{ data: AppUser }> {
  const res = await fetch(`${API_BASE}/v1/admin/users/${userId}/status`, {
    method: "PATCH",
    headers: getHeaders(),
    body: JSON.stringify({ status }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message || `API error: ${res.status}`);
  }
  return res.json();
}
