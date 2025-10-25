import { getCurrentUserEmail, hasAnyAdmin } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function Home() {
  const email = await getCurrentUserEmail();
  if (email) {
    redirect("/books");
  }
  if (!(await hasAnyAdmin())) {
    redirect("/signup");
  }
  redirect("/signin");
}
