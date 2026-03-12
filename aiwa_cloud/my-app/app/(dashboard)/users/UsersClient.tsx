"use client";

import * as React from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { updateUserStatusAction } from "@/app/actions/users";
import type { AppUser } from "@/lib/core-api";

export default function UsersClient({
  users,
  search,
  page,
  totalPages,
  total,
}: {
  users: AppUser[];
  search: string;
  page: number;
  totalPages: number;
  total: number;
}) {
  const [searchVal, setSearchVal] = React.useState(search);
  const [pending, setPending] = React.useState<string | null>(null);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const params = new URLSearchParams();
    if (searchVal.trim()) params.set("search", searchVal.trim());
    params.set("page", "1");
    window.location.href = `/users?${params.toString()}`;
  };

  const handleStatusChange = (userId: string, status: "active" | "inactive" | "suspended") => {
    setPending(userId);
    const fd = new FormData();
    fd.set("userId", userId);
    fd.set("status", status);
    updateUserStatusAction({}, fd).finally(() => setPending(null));
  };

  const formatDate = (s: string | null) =>
    s ? new Date(s).toLocaleString("zh-CN") : "-";

  return (
    <>
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-semibold">用户管理</h1>
        <form onSubmit={handleSearch} className="flex gap-2">
          <Input
            placeholder="搜索用户 ID / 邮箱 / 昵称"
            value={searchVal}
            onChange={(e) => setSearchVal(e.target.value)}
            className="w-64"
          />
          <Button type="submit">搜索</Button>
        </form>
      </div>

      <div className="text-sm text-zinc-500 dark:text-zinc-400">
        共 {total} 个用户
      </div>

      <div className="overflow-x-auto rounded-lg border border-zinc-200 dark:border-zinc-800">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-zinc-200 bg-zinc-50/60 text-zinc-500 dark:border-zinc-800 dark:bg-zinc-900/30 dark:text-zinc-400">
            <tr>
              <th className="py-2 pl-4">用户 ID</th>
              <th className="py-2">邮箱</th>
              <th className="py-2">昵称</th>
              <th className="py-2">状态</th>
              <th className="py-2">注册时间</th>
              <th className="py-2">最近登录</th>
              <th className="py-2 pr-4 text-right">操作</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr
                key={u.id}
                className="border-b border-zinc-100 last:border-0 dark:border-zinc-900"
              >
                <td className="py-2 pl-4 font-mono text-xs">{u.id.slice(0, 8)}...</td>
                <td className="py-2">{u.email}</td>
                <td className="py-2">{u.name || "-"}</td>
                <td className="py-2">{u.status === "active" ? "启用" : u.status === "suspended" ? "停用" : "未激活"}</td>
                <td className="py-2">{formatDate(u.createdAt)}</td>
                <td className="py-2">{formatDate(u.lastLoginAt)}</td>
                <td className="py-2 pr-4 text-right">
                  {u.status === "active" ? (
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={!!pending}
                      onClick={() => handleStatusChange(u.id, "inactive")}
                    >
                      {pending === u.id ? "处理中" : "禁用"}
                    </Button>
                  ) : (
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={!!pending}
                      onClick={() => handleStatusChange(u.id, "active")}
                    >
                      {pending === u.id ? "处理中" : "启用"}
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex justify-center gap-2 pt-4">
          {page > 1 && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                const params = new URLSearchParams();
                if (search) params.set("search", search);
                params.set("page", String(page - 1));
                window.location.href = `/users?${params.toString()}`;
              }}
            >
              上一页
            </Button>
          )}
          <span className="flex items-center px-2 text-sm">
            {page} / {totalPages}
          </span>
          {page < totalPages && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                const params = new URLSearchParams();
                if (search) params.set("search", search);
                params.set("page", String(page + 1));
                window.location.href = `/users?${params.toString()}`;
              }}
            >
              下一页
            </Button>
          )}
        </div>
      )}
    </>
  );
}
