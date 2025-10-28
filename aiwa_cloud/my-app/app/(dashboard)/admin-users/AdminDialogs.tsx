"use client";

import * as React from "react";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { useActionState } from "react";
import { createAdminUser, updateAdminUser, type AdminActionResult } from "@/app/actions/admin";

export function CreateAdminDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (v: boolean) => void }) {
  const [state, formAction] = useActionState<AdminActionResult, FormData>(createAdminUser, {});
  
  React.useEffect(() => {
    if (state?.success) {
      onOpenChange(false);
    }
  }, [state, onOpenChange]);
  
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>新建管理员</DialogTitle>
        </DialogHeader>
        <form action={formAction} className="grid gap-3">
          <div className="grid gap-2">
            <Label htmlFor="name">姓名</Label>
            <Input id="name" name="name" required />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="email">邮箱</Label>
            <Input id="email" name="email" type="email" required />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="password">初始密码</Label>
            <Input id="password" name="password" type="password" required />
          </div>
          <div className="flex items-center gap-2">
            <Checkbox id="isSystemAdmin" name="isSystemAdmin" />
            <Label htmlFor="isSystemAdmin">系统管理员</Label>
          </div>
          <div className="flex items-center gap-2">
            <Checkbox id="isActive" name="isActive" defaultChecked />
            <Label htmlFor="isActive">启用</Label>
          </div>
          {state?.error && <div className="text-sm text-red-600">{state.error}</div>}
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>取消</Button>
            <Button type="submit">创建</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function EditAdminDialog({ open, onOpenChange, admin, isSelf }: { open: boolean; onOpenChange: (v: boolean) => void; admin: { id: string; name: string; email: string; isSystemAdmin: boolean; isActive: boolean }; isSelf: boolean; }) {
  const [state, formAction] = useActionState<AdminActionResult, FormData>(updateAdminUser, {});
  
  React.useEffect(() => {
    if (state?.success) {
      onOpenChange(false);
    }
  }, [state, onOpenChange]);
  
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>编辑管理员</DialogTitle>
        </DialogHeader>
        <form action={formAction} className="grid gap-3">
          <input type="hidden" name="id" value={admin.id} />
          <div className="grid gap-2">
            <Label htmlFor="name">姓名</Label>
            <Input id="name" name="name" required defaultValue={admin.name} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="email">邮箱</Label>
            <Input id="email" name="email" type="email" required defaultValue={admin.email} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="password">重置密码（可选）</Label>
            <Input id="password" name="password" type="password" placeholder="留空则不修改" />
          </div>
          <div className="flex items-center gap-2">
            <Checkbox id="isSystemAdmin" name="isSystemAdmin" defaultChecked={admin.isSystemAdmin} disabled={isSelf} />
            <Label htmlFor="isSystemAdmin" className={isSelf ? "text-zinc-400" : undefined}>系统管理员</Label>
          </div>
          <div className="flex items-center gap-2">
            <Checkbox id="isActive" name="isActive" defaultChecked={admin.isActive} disabled={isSelf} />
            <Label htmlFor="isActive" className={isSelf ? "text-zinc-400" : undefined}>启用</Label>
          </div>
          {state?.error && <div className="text-sm text-red-600">{state.error}</div>}
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>取消</Button>
            <Button type="submit">保存</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}


