# AIWA Auth API（阿里云版本）

> **版本 3.0** - 简化认证服务，适合毕业设计部署到阿里云

基于 JWT 的用户认证 API，为 AIWA 健身姿态纠正应用提供用户登录/注册功能。

---

## ✨ 特性

- ✅ **用户注册/登录** - 基于邮箱和密码
- ✅ **JWT 认证** - RS256 标准，access + refresh token
- ✅ **安全加密** - Bcrypt 密码哈希
- ✅ **阿里云部署** - RDS PostgreSQL + ECS
- ✅ **本地开发** - Docker Compose 零配置
- ✅ **可扩展** - 预留文件存储接口（OSS）

---

## 🚀 快速部署

### 方案1：阿里云部署（推荐）⭐

**适合毕业设计，约 200 元/月！**

详细步骤请查看：**[ALIYUN_DEPLOYMENT.md](./ALIYUN_DEPLOYMENT.md)**

**简要步骤：**
1. 创建阿里云 RDS PostgreSQL 数据库
2. 购买 ECS 云服务器（2核2GB）
3. 安装 Docker 和 Docker Compose
4. 配置环境变量（数据库连接、JWT密钥）
5. 启动服务

**成本：** 
- 正常：约 200 元/月
- 学生优惠：约 90 元/月

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

### 当前架构（简化版）

```
Flutter App
    ↓ (HTTP/JSON)
Auth API (Fastify/Node.js)
    ↓ (SQL)
阿里云 RDS PostgreSQL
```

### 未来扩展（可选）

```
Flutter App
    ↓
Auth API
    ↓
阿里云 OSS（文件存储）
    ↓
训练数据管理
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
│   │   ├── config.ts          # 配置管理（含阿里云）
│   │   └── main.ts            # 入口
│   ├── prisma/
│   │   └── schema.prisma      # ✅ User, RefreshToken
│   ├── Dockerfile
│   ├── package.json
│   └── env.example            # 环境变量模板
│
├── my-app/                    # Next.js 管理后台（可选）
├── docker-compose.yml         # ✅ 本地开发
├── ALIYUN_DEPLOYMENT.md       # ✅ 阿里云部署指南
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

### 云服务（阿里云）
- **数据库**: RDS PostgreSQL
- **服务器**: ECS（可选）
- **对象存储**: OSS（可选，用于文件存储）

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
  // 阿里云 ECS 地址
  static const String baseUrl = 'http://你的ECS公网IP:3000';
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('登录失败');
    }
  }
}
```

---

## 🎓 毕业答辩建议

### 技术亮点

1. **全栈开发**
   - 前端：Flutter（跨平台移动应用）
   - 后端：Node.js + TypeScript（RESTful API）
   - 数据库：PostgreSQL（关系型数据库）
   - 云平台：阿里云（国内主流）

2. **现代架构**
   - 前后端分离
   - JWT 认证标准
   - Docker 容器化
   - 云端部署

3. **工程实践**
   - TypeScript 类型安全
   - Prisma ORM 数据库迁移
   - 环境变量管理
   - Docker Compose 本地开发

### 演示建议

1. **展示阿里云控制台**
   - RDS 数据库配置
   - ECS 服务器状态
   - （可选）OSS 存储桶

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
> - **数据库**：阿里云 RDS PostgreSQL（云端托管）
> - **部署**：阿里云 ECS，使用 Docker 容器化部署
> - **认证**：JWT 行业标准，支持 token 刷新
> 
> 目前实现了核心的用户认证功能，**预留了云端文件存储接口**，
> 未来可以添加训练数据存储、用户统计分析等功能。"

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
- 阿里云 RDS 白名单是否配置

### 问题3：JWT 错误

**检查：**
- JWT_ACCESS_SECRET 和 JWT_REFRESH_SECRET 是否已设置
- 密钥长度是否足够（建议 32+ 字符）

### 问题4：阿里云部署失败

**检查：**
- RDS 和 ECS 是否在同一地域和 VPC
- 环境变量是否正确配置
- 安全组是否放行端口

---

## 📖 更多文档

- 📖 **[阿里云部署指南](./ALIYUN_DEPLOYMENT.md)** - 完整部署教程
- 🗄️ **[数据库 Schema](./core-api/prisma/schema.prisma)** - 数据模型

---

## 🔄 版本历史

### v3.0.0 (2025-11-02) - 阿里云版本

- ✅ 删除 AWS/Railway 依赖
- ✅ 添加阿里云 RDS 支持
- ✅ 预留 OSS 对象存储接口
- ✅ 简化为纯认证服务
- ✅ 优化毕业设计部署流程

### v2.0.0 (2025-10-31) - Railway 版本

- ✅ 移除 AWS 依赖
- ✅ 添加 Railway 部署支持
- ✅ 简化架构

### v1.0.0 (2025-10-30) - AWS 版本

- ✅ 完整的云端架构
- ✅ AWS S3 + SQS + Lambda

---

## 💰 成本对比

| 云平台 | 配置 | 月费用 |
|--------|------|--------|
| **阿里云** | RDS 1核2GB + ECS 2核2GB | ¥200 |
| 阿里云学生 | 同上（学生优惠） | ¥90 |
| Railway | PostgreSQL + 1 服务 | $10 (¥70) |
| AWS | RDS + EC2 | $20 (¥140) |

**推荐：** 国内毕业设计使用阿里云（速度快、有学生优惠）

---

## 📧 支持

遇到问题？

1. 查看 [阿里云文档](https://help.aliyun.com/)
2. 查看 [Fastify 文档](https://www.fastify.io/)
3. 查看 [Prisma 文档](https://www.prisma.io/)

---

## 📄 许可证

MIT License

---

**祝你答辩顺利！🎉**
