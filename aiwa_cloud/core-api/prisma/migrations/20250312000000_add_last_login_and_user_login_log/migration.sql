-- AlterTable
ALTER TABLE "users" ADD COLUMN "last_login_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "user_login_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "success" BOOLEAN NOT NULL,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_login_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "user_login_logs_user_id_idx" ON "user_login_logs"("user_id");

-- CreateIndex
CREATE INDEX "user_login_logs_created_at_idx" ON "user_login_logs"("created_at");

-- AddForeignKey
ALTER TABLE "user_login_logs" ADD CONSTRAINT "user_login_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
