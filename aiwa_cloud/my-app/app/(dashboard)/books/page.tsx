import Link from "next/link";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { UserCircle, Users, FileText, Activity } from "lucide-react";

export default function BooksPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">管理概览</h1>
      <p className="text-sm text-zinc-600 dark:text-zinc-400">
        AIWA 健身姿态纠正管理后台。从下方入口管理用户、管理员及查看系统日志。
      </p>
      <div className="grid gap-4 md:grid-cols-2">
        <Link href="/users">
          <Card className="transition-colors hover:bg-zinc-50 dark:hover:bg-zinc-900/50">
            <CardHeader>
              <UserCircle className="h-8 w-8 text-zinc-500" />
              <CardTitle>用户管理</CardTitle>
              <CardDescription>查看、启用/禁用应用用户</CardDescription>
            </CardHeader>
          </Card>
        </Link>
        <Link href="/admin-users">
          <Card className="transition-colors hover:bg-zinc-50 dark:hover:bg-zinc-900/50">
            <CardHeader>
              <Users className="h-8 w-8 text-zinc-500" />
              <CardTitle>管理员管理</CardTitle>
              <CardDescription>管理系统管理员账号</CardDescription>
            </CardHeader>
          </Card>
        </Link>
        <Link href="/logs/login">
          <Card className="transition-colors hover:bg-zinc-50 dark:hover:bg-zinc-900/50">
            <CardHeader>
              <FileText className="h-8 w-8 text-zinc-500" />
              <CardTitle>登录日志</CardTitle>
              <CardDescription>查看管理员登录记录</CardDescription>
            </CardHeader>
          </Card>
        </Link>
        <Link href="/logs/operations">
          <Card className="transition-colors hover:bg-zinc-50 dark:hover:bg-zinc-900/50">
            <CardHeader>
              <Activity className="h-8 w-8 text-zinc-500" />
              <CardTitle>操作日志</CardTitle>
              <CardDescription>查看管理员操作记录</CardDescription>
            </CardHeader>
          </Card>
        </Link>
      </div>
    </div>
  );
}


