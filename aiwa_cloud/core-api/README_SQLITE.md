# SQLite 快速设置（Windows PowerShell）

## 🚀 3 步快速开始

### 第 1 步：进入目录

```powershell
cd aiwa_cloud\core-api
```

### 第 2 步：运行设置脚本（推荐）

```powershell
.\setup-sqlite.ps1
```

脚本会自动：
- ✅ 创建 `.env` 文件
- ✅ 配置 SQLite schema
- ✅ 生成 JWT 密钥
- ✅ 安装依赖
- ✅ 创建数据库

### 第 3 步：启动服务

```powershell
npm run dev
```

---

## 📝 手动设置（如果脚本失败）

### 步骤 1：进入目录

```powershell
cd aiwa_cloud\core-api
```

### 步骤 2：复制配置文件

```powershell
Copy-Item env.sqlite.example .env
Copy-Item prisma\schema.sqlite.prisma prisma\schema.prisma
```

### 步骤 3：生成 JWT 密钥

```powershell
# 生成第一个密钥（用于 JWT_ACCESS_SECRET）
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# 生成第二个密钥（用于 JWT_REFRESH_SECRET）
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

将输出的字符串填入 `.env` 文件中。

### 步骤 4：安装依赖

```powershell
npm install
```

### 步骤 5：创建数据库

```powershell
npx prisma db push
```

### 步骤 6：启动服务

```powershell
npm run dev
```

---

## ✅ 验证

打开新终端，测试 API：

```powershell
curl http://localhost:3001/health
```

应该返回 JSON 响应。

---

## 🐛 常见问题

### 问题：找不到文件

**错误：**
```
Copy-Item : 找不到路径...因为该路径不存在
```

**解决：**
确保你在正确的目录下：
```powershell
# 检查当前位置
Get-Location

# 应该显示：...\aiwa_cloud\core-api

# 如果不在，进入目录
cd aiwa_cloud\core-api
```

### 问题：端口被占用

**错误：**
```
Error: listen EADDRINUSE: address already in use :::3001
```

**解决：**
修改 `.env` 文件中的 `PORT`：
```powershell
# 编辑 .env 文件，将 PORT 改为其他端口
PORT=3002
```

---

## 📚 更多信息

- 详细文档：[LOCAL_SETUP.md](../LOCAL_SETUP.md)
- 快速开始：[QUICK_START.md](../QUICK_START.md)

