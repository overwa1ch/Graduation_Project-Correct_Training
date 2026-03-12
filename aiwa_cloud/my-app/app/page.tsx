import { getCurrentUserEmail, hasAnyAdmin } from "@/lib/auth";
import { redirect } from "next/navigation";
import Link from "next/link";

async function renderDbSetupPage(error: string) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-zinc-50 px-4 dark:bg-black">
      <div className="max-w-md rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
        <h1 className="text-xl font-semibold text-zinc-900 dark:text-zinc-100">
          数据库未就绪
        </h1>
        <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-400">{error}</p>
        <div className="mt-4 space-y-2 text-sm text-zinc-600 dark:text-zinc-400">
          <p className="font-medium">请按以下步骤操作：</p>
          <ol className="list-inside list-decimal space-y-1">
            <li>
              若使用 SQLite（<code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">file:</code> 或{" "}
              <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">sqlite:</code>）：运行{" "}
              <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">pnpm init-sqlite</code>
            </li>
            <li>
              若使用 PostgreSQL：启动数据库后执行{" "}
              <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">pnpm drizzle-kit push</code>
            </li>
            <li>刷新本页面</li>
          </ol>
          <p className="mt-2 text-xs">
            若无 PostgreSQL，可改用 SQLite（在 .env.local 中设置{" "}
            <code className="rounded bg-zinc-100 px-1 dark:bg-zinc-800">DATABASE_URL=file:./data/admin.db</code>
            ）或安装{" "}
            <a
              href="https://www.postgresql.org/download/windows/"
              className="underline"
              target="_blank"
              rel="noreferrer"
            >
              PostgreSQL
            </a>{" "}
            或使用{" "}
            <a
              href="https://supabase.com"
              className="underline"
              target="_blank"
              rel="noreferrer"
            >
              Supabase
            </a>{" "}
            免费云数据库。
          </p>
        </div>
        <Link
          href="/"
          className="mt-4 inline-block rounded-md bg-zinc-900 px-4 py-2 text-sm text-white hover:bg-zinc-800 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-zinc-200"
        >
          刷新重试
        </Link>
      </div>
    </div>
  );
}

export default async function Home() {
  let hasAdmin: boolean;
  try {
    hasAdmin = await hasAnyAdmin();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const cause = e instanceof Error && e.cause ? String(e.cause) : "";
    const isRefused = msg.includes("ECONNREFUSED") || cause.includes("ECONNREFUSED");
    return renderDbSetupPage(
      isRefused ? "无法连接 PostgreSQL，请确保数据库已启动。" : msg || "数据库连接失败"
    );
  }

  const email = await getCurrentUserEmail();
  if (email) {
    redirect("/books");
  }
  if (!hasAdmin) {
    redirect("/signup");
  }
  redirect("/signin");
}
