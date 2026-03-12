import { createClient } from "@libsql/client";
import { drizzle } from "drizzle-orm/libsql";
import * as path from "path";
import * as schema from "./schema-sqlite";

const url = process.env.DATABASE_URL ?? "file:./data/admin.db";
const dbPath = url.startsWith("file:") ? url : `file:${path.resolve(process.cwd(), url)}`;
const client = createClient({ url: dbPath });
export const db = drizzle(client, { schema });
