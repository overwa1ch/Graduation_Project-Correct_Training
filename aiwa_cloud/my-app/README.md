# 毕业项目 - 训练管理系统（云端管理平台）

## 项目简介

这是一个基于 Next.js 15 开发的云端管理平台，用于管理训练相关的数据和用户。系统采用现代化的技术栈，提供完整的认证授权功能和管理员管理功能。

## 技术栈

- **框架**: Next.js 15 (App Router)
- **语言**: TypeScript
- **数据库**: PostgreSQL (Supabase)
- **ORM**: Drizzle ORM
- **样式**: Tailwind CSS 4
- **UI 组件**: 自定义组件库（基于 Radix UI）
- **认证**: 基于 Session Cookie 的自定义认证系统

## 核心功能

### 1. 用户认证系统
- ✅ 管理员注册（首次注册自动成为系统管理员）
- ✅ 管理员登录
- ✅ Session 管理（7天有效期）
- ✅ 密码哈希加密（SHA-256）
- ✅ 路由保护（中间件拦截）

### 2. 管理员管理
- ✅ 管理员列表展示
- ✅ 新建管理员（仅系统管理员）
- ✅ 编辑管理员权限
- ✅ 账户状态管理（启用/停用）
- ✅ 系统管理员/普通管理员角色区分

### 3. 数据模型

#### admin-users 表
```typescript
- id: UUID (主键)
- name: 文本 (姓名)
- email: 文本 (邮箱，唯一)
- password_hash: 文本 (密码哈希)
- is_system_admin: 布尔 (是否为系统管理员)
- is_active: 布尔 (账户是否启用)
- created_at: 时间戳
- updated_at: 时间戳
```

#### admin-session 表
```typescript
- id: UUID (主键)
- user_id: UUID (外键，关联 admin-users)
- session_token: 文本 (会话令牌，唯一)
- expires_at: 时间戳 (过期时间)
- created_at: 时间戳
```

## 项目结构

```
my-app/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # 认证相关页面（不带导航）
│   │   ├── signin/              # 登录页
│   │   └── signup/              # 注册页
│   ├── (dashboard)/             # 仪表板页面（带导航）
│   │   ├── admin-users/         # 管理员管理
│   │   └── layout.tsx           # 仪表板布局
│   ├── actions/                 # Server Actions
│   │   ├── admin-users.ts       # 管理员操作
│   │   ├── admin.ts             # 管理相关操作
│   │   └── auth.ts              # 认证操作
│   ├── globals.css              # 全局样式
│   ├── layout.tsx               # 根布局
│   └── page.tsx                 # 首页（重定向逻辑）
├── components/                   # React 组件
│   └── ui/                      # UI 基础组件
│       ├── button.tsx
│       ├── card.tsx
│       ├── checkbox.tsx
│       ├── dialog.tsx
│       ├── input.tsx
│       ├── label.tsx
│       └── separator.tsx
├── lib/                         # 核心库文件
│   ├── auth.ts                  # 认证逻辑
│   ├── db.ts                    # 数据库连接
│   ├── schema.ts                # 数据库模型
│   └── utils.ts                 # 工具函数
├── drizzle/                     # 数据库迁移文件
├── public/                      # 静态资源
├── middleware.ts                # Next.js 中间件（路由保护）
└── drizzle.config.ts           # Drizzle 配置
```

## 安装与运行

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
创建 `.env.local` 文件：
```env
DATABASE_URL=postgresql://username:password@host:port/database
```

### 3. 数据库迁移
```bash
# 生成迁移文件
npm run drizzle:generate

# 推送到数据库
npm run drizzle:push

# 打开 Drizzle Studio（可视化管理）
npm run drizzle:studio
```

### 4. 启动开发服务器
```bash
npm run dev
```

访问 http://localhost:3000

## 开发脚本

```bash
npm run dev              # 启动开发服务器
npm run build            # 构建生产版本
npm run start            # 启动生产服务器
npm run lint             # 运行 ESLint
npm run drizzle:generate # 生成数据库迁移
npm run drizzle:push     # 推送迁移到数据库
npm run drizzle:studio   # 打开 Drizzle Studio
```

## 待开发功能

- [ ] 用户训练数据管理
- [ ] 数据统计与可视化
- [ ] 导出功能
- [ ] 批量操作
- [ ] 搜索与过滤
- [ ] 角色权限细化

## 安全注意事项

⚠️ **重要提醒**：
1. 请勿将数据库凭证提交到版本控制系统
2. 生产环境建议使用更强的密码哈希算法（如 bcrypt、argon2）
3. 建议添加请求频率限制防止暴力破解
4. 建议添加 CSRF 保护
5. 建议添加日志审计功能

## 最近更新

- ✅ 完成管理员认证系统
- ✅ 完成管理员管理功能
- ✅ 优化项目结构
- ✅ 清理测试和调试文件

## 许可证

本项目为毕业设计项目。
