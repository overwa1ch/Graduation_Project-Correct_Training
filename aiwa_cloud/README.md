# AIWA Auth API (Simplified)

> **版本 2.0** - 简化版认证服务，适合毕业设计快速部署

基于 JWT 的用户认证 API，为 AIWA 健身姿态纠正应用提供用户管理功能。

---

## ✨ 特性

- ✅ **用户注册/登录** - 基于邮箱和密码
- ✅ **JWT 认证** - RS256 标准，access + refresh token
- ✅ **安全加密** - Bcrypt 密码哈希
- ✅ **快速部署** - Railway 一键部署
- ✅ **本地开发** - Docker Compose 零配置
- ✅ **可扩展** - 预留会话管理、云端分析模块接口

---

## 🚀 快速部署

### 方案1：Railway 部署（推荐）⭐

**最快 5 分钟上线！零运维经验要求！**

详细步骤请查看：**[RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md)**

**简要步骤：**
1. 登录 [Railway](https://railway.app/) → 连接 GitHub 仓库
2. Root Directory 设置为：`aiwa_cloud`
3. 添加 PostgreSQL 数据库
4. 配置环境变量（JWT密钥）
5. 自动部署完成！

**成本：** $5 试用额度，之后约 $10/月

---

### 方案2：本地开发（Docker Compose）

```bash
cd aiwa_cloud
docker-compose up
```

API 运行在：**http://localhost:3000**

测试：
```bash
curl http://localhost:3000/health
```

---

## 🏛️ 架构

### 简化版架构（当前实现）

```
Flutter App
    ↓ (HTTP/JSON)
Auth API (Fastify/Node.js)
    ↓ (SQL)
PostgreSQL Database
```

### 完整版架构（预留扩展）

```
Flutter App
    ↓ (HTTP/JSON)
Auth API
    ↓
会话管理 → AI Workers → 结果存储
```

---

## 📁 项目结构

```
aiwa_cloud/
├── core-api/                  # 认证 API
│   ├── src/
│   │   ├── modules/
│   │   │   └── auth/          # ✅ 注册、登录、Token
│   │   ├── lib/               # 加密、数据库
│   │   ├── config.ts          # 配置管理
│   │   └── main.ts            # 入口
│   ├── prisma/
│   │   └── schema.prisma      # ✅ User, RefreshToken
│   ├── Dockerfile
│   ├── package.json
│   └── env.example            # 环境变量模板
│
├── workers/                   # ❌ 已移除（AI功能在Flutter本地）
├── infra/
│   ├── archive/               # 归档的AWS/阿里云文档
│   └── terraform/             # 基础设施代码（未来）
│
├── docker-compose.yml         # ✅ 本地开发
├── railway.json               # ✅ Railway 部署配置
├── nixpacks.toml              # ✅ Railway 构建配置
├── RAILWAY_DEPLOYMENT.md      # ✅ 部署指南
└── README.md                  # 本文件
```

---

## 📚 API 文档

### 端点列表

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | `/health` | 健康检查 | ❌ |
| POST | `/v1/auth/register` | 用户注册 | ❌ |
| POST | `/v1/auth/login` | 用户登录 | ❌ |
| POST | `/v1/auth/refresh` | 刷新Token | ❌ |

### 快速示例

#### 1. 注册用户

```bash
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**响应：**
```json
{
  "token": "eyJhbGciOiJIUzI1...",
  "refresh_token": "abc123def456..."
}
```

#### 2. 登录

```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### 3. 刷新Token

```bash
curl -X POST http://localhost:3000/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "abc123def456..."
  }'
```

详细 API 规范：[docs/07-cloud/CLOUD_CORE_API.md](../docs/07-cloud/CLOUD_CORE_API.md)

---

## 🛠️ 技术栈

### 后端
- **Runtime**: Node.js 20
- **Framework**: Fastify 4.26
- **Language**: TypeScript 5.3
- **ORM**: Prisma 5.9
- **Database**: PostgreSQL 15
- **Auth**: JWT (@fastify/jwt)
- **Encryption**: Bcrypt

### 部署
- **Platform**: Railway (推荐) / Docker
- **CI/CD**: GitHub → Railway 自动部署

---

## 🔧 本地开发指南

### 1. 克隆项目

```bash
git clone <your-repo>
cd Graduation_Project-Correct_Training/aiwa_cloud
```

### 2. 配置环境

```bash
cd core-api
cp env.example .env
```

编辑 `.env` 文件：
```bash
DATABASE_URL=postgresql://aiwa:aiwa_dev_password@localhost:5432/aiwa_auth
JWT_ACCESS_SECRET=<生成一个随机字符串>
JWT_REFRESH_SECRET=<生成另一个随机字符串>
```

生成密钥：
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. 启动数据库

```bash
cd ..  # 回到 aiwa_cloud 目录
docker-compose up postgres -d
```

### 4. 安装依赖

```bash
cd core-api
npm install
```

### 5. 运行迁移

```bash
npx prisma migrate dev
```

### 6. 启动开发服务器

```bash
npm run dev
```

API 运行在：http://localhost:3000

### 7. 测试

```bash
# 健康检查
curl http://localhost:3000/health

# 注册
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## 📱 Flutter 集成

### 添加依赖

```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
```

### API 客户端示例

```dart
// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'https://your-app.up.railway.app';
  // 或本地开发: 'http://localhost:3000'

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('注册失败');
    }
  }
}
```

完整的 Flutter 集成示例请查看：[RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md)

---

## 🎓 毕业答辩建议

### 技术亮点

1. **全栈开发**
   - 前端：Flutter（跨平台移动应用）
   - 后端：Node.js + TypeScript（RESTful API）
   - 数据库：PostgreSQL（关系型数据库）

2. **现代架构**
   - 前后端分离
   - JWT 认证标准
   - Docker 容器化
   - PaaS 云部署

3. **工程实践**
   - TypeScript 类型安全
   - Prisma ORM 数据库迁移
   - 环境变量管理
   - Docker Compose 本地开发

### 演示建议

1. **展示 Railway Dashboard**
   - 部署状态
   - 环境变量配置
   - 日志监控

2. **API 测试（Postman/curl）**
   - 注册新用户
   - 登录获取 Token
   - Token 刷新

3. **Flutter 应用演示**
   - 登录界面
   - 与云端 API 通信
   - 用户信息展示

### 答辩话术

> "本项目采用 **前后端分离** 的现代架构设计：
> 
> - **前端**：Flutter 跨平台移动应用，实现姿态识别和分析
> - **后端**：Node.js + Fastify RESTful API，提供用户认证服务
> - **数据库**：PostgreSQL 关系型数据库
> - **部署**：Railway PaaS 平台，简化运维
> - **认证**：JWT RS256 行业标准
> 
> 目前实现了核心的用户认证功能，**预留了云端分析扩展接口**，
> 未来可以添加会话管理、云端AI分析等功能。"

---

## 🐛 故障排查

### 问题1：Docker 无法启动

**解决：**
```bash
docker-compose down -v  # 清理旧容器
docker-compose up       # 重新启动
```

### 问题2：数据库连接失败

**检查：**
- PostgreSQL 是否运行：`docker ps`
- DATABASE_URL 是否正确
- 端口 5432 是否被占用

### 问题3：JWT 错误

**检查：**
- JWT_ACCESS_SECRET 和 JWT_REFRESH_SECRET 是否已设置
- 密钥长度是否足够（建议 32+ 字符）

### 问题4：Railway 部署失败

**检查：**
- Root Directory 是否设置为 `aiwa_cloud`
- 环境变量是否完整
- 查看 Build Logs

---

## 📖 更多文档

- 📖 **[Railway 部署指南](./RAILWAY_DEPLOYMENT.md)** - 零基础部署教程
- 🔐 **[API 规范](../docs/07-cloud/CLOUD_CORE_API.md)** - 完整接口文档
- 🗄️ **[数据库 Schema](./core-api/prisma/schema.prisma)** - 数据模型
- 📦 **[归档文档](./infra/archive/)** - AWS/阿里云部署（已弃用）

---

## 🔄 版本历史

### v2.0.0 (2025-10-31) - 简化版

- ✅ 移除 AWS/阿里云依赖
- ✅ 移除 Workers 模块（AI功能在Flutter本地）
- ✅ 简化为纯认证服务
- ✅ 添加 Railway 部署支持
- ✅ 优化 Docker Compose 配置

### v1.0.0 (2025-10-30) - 完整版

- ✅ 完整的云端架构
- ✅ AWS S3 + SQS
- ✅ Python Workers (REINFER + ADVICE)

---

## 📧 支持

遇到问题？

1. 查看 [Railway 文档](https://docs.railway.app/)
2. 查看 [Fastify 文档](https://www.fastify.io/)
3. 查看 [Prisma 文档](https://www.prisma.io/)

---

## 📄 许可证

MIT License

---

**祝你答辩顺利！🎉**
