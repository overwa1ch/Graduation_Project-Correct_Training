"use client";

import * as React from "react";
import { Button } from "@/components/ui/button";
import { CreateAdminDialog, EditAdminDialog } from "./AdminDialogs";

type Admin = { id: string; name: string; email: string; isSystemAdmin: boolean; isActive: boolean };

export default function AdminUsersClient({ admins, currentUserId }: { admins: Admin[]; currentUserId: string }) {
  const [createOpen, setCreateOpen] = React.useState(false);
  const [editOpen, setEditOpen] = React.useState<string | null>(null);
  const toEdit = admins.find((a) => a.id === editOpen) || null;

  return (
    <>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">管理员管理</h1>
        <Button onClick={() => setCreateOpen(true)}>新建管理员</Button>
      </div>

      <div className="overflow-x-auto rounded-lg border border-zinc-200 dark:border-zinc-800">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-zinc-200 bg-zinc-50/60 text-zinc-500 dark:border-zinc-800 dark:bg-zinc-900/30 dark:text-zinc-400">
            <tr>
              <th className="py-2 pl-4">姓名</th>
              <th className="py-2">邮箱</th>
              <th className="py-2">角色</th>
              <th className="py-2">状态</th>
              <th className="py-2 pr-4 text-right">操作</th>
            </tr>
          </thead>
          <tbody>
            {admins.map((a) => (
              <tr key={a.id} className="border-b border-zinc-100 last:border-0 dark:border-zinc-900">
                <td className="py-2 pl-4">{a.name}</td>
                <td className="py-2">{a.email}</td>
                <td className="py-2">{a.isSystemAdmin ? "系统管理员" : "普通管理员"}</td>
                <td className="py-2">{a.isActive ? "启用" : "停用"}</td>
                <td className="py-2 pr-4 text-right">
                  <Button size="sm" variant="outline" onClick={() => setEditOpen(a.id)}>编辑</Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <CreateAdminDialog open={createOpen} onOpenChange={setCreateOpen} />
      {toEdit && (
        <EditAdminDialog
          open={!!editOpen}
          onOpenChange={(v) => !v && setEditOpen(null)}
          admin={toEdit}
          isSelf={toEdit.id === currentUserId}
        />
      )}
    </>
  );
}


