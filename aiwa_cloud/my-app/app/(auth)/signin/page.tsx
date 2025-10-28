import Link from "next/link";
import { redirect } from "next/navigation";
import { hasAnyAdmin } from "@/lib/auth";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { signinAction, type ActionState } from "@/app/actions/auth";
import SigninForm from "./signin-form";

export default async function SignInPage() {
  if (!(await hasAnyAdmin())) {
    redirect("/signup");
  }
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 px-4 dark:bg-black">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>管理员登录</CardTitle>
          <CardDescription>使用邮箱和密码登录</CardDescription>
        </CardHeader>
        <CardContent>
          <SigninForm />
          <p className="mt-4 text-sm text-zinc-600 dark:text-zinc-400">
            还没有账号？
            <Link href="/signup" className="ml-1 underline">
              立即注册
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}


