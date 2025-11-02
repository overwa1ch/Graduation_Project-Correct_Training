# 本地运行指南（不使用 Docker）

> **最简单的方式** - 使用 SQLite，一个文件即可运行！

---

## 🎯 为什么选择这个方案？

- ✅ **无需 Docker** - 不需要配置 Docker Desktop
- ✅ **无需 PostgreSQL** - 使用 SQLite 文件数据库
- ✅ **零配置** - 安装依赖即可运行
- ✅ **快速启动** - 5 分钟搞定

---

## 📋 前置要求

只需安装：
- ✅ **Node.js 20+** - [下载地址](https://nodejs.org/)
- ✅ **npm**（随 Node.js 安装）

**不需要：**
- ❌ Docker Desktop
- ❌ PostgreSQL 服务器
- ❌ 任何数据库服务器

---

## 🚀 快速开始（3 步）

### ⚠️ 重要：必须在正确的目录下运行！

**所有命令都必须在 `aiwa_cloud/core-api` 目录下执行！**

### 第 1 步：进入项目目录

```powershell
# Windows PowerShell - 从项目根目录开始
cd aiwa_cloud
cd core-api

# 或一次性进入
cd aiwa_cloud\core-api

# 验证当前位置（应该显示 ...\aiwa_cloud\core-api）
Get-Location
```

```bash
# Linux/Mac
cd aiwa_cloud/core-api

# 验证当前位置
pwd
```

### 第 2 步：配置环境

**确保你在 `core-api` 目录下！**

```powershell
# Windows PowerShell
# 首先检查文件是否存在
Get-ChildItem env.sqlite.example

# 如果文件存在，复制
Copy-Item env.sqlite.example .env

# 如果提示找不到文件，说明不在正确目录
```

```bash
# Linux/Mac
# 首先检查文件是否存在
ls env.sqlite.example

# 如果文件存在，复制
cp env.sqlite.example .env
```

编辑 `.env` 文件，生成 JWT 密钥：

```bash
# 生成密钥
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

将输出的字符串填入 `.env` 文件中的：
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`

**最小配置（`.env` 文件）：**
```bash
DATABASE_URL="file:./dev.db"
JWT_ACCESS_SECRET=你的32字符密钥
JWT_REFRESH_SECRET=你的32字符密钥
PORT=8080
NODE_ENV=development
CORS_ORIGIN=*
```

**⚠️ Windows 用户注意：**
- Windows 系统在端口 3000-3012 范围内有保留端口
- 如果使用 3000 或 3001 可能遇到 `EACCES: permission denied` 错误
- 推荐使用端口 **8080**（已更新为默认值）
- 其他可选端口：8081, 4000, 5000（需确保不被占用）

### 第 3 步：安装并运行

```bash
# 安装依赖
npm install

# 配置 SQLite schema（复制 schema.sqlite.prisma 为 schema.prisma）
Copy-Item prisma\schema.sqlite.prisma prisma\schema.prisma
# 或 Linux/Mac: cp prisma/schema.sqlite.prisma prisma/schema.prisma

# 创建数据库并运行迁移
npx prisma db push

# 启动开发服务器
npm run dev
```

看到以下输出说明成功：
```
🚀 AIWA Auth API listening on port 3001
📝 Environment: development
```

---

## ✅ 测试 API

### 健康检查

```bash
curl http://localhost:3001/health
```

**预期响应：**
```json
{
  "status": "ok",
  "timestamp": "2025-11-02T...",
  "service": "aiwa-auth-api",
  "version": "1.0.0"
}
```

### 注册用户

```bash
curl -X POST http://localhost:3001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

**预期响应：**
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refresh_token": "abc123..."
}
```

### 登录

```bash
curl -X POST http://localhost:3001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

---

## 📁 文件结构

运行后，项目目录会生成：

```
core-api/
├── .env                    # 环境变量（你自己创建的）
├── dev.db                  # SQLite 数据库文件（自动创建）
├── node_modules/           # 依赖包
├── dist/                   # 编译后的代码
└── ...
```

**重要文件：**
- `dev.db` - SQLite 数据库文件（包含所有用户数据）

---

## 🔧 查看数据库

### 方法 1：使用 Prisma Studio（推荐）

```bash
npx prisma studio
```

浏览器自动打开：http://localhost:5555

### 方法 2：使用 SQLite 命令行

```bash
# 安装 sqlite3 命令行工具
# Windows (使用 Chocolatey)
choco install sqlite

# Mac
brew install sqlite3

# Linux
sudo apt install sqlite3

# 打开数据库
sqlite3 dev.db

# 查看表
.tables

# 查看用户
SELECT * FROM users;

# 退出
.quit
```

---

## 🎨 在 Flutter 中连接

### 配置 API 地址

```dart
class ApiConfig {
  // 本地开发（SQLite 版本运行在 3001 端口）
  static const String baseUrl = 'http://localhost:3001';
  
  // Android 模拟器使用：
  // static const String baseUrl = 'http://10.0.2.2:3001';
  
  // iOS 模拟器使用：
  // static const String baseUrl = 'http://localhost:3001';
  
  // 真机使用电脑的局域网 IP：
  // static const String baseUrl = 'http://192.168.1.100:3001';
}
```

---

## ⚙️ 常见问题

### Q1: 端口 3001 也被占用？

**解决：** 修改 `.env` 文件中的 `PORT`：
```bash
PORT=3002  # 或其他可用端口
```

然后重启服务器。

### Q2: Prisma 报错 "Unknown datasource provider"

**解决：** 确保 `prisma/schema.prisma` 使用 SQLite 版本：
```bash
# 确认 datasource provider 是 "sqlite"
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```

### Q3: 数据库文件在哪里？

**位置：** `core-api/dev.db`

**查看位置：**
```bash
# Windows PowerShell
Get-ChildItem dev.db

# Linux/Mac
ls -lh dev.db
```

### Q4: 如何重置数据库？

```bash
# 删除数据库文件
Remove-Item dev.db  # Windows
# 或 rm dev.db  # Linux/Mac

# 重新创建
npx prisma db push
```

### Q5: 如何备份数据？

**SQLite 数据库就是一个文件：**
```bash
# 复制 dev.db 文件即可
Copy-Item dev.db dev.db.backup  # Windows
# 或 cp dev.db dev.db.backup  # Linux/Mac
```

---

## 🔄 切换到 PostgreSQL（生产环境）

如果后续需要部署到阿里云，只需要：

### 1. 修改 Prisma Schema

编辑 `prisma/schema.prisma`，将：
```prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```

改为：
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

### 2. 修改环境变量

编辑 `.env`，将：
```bash
DATABASE_URL="file:./dev.db"
```

改为：
```bash
DATABASE_URL=postgresql://aiwa_admin:密码@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud
```

### 3. 运行迁移

```bash
npx prisma migrate dev
```

---

## 💡 开发技巧

### 1. 热重载

使用 `npm run dev`（已配置），代码修改后自动重启。

### 2. 查看日志

终端直接显示所有日志，包括请求日志。

### 3. 调试

在代码中添加 `console.log()`，终端会显示输出。

### 4. 测试数据

使用 Prisma Studio 可以手动添加测试用户：
```bash
npx prisma studio
```

---

## 📊 SQLite vs PostgreSQL

| 特性 | SQLite | PostgreSQL |
|------|--------|------------|
| **设置** | ✅ 零配置 | ❌ 需要服务器 |
| **适合场景** | 开发/测试 | 生产环境 |
| **性能** | 单用户快 | 并发性能好 |
| **数据存储** | 单个文件 | 服务器 |
| **备份** | 复制文件 | 导出 SQL |
| **成本** | 免费 | 需要服务器 |

**推荐：**
- **本地开发**：SQLite（当前方案）
- **生产环境**：PostgreSQL（阿里云 RDS）

---

## 🎓 毕业设计使用

### 优点
- ✅ 设置简单，不会遇到 Docker 问题
- ✅ 演示效果好（可以看到数据库文件）
- ✅ 无需云端资源（本地运行即可）
- ✅ 代码迁移简单（切换到 PostgreSQL 只需改配置）

### 演示建议
1. **展示 Prisma Studio**
   - 运行 `npx prisma studio`
   - 展示用户数据表

2. **展示数据库文件**
   - 显示 `dev.db` 文件
   - 说明这是 SQLite 文件数据库

3. **展示 API 调用**
   - 使用 Postman 或 curl
   - 演示注册/登录流程

4. **说明扩展性**
   - 展示如何切换到 PostgreSQL
   - 说明生产环境部署方案

---

## 🚀 下一步

1. ✅ **本地测试完成**
   - API 正常运行
   - 注册/登录功能正常

2. 📋 **集成 Flutter 应用**
   - 配置 API 地址
   - 测试登录流程

3. 📋 **准备答辩材料**
   - 截图 Prisma Studio
   - 录制 API 调用视频
   - 准备架构说明

---

## 📞 需要帮助？

遇到问题？

1. 查看错误日志（终端输出）
2. 检查 `.env` 文件配置
3. 确认 Node.js 版本（`node --version`）
4. 尝试删除 `node_modules` 和 `dev.db`，重新开始

---

**祝你开发顺利！** 🎉

*如果遇到问题，优先查看终端错误信息，大部分问题都能从中找到原因。*

