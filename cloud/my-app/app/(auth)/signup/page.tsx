import Link from "next/link";
import { redirect } from "next/navigation";
import { hasAnyAdmin } from "@/lib/auth";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import SignupForm from "./signup-form";

export default async function SignUpPage() {
  if (await hasAnyAdmin()) {
    redirect("/signin");
  }
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 px-4 dark:bg-black">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>管理员注册</CardTitle>
          <CardDescription>创建系统管理员账号</CardDescription>
        </CardHeader>
        <CardContent>
          <SignupForm />
          <p className="mt-4 text-sm text-zinc-600 dark:text-zinc-400">
            已有账号？
            <Link href="/signin" className="ml-1 underline">
              去登录
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}


