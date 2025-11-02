# AIWA 管理后台

> **可选功能** - Next.js 管理后台（用于用户管理）

---

## 📋 说明

这是一个可选的 Next.js 管理后台应用，用于：
- 查看注册用户
- 管理用户状态
- 查看用户统计信息

**注意：** 如果只需要 Flutter 移动端 + 认证 API，可以不使用此管理后台。

---

## 🚀 快速开始

### 1. 安装依赖

```bash
cd my-app
npm install
```

### 2. 配置环境变量

创建 `.env.local` 文件：

```bash
# 数据库（与 core-api 使用相同的数据库）
DATABASE_URL=postgresql://aiwa:aiwa_dev_password@localhost:5432/aiwa_auth

# NextAuth 密钥（生成随机字符串）
NEXTAUTH_SECRET=your_nextauth_secret_here
NEXTAUTH_URL=http://localhost:3001

# API 地址（core-api）
API_BASE_URL=http://localhost:3000
```

### 3. 运行数据库迁移

```bash
npx drizzle-kit push:pg
```

### 4. 启动开发服务器

```bash
npm run dev
```

访问：http://localhost:3001

---

## 🎨 功能

### 当前实现
- ✅ 管理员登录
- ✅ 查看用户列表
- ✅ 用户状态管理（激活/停用）

### 未来扩展
- [ ] 用户详情页
- [ ] 训练数据统计
- [ ] 用户活跃度分析

---

## 🔐 默认管理员账号

首次运行时需要手动创建管理员：

```sql
-- 连接到数据库
psql postgresql://aiwa:aiwa_dev_password@localhost:5432/aiwa_auth

-- 创建管理员用户
INSERT INTO users (id, email, password_hash, status)
VALUES (
  gen_random_uuid(),
  'admin@example.com',
  -- 密码: admin123（使用 bcrypt 加密）
  '$2b$10$N9qo8uLOickgx2ZMRZoMye.IY0n1UdWfQA8V5R6VU5gJN8QKKUQWS',
  'active'
);
```

登录信息：
- 邮箱: `admin@example.com`
- 密码: `admin123`

**⚠️ 生产环境务必修改密码！**

---

## 🛠️ 技术栈

- **框架**: Next.js 15 (App Router)
- **数据库**: PostgreSQL + Drizzle ORM
- **认证**: NextAuth.js
- **UI**: Tailwind CSS + shadcn/ui
- **语言**: TypeScript

---

## 📖 API 集成

管理后台通过 HTTP 调用 core-api：

```typescript
// 获取用户列表
const response = await fetch(`${API_BASE_URL}/v1/users`, {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
  },
});
```

**注意：** 需要在 core-api 中添加管理员接口（当前版本未实现）。

---

## 🚧 当前状态

- **状态**: 基础框架已搭建
- **是否必需**: ❌ 不必需（毕业设计可选）
- **推荐**: 如果时间充裕，可以演示管理后台增加亮点

---

## 🎓 毕业答辩建议

如果使用此管理后台：

1. **展示内容**
   - 用户管理界面
   - 实时用户数据
   - 管理员权限控制

2. **技术亮点**
   - 前后端分离
   - 多端应用（Flutter + Next.js）
   - 统一认证系统

3. **注意事项**
   - 说明这是"可选的管理后台"
   - 重点仍在 Flutter 移动端

---

## 📝 开发建议

### 最小实现（毕业设计）

只实现：
- 管理员登录
- 查看用户列表
- 基本的用户管理

### 完整实现（未来扩展）

添加：
- 训练数据可视化
- 用户行为分析
- 系统监控面板

---

## 🗂️ 文件结构

```
my-app/
├── app/
│   ├── (auth)/        # 登录页面
│   ├── (dashboard)/   # 管理后台主页
│   └── actions/       # Server Actions
├── components/        # UI 组件
├── lib/              # 工具库
└── drizzle/          # 数据库迁移
```

---

## 📞 技术支持

- Next.js 文档: https://nextjs.org/docs
- Drizzle ORM: https://orm.drizzle.team/
- shadcn/ui: https://ui.shadcn.com/

---

**结论：** 此管理后台是可选功能，毕业设计可以不使用。如果时间充裕，可以作为额外亮点展示。
