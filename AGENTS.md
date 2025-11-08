# AIWA 项目协作指南

## 1. 项目概述
AIWA 是一个面向健身姿态纠正的全栈解决方案，前端采用 Flutter 构建移动端体验，后端基于 Fastify + Prisma 提供云端认证与会话管理能力。系统通过 PostgreSQL 持久化用户与分析数据，并预留对阿里云 OSS 的扩展支持，实现从姿态采集、历史记录管理到云端登录授权的完整闭环。详见 `aiwa_cloud/PROJECT_SUMMARY.md` 中的整体架构描述。

## 2. 安装、环境变量、运行与构建
### 通用要求
- Node.js ≥ 20（用于后端 core-api 服务）。
- 已安装 pnpm 包管理器（所有原本 `npm` 的脚本请改用 `pnpm`）。
- Flutter SDK ≥ 3.4（用于移动端 `aiwa_app`）。

### 后端（aiwa_cloud/core-api）
1. 复制环境变量模板并按需填写数据库、JWT 以及可选的阿里云配置：
   ```bash
   cp env.example .env
   ```
   关键变量包括 `DATABASE_URL`、`JWT_ACCESS_SECRET`、`JWT_REFRESH_SECRET`、`PORT`、`CORS_ORIGIN`，以及按需启用的 `USE_ALIYUN_OSS` 和相关 OSS 凭据。详细字段说明见 `aiwa_cloud/core-api/env.example`。
2. 安装依赖并生成 Prisma 客户端：
   ```bash
   pnpm install
   pnpm prisma:generate
   ```
3. 初始化数据库（开发环境可选择迁移或直接推送 Schema）：
   ```bash
   pnpm prisma:migrate
   # 或
   pnpm prisma:push
   ```
4. 运行与构建：
   ```bash
   pnpm dev         # 开发模式（Fastify + tsx 热重载）
   pnpm build       # TypeScript 编译到 dist/
   pnpm start       # 生产环境启动（需先 build）
   pnpm lint        # 代码规范检查
   pnpm prisma:studio  # 打开 Prisma Studio 调试数据
   ```

### 前端（aiwa_app）
1. 安装依赖：
   ```bash
   flutter pub get
   ```
2. 运行与调试：
   ```bash
   flutter run
   ```
3. 构建产物：
   ```bash
   flutter build apk    # Android 包
   flutter build ios    # iOS（需 macOS 环境）
   flutter build web    # Web 预览（可选）
   ```
4. 前端会通过 `aiwa_core` 本地 Dart 包与后端 REST API 协同，确保 `.env` 中的后端地址与应用配置保持一致。

## 3. 目录结构、页面路由与 API
### 主要目录
```
├── aiwa_app/                 # Flutter 客户端（姿态采集、历史记录、设置等）
│   ├── lib/
│   │   ├── main.dart         # 入口与路由守卫
│   │   ├── ui/pages/         # 登录、注册、欢迎、主页、相机、设置等页面
│   │   ├── ui/widgets/       # 复用组件
│   │   ├── services/         # 认证状态、历史记录等服务层
│   │   └── theme/            # 设计语言与 Token
├── aiwa_core/                # 纯 Dart 核心逻辑与工具库
├── aiwa_cloud/
│   └── core-api/             # Fastify 后端（认证、会话、作业触发）
│       ├── src/
│       │   ├── main.ts       # 应用入口
│       │   ├── config.ts     # 配置加载
│       │   ├── middleware/   # JWT 鉴权中间件
│       │   └── modules/auth/ # 用户认证模块
│       ├── prisma/           # 数据库 Schema
│       └── docker-compose.yml# 本地服务编排
├── assets/、docs/            # 设计资产与说明文档
└── 其他 aiwa_* 子项目        # CLI、runner 等扩展模块
```
目录详情可参考 `aiwa_cloud/PROJECT_SUMMARY.md`。

### 前端路由
`aiwa_app/lib/main.dart` 定义了基于 `MaterialApp` 的路由守卫：
- 未登录：`/login`（登录页）、`/register`（注册页）。
- 登录后：`/welcome`（欢迎页）、`/home`（历史记录主页）、`/camera`（姿态采集）、`/settings`（设置）。
所有受保护页面会根据 `AuthState` 状态重定向，未知路由回退到首页或登录页。

### 后端 API
`aiwa_cloud/core-api/README.md` 列出了 REST 接口：
- 认证模块：`POST /v1/auth/register`、`POST /v1/auth/login`、`POST /v1/auth/refresh`。
- 会话管理：`POST /v1/sessions`、`POST /v1/sessions/:id/finalize`、`GET /v1/sessions/:id`。
- 作业编排：`POST /v1/sessions/:id/jobs/reinfer`、`POST /v1/sessions/:id/jobs/advice`、`GET /v1/jobs/:id`。
- 结果查询：`GET /v1/sessions/:id/results`。
`src/modules/auth/auth.routes.ts` 已实现认证相关路由，其余接口可根据 README 约定扩展。

## 4. 技术栈与关键依赖
- **Flutter + Dart**：移动端 UI 与交互核心（依赖 `google_mlkit_pose_detection`、`image_picker`、`video_player`、`shared_preferences` 等）。参见 `aiwa_app/pubspec.yaml`。
- **aiwa_core**：封装通用 CSV、路径等工具逻辑，供 Flutter 端复用。
- **Fastify + TypeScript**：后端 Web 框架，结合 `@fastify/jwt`、`zod` 做认证与数据校验。依赖列表详见 `aiwa_cloud/core-api/package.json`。
- **Prisma + PostgreSQL**：关系型数据访问层，`prisma` 目录维护 Schema，命令通过 pnpm 调用。
- **安全与加密**：`bcrypt` 负责密码哈希，JWT 秘钥需通过 OpenSSL 或 Node `crypto` 生成，具体要求见 `aiwa_cloud/core-api/README.md`。
- **云端扩展**：环境变量预留阿里云 OSS、S3、SQS 等集成接口，详见 `aiwa_cloud/PROJECT_SUMMARY.md`。

## 5. pnpm 使用约定
- 所有后端 Node.js 子项目一律使用 `pnpm` 执行依赖安装与脚本命令（如 `pnpm install`、`pnpm dev`、`pnpm prisma:migrate`）。
- 如需在 CI 或脚本中更新命令，请确保先运行 `pnpm install` 并提交 `pnpm-lock.yaml`。
- 避免混用 `npm` 或 `yarn`，以免生成多余锁文件。