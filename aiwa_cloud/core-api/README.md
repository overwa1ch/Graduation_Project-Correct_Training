# AIWA Core API

> **版本 3.0** - 简化认证服务，适合毕业设计部署到阿里云

基于 Fastify 的用户认证 API，为 AIWA 健身姿态纠正应用提供用户登录/注册功能。

## 特性

- ✅ **JWT 认证** - HS256 标准，access + refresh token
- ✅ **安全加密** - Bcrypt 密码哈希
- ✅ **数据库支持** - PostgreSQL（生产）/ SQLite（开发）
- ✅ **类型安全** - TypeScript 5.3
- ✅ **ORM** - Prisma 5.9

## 技术栈

- **Framework**: Fastify 4.26
- **Database**: PostgreSQL 15 / SQLite（开发）
- **ORM**: Prisma 5.9
- **Language**: TypeScript 5.3
- **Auth**: JWT (@fastify/jwt)
- **Encryption**: Bcrypt

## 快速开始

### 1. 安装依赖

```bash
pnpm install
```

### 2. 配置环境

复制环境变量模板：

```bash
# SQLite 版本（推荐用于本地开发）
cp env.sqlite.example .env

# 或 PostgreSQL 版本
cp env.example .env
```

编辑 `.env` 文件，生成并填入 JWT 密钥：

```bash
# 生成密钥（运行两次，分别用于 ACCESS 和 REFRESH）
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. 设置数据库

```bash
# 生成 Prisma 客户端
pnpm prisma:generate

# SQLite: 直接推送 Schema
pnpm prisma:push

# PostgreSQL: 运行迁移
pnpm prisma:migrate
```

### 4. 启动开发服务器

```bash
pnpm dev
```

服务器将运行在 `http://localhost:8080`（SQLite）或 `http://localhost:3000`（PostgreSQL）

## API 端点

### 认证

- `POST /v1/auth/register` - 注册新用户
- `POST /v1/auth/login` - 登录并获取 JWT tokens
- `POST /v1/auth/refresh` - 刷新 access token

### 健康检查

- `GET /health` - 服务健康检查

## 开发

```bash
# 开发模式（热重载）
pnpm dev

# 构建生产版本
pnpm build

# 启动生产服务器
pnpm start

# 代码检查
pnpm lint

# 打开 Prisma Studio（数据库可视化）
pnpm prisma:studio
```

## 部署

### 本地开发（SQLite）

使用 SQLite 文件数据库，无需 Docker 或 PostgreSQL 服务器。详见 `env.sqlite.example`。

### 生产环境（PostgreSQL）

使用 PostgreSQL 数据库（推荐阿里云 RDS）。详见 `env.example` 和 `../README.md`。

## 项目结构

```
core-api/
├── src/
│   ├── main.ts              # 应用入口
│   ├── config.ts            # 配置管理
│   ├── lib/                 # 工具库
│   │   ├── crypto.ts        # 密码加密
│   │   ├── prisma.ts        # 数据库客户端
│   │   └── aliyun-oss.ts    # 阿里云 OSS（预留，未实现）
│   ├── middleware/          # 中间件
│   │   └── auth.middleware.ts
│   └── modules/             # 业务模块
│       └── auth/            # 认证模块
├── prisma/
│   ├── schema.prisma        # PostgreSQL Schema
│   └── schema.sqlite.prisma # SQLite Schema
└── package.json
```

## 许可证

MIT
