"use client";

import { useActionState } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { signupAction, type ActionState } from "@/app/actions/auth";

const initialState: ActionState = {};

export default function SignupForm() {
  const [state, formAction] = useActionState(signupAction, initialState);
  return (
    <form action={formAction} className="grid gap-4">
      <div className="grid gap-2">
        <Label htmlFor="name">姓名</Label>
        <Input id="name" name="name" required placeholder="张三" />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="email">邮箱</Label>
        <Input id="email" name="email" type="email" required placeholder="you@example.com" />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="password">密码</Label>
        <Input id="password" name="password" type="password" required />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="confirm">确认密码</Label>
        <Input id="confirm" name="confirm" type="password" required />
      </div>
      {state?.error && (
        <div className="text-sm text-red-600">{state.error}</div>
      )}
      <Button type="submit" className="w-full">注册</Button>
    </form>
  );
}


