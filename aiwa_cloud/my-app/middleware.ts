import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const session = request.cookies.get("session")?.value;

  const isProtected = pathname.startsWith("/books") || pathname.startsWith("/admin-users");
  const isAuthPage = pathname === "/signin" || pathname === "/signup";

  if (isProtected && !session) {
    const url = request.nextUrl.clone();
    url.pathname = "/signin";
    return NextResponse.redirect(url);
  }

  if (isAuthPage && session) {
    const url = request.nextUrl.clone();
    url.pathname = "/books";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/books/:path*", "/admin-users/:path*", "/signin", "/signup"],
};

