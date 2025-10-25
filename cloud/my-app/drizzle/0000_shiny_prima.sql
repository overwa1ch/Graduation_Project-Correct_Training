CREATE TABLE "admin-session" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"session_token" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "admin-session_session_token_unique" UNIQUE("session_token")
);
--> statement-breakpoint
CREATE TABLE "admin-users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"password_hash" text NOT NULL,
	"is_system_admin" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "admin-users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "admin-session" ADD CONSTRAINT "admin-session_user_id_admin-users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."admin-users"("id") ON DELETE cascade ON UPDATE no action;