import { getCurrentUser } from "@/lib/auth";
import { listUsers } from "@/lib/core-api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { redirect } from "next/navigation";
import UsersClient from "./UsersClient";

type Props = { searchParams: Promise<{ search?: string; page?: string }> };

export default async function UsersPage({ searchParams }: Props) {
  const user = await getCurrentUser();
  if (!user) redirect("/signin");

  const params = await searchParams;
  const search = params.search ?? "";
  const page = Math.max(1, parseInt(params.page || "1", 10) || 1);

  let data;
  try {
    data = await listUsers({ search: search || undefined, page, limit: 20 });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "未知错误";
    const isConfig = msg.includes("ADMIN_API_KEY") || msg.includes("Admin API is not configured");
    const is500 = msg.includes("500") || msg.includes("INTERNAL_ERROR");
    const cause = e instanceof Error && e.cause ? String(e.cause) : "";
    const isRefused =
      msg.includes("ECONNREFUSED") ||
      msg.includes("fetch failed") ||
      cause.includes("ECONNREFUSED");
    return (
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>用户管理</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-destructive">
              {isRefused
                ? "无法连接 core-api，请确保 core-api 已启动（如 pnpm dev）。"
                : isConfig
                  ? "Admin API 未配置：请在 core-api 的 .env 中设置 ADMIN_API_KEY（至少 32 字符），并与 my-app 的 .env.local 保持一致。"
                  : is500
                    ? "core-api 返回 500 错误，请检查 core-api 日志。常见原因：数据库未初始化（运行 prisma db push）、或 schema 与数据库不匹配。"
                    : "无法连接 core-api，请检查 API_BASE_URL 和 ADMIN_API_KEY 配置。"}
            </p>
            <p className="mt-2 text-sm text-zinc-500">{msg}</p>
            <div className="mt-4 space-y-1 text-sm text-zinc-600 dark:text-zinc-400">
              <p className="font-medium">快速修复：</p>
              <ol className="list-inside list-decimal space-y-1">
                <li>进入 aiwa_cloud/core-api，运行 <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">.\setup-sqlite.ps1</code> 或 <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">pnpm prisma db push</code></li>
                <li>确认 .env 中有 <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">ADMIN_API_KEY=dev_admin_key_32_chars_minimum_here</code></li>
                <li>启动 core-api：<code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">pnpm dev</code></li>
                <li>确认 my-app 的 API_BASE_URL 与 core-api 端口一致（如 http://localhost:3001）</li>
              </ol>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>系统用户</CardTitle>
        </CardHeader>
        <CardContent>
          <UsersClient
            users={data.data}
            search={search}
            page={data.meta.page}
            totalPages={data.meta.totalPages}
            total={data.meta.total}
          />
        </CardContent>
      </Card>
    </div>
  );
}
