# Railway 部署指南

> **简化版 AIWA Auth API - 适合毕业设计快速部署**

## 🚀 快速开始

### 前提条件
- GitHub 账号
- Railway 账号（用 GitHub 登录：https://railway.app/）

---

## 📝 部署步骤

### 1. 准备代码

确保你的代码已推送到 GitHub。

### 2. 创建 Railway 项目

1. 登录 [Railway Dashboard](https://railway.app/dashboard)
2. 点击 **"New Project"**
3. 选择 **"Deploy from GitHub repo"**
4. 授权并选择你的仓库：`Graduation_Project-Correct_Training`
5. **Root Directory** 设置为：`aiwa_cloud`

### 3. 添加 PostgreSQL 数据库

1. 在项目页面点击 **"+ New"**
2. 选择 **"Database"** → **"PostgreSQL"**
3. Railway 会自动创建数据库并生成 `DATABASE_URL` 环境变量

### 4. 配置环境变量

在 Auth API 服务的 **"Variables"** 标签添加：

#### 必需变量：

```bash
# JWT 密钥（生成两个不同的随机字符串）
JWT_ACCESS_SECRET=<生成的密钥1>
JWT_REFRESH_SECRET=<生成的密钥2>

# 环境
NODE_ENV=production

# 端口（Railway 自动配置，通常不需要改）
PORT=3000

# CORS（允许所有来源，或设置为你的Flutter应用域名）
CORS_ORIGIN=*
```

#### 生成 JWT 密钥的方法：

**方法1：使用 Node.js**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

**方法2：使用在线工具**
- https://generate-secret.vercel.app/32

**方法3：使用 OpenSSL**
```bash
openssl rand -hex 32
```

生成两个不同的密钥，分别用于 `JWT_ACCESS_SECRET` 和 `JWT_REFRESH_SECRET`。

### 5. 部署

1. Railway 会自动检测到 `nixpacks.toml` 配置
2. 点击 **"Deploy"** 开始构建
3. 等待 3-5 分钟完成部署

### 6. 获取 API 地址

部署成功后，Railway 会生成一个公开 URL，例如：
```
https://aiwa-auth-api-production.up.railway.app
```

你可以在 **"Settings"** → **"Domains"** 中找到。

---

## ✅ 测试部署

### 1. 测试健康检查

```bash
curl https://your-app.up.railway.app/health
```

**预期响应：**
```json
{
  "status": "ok",
  "timestamp": "2025-10-31T...",
  "service": "aiwa-auth-api",
  "version": "1.0.0"
}
```

### 2. 测试注册

```bash
curl -X POST https://your-app.up.railway.app/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**预期响应：**
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refresh_token": "abc123..."
}
```

### 3. 测试登录

```bash
curl -X POST https://your-app.up.railway.app/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

---

## 📱 Flutter 集成

### 配置 API 地址

在 Flutter 项目中创建配置文件：

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Railway 生产环境地址
  static const String baseUrl = 'https://your-app.up.railway.app';
  
  // 或者使用环境变量
  static String get apiUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    if (env == 'production') {
      return 'https://your-app.up.railway.app';
    }
    return 'http://localhost:3000'; // 本地开发
  }
}
```

### 使用 API

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('注册失败: ${response.body}');
    }
  }
}
```

---

## 💰 成本估算

### Railway 免费额度
- **初始信用**：$5 试用额度
- **PostgreSQL**：包含在套餐内
- **API 服务**：包含在套餐内

### 付费套餐（试用后）
- **Hobby Plan**：$5/月
- **Pro Plan**：$20/月（更多资源）

**预计成本**：
- 试用期：免费
- 之后：约 $10-15/月（Hobby Plan + 数据库）

---

## 🔧 本地开发

### 使用 Docker Compose

```bash
cd aiwa_cloud
docker-compose up
```

API 将运行在 `http://localhost:3000`

### 直接运行

```bash
cd aiwa_cloud/core-api

# 安装依赖
npm install

# 生成 Prisma 客户端
npx prisma generate

# 运行数据库迁移
npx prisma migrate dev

# 启动开发服务器
npm run dev
```

---

## 📊 监控和日志

### 查看日志

在 Railway Dashboard 的 **"Deployments"** 标签：
1. 点击最新的部署
2. 查看 **"View Logs"**

### 查看数据库

Railway 提供内置的数据库管理工具：
1. 点击 PostgreSQL 服务
2. 点击 **"Data"** 标签
3. 或者使用 Railway CLI：
   ```bash
   railway connect postgres
   ```

---

## 🐛 故障排查

### 问题1：部署失败

**检查：**
- 查看 Build Logs
- 确认 `nixpacks.toml` 在 `aiwa_cloud/` 目录
- 确认 Root Directory 设置为 `aiwa_cloud`

### 问题2：API 无法连接数据库

**检查：**
- PostgreSQL 服务是否正常运行
- `DATABASE_URL` 环境变量是否正确（Railway 自动生成）

### 问题3：JWT 错误

**检查：**
- `JWT_ACCESS_SECRET` 和 `JWT_REFRESH_SECRET` 是否已设置
- 密钥长度是否足够（建议 32+ 字符）

### 问题4：CORS 错误

**解决：**
- 在 Railway 环境变量设置：`CORS_ORIGIN=*`
- 或者设置为你的 Flutter 应用域名

---

## 📚 API 文档

### 端点列表

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/health` | 健康检查 |
| POST | `/v1/auth/register` | 用户注册 |
| POST | `/v1/auth/login` | 用户登录 |
| POST | `/v1/auth/refresh` | 刷新 Token |

详细 API 文档请参考：`docs/07-cloud/CLOUD_CORE_API.md`

---

## 🎓 毕业答辩建议

### 展示点

1. **全栈能力**
   - 展示 Railway Dashboard
   - 演示 API 调用（Postman/curl）
   - 展示 Flutter 应用连接云端

2. **架构设计**
   - 说明为什么选择 Railway（简单、成本低）
   - 展示 Docker Compose 本地开发
   - 讲解 JWT 认证机制

3. **可扩展性**
   - 指出预留的 Session/Job 模型（在 schema.prisma 注释中）
   - 说明未来可以添加云端 AI 分析

### 答辩话术

> "本项目采用 **前后端分离架构**：
> 
> - **前端**：Flutter 跨平台移动应用
> - **后端**：Node.js + Fastify RESTful API
> - **数据库**：PostgreSQL
> - **部署**：Railway PaaS 平台
> - **认证**：JWT RS256 标准
> 
> 目前实现了用户认证模块，未来可扩展为完整的云端分析平台。"

---

## 📧 支持

遇到问题？
- 查看 Railway 文档：https://docs.railway.app/
- 查看项目 README：`aiwa_cloud/README.md`
- 检查日志：Railway Dashboard → Deployments → View Logs

---

**祝部署顺利！🎉**

