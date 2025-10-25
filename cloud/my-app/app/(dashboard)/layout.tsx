import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { signoutAction } from "@/app/actions/auth";
import { Book, Users, LogOut } from "lucide-react";
import { redirect } from "next/navigation";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();
  if (!user) {
    redirect("/signin");
  }
  return (
    <div className="flex min-h-screen bg-zinc-50 text-zinc-900 dark:bg-black dark:text-zinc-50">
      <aside className="flex w-64 flex-col border-r border-zinc-200 bg-white p-4 dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mb-4 px-2 text-lg font-semibold">管理后台</div>
        <nav className="grid gap-1">
          <Link href="/books" className="flex items-center gap-2 rounded-md px-2 py-2 hover:bg-zinc-100 dark:hover:bg-zinc-900">
            <Book className="h-4 w-4" />
            单词书管理
          </Link>
          {user.isSystemAdmin && (
            <Link href="/admin-users" className="flex items-center gap-2 rounded-md px-2 py-2 hover:bg-zinc-100 dark:hover:bg-zinc-900">
              <Users className="h-4 w-4" />
              管理员管理
            </Link>
          )}
        </nav>
        <div className="mt-auto">
          <Separator className="my-4" />
          <div className="flex items-center justify-between gap-2 px-2 text-sm text-zinc-600 dark:text-zinc-400">
            <span className="truncate" title={user.email || undefined}>{user.email}</span>
            <form action={signoutAction}>
              <Button variant="ghost" size="icon" title="退出登录">
                <LogOut className="h-4 w-4" />
              </Button>
            </form>
          </div>
        </div>
      </aside>
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}


