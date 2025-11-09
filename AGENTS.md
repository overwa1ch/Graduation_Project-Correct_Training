# AIWA 协作手册

## 1. 项目概述
AIWA（AI Workout Assistant）是一个面向健身姿态纠正的全栈毕业设计项目，覆盖 Flutter 移动端、Dart 核心算法库与 Fastify+Prisma 后端服务三部分。系统以 PostgreSQL/SQLite 持久化用户与会话数据，预留阿里云 OSS 等扩展能力，实现姿态采集、历史记录、云端认证与增强分析的闭环体验。整体设计、上下游模块说明可在 `docs/` 与 `aiwa_cloud/PROJECT_SUMMARY.md` 中进一步查阅。

## 2. 安装、环境变量、运行与构建
### 通用要求
- Node.js ≥ 20；包管理全部使用 **pnpm**（需先全局安装 `pnpm`）。
- Flutter SDK ≥ 3.4，Dart ≥ 3.4，用于 `aiwa_app`。
- 本地如需 PostgreSQL，请提前创建数据库与凭据；亦可使用 SQLite 进行开发调试。

### 后端（`aiwa_cloud/core-api`）
1. 复制环境变量模板：
   ```bash
   # SQLite（本地推荐）
   cp env.sqlite.example .env
   # 或 PostgreSQL（生产）
   cp env.example .env
   ```
2. 在 `.env` 中填写关键变量：
   - `DATABASE_URL`：PostgreSQL 或 SQLite 连接串；
   - `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET`：可通过 `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` 生成；
   - `PORT`、`CORS_ORIGIN` 以及可选的 `USE_ALIYUN_OSS` 与阿里云凭据。
3. 安装依赖并准备数据库：
   ```bash
   pnpm install
   pnpm prisma:generate
   # SQLite 推送 Schema
   pnpm prisma:push
   # 或 PostgreSQL 迁移
   pnpm prisma:migrate
   ```
4. 常用脚本：
   ```bash
   pnpm dev           # tsx 热重载开发
   pnpm build         # TypeScript 编译
   pnpm start         # 生产模式（需先 build）
   pnpm lint          # ESLint
   pnpm prisma:studio # 打开 Prisma Studio
   ```

### 前端（`aiwa_app`）
1. 安装依赖：
   ```bash
   flutter pub get
   ```
2. 运行与调试：
   ```bash
   flutter run                 # 默认设备
   flutter run -d <device_id>  # 指定模拟器/真机
   ```
3. 构建：
   ```bash
   flutter build apk
   flutter build ios    # 需 macOS
   flutter build web    # 可选
   ```
4. 配置后端地址：前端通过 `aiwa_core` 与 REST API 通讯，请在应用运行时配置文件或环境中保持后端基地址一致（详见 `aiwa_app/README.md` 的配置章节）。

### Dart 核心库（`aiwa_core`）
- 提供姿态分析、CSV/IO 工具等 Dart-only 能力。若在本地调试 Flutter 时需联动，可使用 `flutter pub add path` 或在 `pubspec.yaml` 中通过 `path: ../aiwa_core` 引入；额外脚本见库内 `README`（如存在）。

## 3. 目录结构、页面路由与 API
### 目录概览
```
├── aiwa_app/                 # Flutter 客户端
│   ├── lib/
│   │   ├── main.dart         # 入口与路由守卫
│   │   ├── ui/pages/         # 登录、注册、欢迎、主页、相机、设置等页面
│   │   ├── ui/widgets/       # 复用组件
│   │   ├── services/         # 认证、视频分析等服务
│   │   ├── pose/             # ML Kit / MoveNet 引擎实现
│   │   └── adapters/ config/ theme/  # 适配器、配置与主题
│   ├── assets/               # TensorFlow Lite 模型、规则与设计 Tokens
│   └── scripts/ tool/        # Dart/Flutter 工具脚本
├── aiwa_core/                # Dart 核心逻辑（离线分析、工具库）
├── aiwa_cloud/
│   ├── core-api/             # Fastify 后端
│   │   ├── src/
│   │   │   ├── main.ts       # 启动入口
│   │   │   ├── config.ts     # 配置加载
│   │   │   ├── middleware/   # JWT 中间件
│   │   │   └── modules/auth/ # 认证模块
│   │   └── prisma/           # Schema（PostgreSQL & SQLite）
│   ├── docker-compose.yml    # 可扩展服务编排
│   └── README.md             # 后端部署说明
├── docs/                     # 设计、指南、报告
└── 其他子目录（`aiwa_*`）     # 如 CLI、runner 等扩展
```

### 前端页面路由（`aiwa_app/lib/main.dart`）
- `/login`、`/register`：无需登录的认证页面；
- `/welcome`：登录后欢迎页；
- `/home`：历史记录与仪表盘；
- `/camera`：姿态采集与实时提示；
- `/settings`：应用设置与引擎切换；
- 通过 `AuthState` 监听决定访问权限，`kDisableAuthForTesting` 可关闭登录拦截。

### 后端 API（`aiwa_cloud/core-api`）
- `POST /v1/auth/register`：注册用户；
- `POST /v1/auth/login`：登录并返回 access/refresh token；
- `POST /v1/auth/refresh`：刷新 access token；
- `GET /health`：健康检查；
- 扩展接口（会话、分析作业等）详见 `aiwa_cloud/core-api/README.md` 与 `aiwa_cloud/PROJECT_SUMMARY.md`，并在 `src/modules/` 下逐步实现。

## 4. 技术栈与关键依赖
- **Flutter 3.4+ & Dart**：移动端界面与交互；核心依赖包括 `google_mlkit_pose_detection`、`camera`/`image_picker`、`video_player`、`shared_preferences` 等，详见 `aiwa_app/pubspec.yaml`。
- **aiwa_core**：封装姿态评分、CSV 读写、配置解析等 Dart 工具，供前端调用。
- **Fastify 4 + TypeScript 5**：后端 Web 框架，结合 `@fastify/jwt` 实现认证，`zod` 做参数校验，热重载由 `tsx` 驱动。
- **Prisma 5 + PostgreSQL/SQLite**：ORM 与数据库访问层，通过 `pnpm prisma:*` 命令管理 Schema。
- **安全组件**：`bcrypt` 用于密码哈希，JWT 秘钥需使用 `crypto` 生成并妥善保管。
- **DevOps 支持**：`tsconfig.json`、`eslint`、`docker-compose.yml` 等辅助开发与部署，CI/脚本同样应使用 pnpm。

## 5. pnpm 使用约定
- 所有 Node.js 子项目统一使用 `pnpm` 执行依赖安装与脚本，不得混用 npm/yarn；
- 请提交 `pnpm-lock.yaml` 以保持依赖一致性；
- 在 CI 或脚本中执行命令前确保已运行 `pnpm install`，并避免生成多余锁文件。
