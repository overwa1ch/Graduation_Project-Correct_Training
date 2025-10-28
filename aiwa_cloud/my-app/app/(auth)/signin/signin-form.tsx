"use client";

import { useActionState } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { signinAction, type ActionState } from "@/app/actions/auth";

const initialState: ActionState = {};

export default function SigninForm() {
  const [state, formAction] = useActionState(signinAction, initialState);
  return (
    <form action={formAction} className="grid gap-4">
      <div className="grid gap-2">
        <Label htmlFor="email">邮箱</Label>
        <Input id="email" name="email" type="email" required placeholder="you@example.com" />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="password">密码</Label>
        <Input id="password" name="password" type="password" required />
      </div>
      {state?.error && (
        <div className="text-sm text-red-600">{state.error}</div>
      )}
      <Button type="submit" className="w-full">登录</Button>
    </form>
  );
}


