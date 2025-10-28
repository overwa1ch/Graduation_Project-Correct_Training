import { getCurrentUser, listAdmins } from "@/lib/auth";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { redirect } from "next/navigation";
import AdminUsersClient from "./AdminUsersClient";

export default async function AdminUsersPage() {
  const user = await getCurrentUser();
  if (!user) redirect("/signin");
  if (!user.isSystemAdmin) redirect("/books");
  const admins = await listAdmins();
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>管理员</CardTitle>
        </CardHeader>
        <CardContent>
          <AdminUsersClient admins={admins} currentUserId={user.id} />
        </CardContent>
      </Card>
    </div>
  );
}


