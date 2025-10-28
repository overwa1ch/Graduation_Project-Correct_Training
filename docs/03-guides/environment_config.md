# 环境变量配置指南

## 快速开始

在项目根目录创建 `.env.local` 文件，添加以下配置：

```env
# 数据库配置（方式1：推荐）
DATABASE_URL=postgresql://username:password@host:port/database

# 应用配置
NODE_ENV=development
```

## 详细配置说明

### 数据库连接配置

#### 方式1：使用 DATABASE_URL（推荐）

这是最简单的配置方式，特别适合使用 Supabase 或其他云数据库服务：

```env
DATABASE_URL=postgresql://postgres.xxxxxx:your-password@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres
```

**格式说明：**
```
postgresql://[用户名]:[密码]@[主机地址]:[端口]/[数据库名]
```

#### 方式2：单独配置（备选）

如果你的环境不支持 DATABASE_URL，可以使用单独配置：

```env
DB_HOST=your-database-host.supabase.co
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-password
```

### 应用配置

```env
# 环境模式：development（开发）、production（生产）
NODE_ENV=development
```

## Supabase 数据库配置示例

如果你使用 Supabase 托管数据库，可以在 Supabase 控制台获取连接信息：

1. 登录 [Supabase Dashboard](https://app.supabase.com/)
2. 进入你的项目
3. 点击左侧菜单 **Project Settings** → **Database**
4. 在 **Connection string** 部分选择 **URI** 格式
5. 复制连接字符串到 `.env.local` 文件

**示例：**
```env
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxxxxxxxxx.supabase.co:5432/postgres
```

⚠️ **注意：** 记得将 `[YOUR-PASSWORD]` 替换为你的实际数据库密码！

## 环境变量文件说明

### `.env.local`（本地开发）
- 用于本地开发环境
- **不会**被提交到 Git（已在 .gitignore 中）
- 包含敏感信息（数据库密码等）

### `.env.production`（生产环境）
- 用于生产部署
- 通常在部署平台（如 Vercel）的环境变量配置中设置
- **不应**提交到 Git

### `.env.example`（配置模板）
- 环境变量配置模板
- 不包含实际敏感信息
- **应该**提交到 Git，供团队成员参考

## 安全建议

### ✅ 应该做的：
- ✅ 将 `.env.local` 添加到 `.gitignore`
- ✅ 使用强密码
- ✅ 定期更换数据库密码
- ✅ 生产环境使用独立的数据库
- ✅ 在团队中共享 `.env.example`

### ❌ 不应该做的：
- ❌ 将包含真实密码的 `.env` 文件提交到 Git
- ❌ 在代码中硬编码数据库凭证
- ❌ 在公共场合（如截图、日志）暴露环境变量
- ❌ 开发和生产环境使用相同的数据库

## 验证配置

配置完成后，运行以下命令验证数据库连接：

```bash
# 测试数据库连接
npm run drizzle:studio
```

如果能成功打开 Drizzle Studio，说明数据库配置正确。

## 常见问题

### Q: 提示 "DATABASE_URL is not set" 错误？
**A:** 检查 `.env.local` 文件是否在项目根目录，且文件名正确（注意不是 `.env.txt`）

### Q: 连接数据库失败？
**A:** 请检查：
1. DATABASE_URL 格式是否正确
2. 数据库密码是否正确（注意特殊字符需要 URL 编码）
3. 网络是否能访问数据库服务器
4. 数据库服务是否正常运行

### Q: Vercel 部署时如何配置？
**A:** 在 Vercel 项目设置中：
1. 进入项目 Settings → Environment Variables
2. 添加 `DATABASE_URL` 变量
3. 选择环境（Production / Preview / Development）
4. 重新部署项目

### Q: 密码中有特殊字符怎么办？
**A:** 需要进行 URL 编码，例如：
- `@` → `%40`
- `#` → `%23`
- `&` → `%26`

或者使用在线工具进行编码：https://www.urlencoder.org/

## 示例配置文件

### 开发环境 (`.env.local`)
```env
# Supabase 数据库（开发）
DATABASE_URL=postgresql://postgres:dev-password@db.dev.supabase.co:5432/postgres

NODE_ENV=development
```

### 生产环境 (Vercel 环境变量)
```env
# Supabase 数据库（生产）
DATABASE_URL=postgresql://postgres:prod-strong-password@db.prod.supabase.co:5432/postgres

NODE_ENV=production
```

---

**提示：** 如需帮助，请参考 [Next.js 环境变量文档](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)

