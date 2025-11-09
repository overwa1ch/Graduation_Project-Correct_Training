# 快速开始指南

> 5 分钟快速体验 AIWA Auth API

---

## 🎯 目标

- 在本地运行认证 API（不使用 Docker）
- 测试注册/登录功能
- 准备部署到阿里云

---

## ⚡ 快速开始（推荐：SQLite 版本）

### 前置要求

- ✅ **Node.js 20+** - [下载地址](https://nodejs.org/)
- ✅ **npm**（随 Node.js 安装）

**不需要 Docker！**

### 第一步：进入项目目录

```bash
cd aiwa_cloud/core-api
```

### 第二步：配置环境

```bash
# Windows PowerShell
Copy-Item env.sqlite.example .env

# Linux/Mac
cp env.sqlite.example .env
```

生成 JWT 密钥并填入 `.env`：
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 第三步：安装并运行

```bash
# 安装依赖
npm install

# 配置 SQLite（复制 SQLite schema）
Copy-Item prisma\schema.sqlite.prisma prisma\schema.prisma
# Linux/Mac: cp prisma/schema.sqlite.prisma prisma/schema.prisma

# 创建数据库
npx prisma db push

# 启动开发服务器
npm run dev
```

看到以下输出说明成功：
```
🚀 AIWA Auth API listening on port 8080
📝 Environment: development
🌐 Access at: http://localhost:8080
```

⚠️ **Windows 用户：** 如果看到端口权限错误，端口可能在 Windows 保留范围内，已更新默认端口为 8080。

---

## 🐳 备选方案：使用 Docker（可选）

如果你已经配置好 Docker，也可以使用 Docker Compose：

```bash
cd aiwa_cloud
docker-compose up
```

⚠️ **注意：** 如果遇到 Docker 端口问题，建议使用上面的 SQLite 方案。

### 第四步：测试 API

#### 1. 健康检查

```bash
# SQLite 版本（默认端口 8080）
curl http://localhost:8080/health

# 或 Docker 版本（端口 3000）
curl http://localhost:3000/health
```

**预期响应：**
```json
{
  "status": "ok",
  "timestamp": "2025-11-02T12:00:00.000Z",
  "service": "aiwa-auth-api",
  "version": "1.0.0"
}
```

#### 2. 注册用户

```bash
# SQLite 版本
curl -X POST http://localhost:3001/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"

# 或 Docker 版本
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

**预期响应：**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "abc123def456..."
}
```

#### 3. 登录

```bash
# SQLite 版本
curl -X POST http://localhost:3001/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

#### 4. 刷新 Token

```bash
# 使用上面获取的 refresh_token
curl -X POST http://localhost:3001/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"你的refresh_token\"}"
```

---

## 🔍 查看数据库

### SQLite 版本

#### 方法1：使用 Prisma Studio（推荐）

```bash
cd core-api
npx prisma studio
```

浏览器自动打开：http://localhost:5555

#### 方法2：使用 SQLite 命令行

```bash
# 打开数据库文件
sqlite3 dev.db

# 查看表
.tables

# 查看用户
SELECT * FROM users;

# 退出
.quit
```

### Docker 版本（如果使用）

```bash
# 使用 psql
docker exec -it aiwa-postgres psql -U aiwa -d aiwa_auth

# 查看用户
SELECT id, email, status, created_at FROM users;

# 退出
\q
```

---

## 🛠️ 详细本地开发步骤（SQLite 版本）

### 1. 复制 SQLite Schema

```bash
cd core-api
Copy-Item prisma\schema.sqlite.prisma prisma\schema.prisma
# Linux/Mac: cp prisma/schema.sqlite.prisma prisma/schema.prisma
```

### 2. 配置环境变量

```bash
Copy-Item env.sqlite.example .env
# Linux/Mac: cp env.sqlite.example .env
```

编辑 `.env`，生成 JWT 密钥：

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

将输出的字符串填入 `JWT_ACCESS_SECRET` 和 `JWT_REFRESH_SECRET`。

**最小配置：**
```bash
DATABASE_URL="file:./dev.db"
JWT_ACCESS_SECRET=你的32字符密钥
JWT_REFRESH_SECRET=你的32字符密钥
PORT=3001
```

### 3. 安装依赖

```bash
npm install
```

### 4. 创建数据库

```bash
npx prisma db push
```

这会创建 `dev.db` 文件（SQLite 数据库）。

### 5. 启动开发服务器

```bash
npm run dev
```

API 运行在：**http://localhost:8080**（默认端口 8080）

### 6. 测试

```powershell
# PowerShell - 健康检查
Invoke-WebRequest -Uri http://localhost:8080/health -UseBasicParsing

# 或使用测试脚本（推荐）
.\测试API.ps1
```

```bash
# Linux/Mac - 健康检查
curl http://localhost:8080/health
```

---

## 📱 集成到 Flutter

### 1. 添加依赖

在 `pubspec.yaml` 中：

```yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
```

### 2. 创建 API 客户端

创建文件 `lib/services/auth_api.dart`：

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthApi {
  // 本地开发（SQLite 版本）
  static const String baseUrl = 'http://localhost:8080';
  
  // Android 模拟器
  // static const String baseUrl = 'http://10.0.2.2:8080';
  
  // 真机（替换为你的电脑局域网 IP）
  // static const String baseUrl = 'http://192.168.1.100:8080';
  
  // 阿里云部署后（替换为实际地址）
  // static const String baseUrl = 'http://你的ECS公网IP:8080';

  /// 注册新用户
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
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

  /// 用户登录
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('登录失败: ${response.body}');
    }
  }

  /// 刷新 Token
  static Future<String> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('刷新Token失败');
    }
  }
}
```

### 3. 使用示例

```dart
// 注册
try {
  final result = await AuthApi.register('user@example.com', 'password123');
  print('Access Token: ${result['token']}');
  print('Refresh Token: ${result['refresh_token']}');
  
  // 保存 token 到 secure storage
  await _secureStorage.write(key: 'access_token', value: result['token']);
  await _secureStorage.write(key: 'refresh_token', value: result['refresh_token']);
} catch (e) {
  print('注册失败: $e');
}

// 登录
try {
  final result = await AuthApi.login('user@example.com', 'password123');
  // 处理登录成功
} catch (e) {
  print('登录失败: $e');
}
```

---

## 🚀 部署到阿里云

准备好本地测试后，按照以下步骤部署：

### 1. 创建阿里云 RDS

详见：[ALIYUN_DEPLOYMENT.md](./ALIYUN_DEPLOYMENT.md#第一步创建-rds-postgresql-数据库)

### 2. 购买 ECS

详见：[ALIYUN_DEPLOYMENT.md](./ALIYUN_DEPLOYMENT.md#第二步购买-ecs-云服务器)

### 3. 部署应用

详见：[ALIYUN_DEPLOYMENT.md](./ALIYUN_DEPLOYMENT.md#第三步部署应用)

---

## 🐛 常见问题

### Q1: 端口 3001 被占用？

**A:** 修改 `.env` 文件中的 `PORT`：
```bash
PORT=3002  # 或其他可用端口
```

### Q2: Prisma 报错 "Unknown datasource provider"

**A:** 确保使用 SQLite schema：
```bash
# 确认 prisma/schema.prisma 中：
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}
```

### Q3: 数据库文件在哪里？

**A:** SQLite 数据库文件在 `core-api/dev.db`

查看：
```bash
# Windows
Get-ChildItem dev.db

# Linux/Mac
ls -lh dev.db
```

### Q4: Flutter 无法连接到本地 API

**A:** 
- **Android 模拟器**: 使用 `http://10.0.2.2:8080`
- **iOS 模拟器**: 使用 `http://localhost:8080`
- **真机**: 使用电脑的局域网 IP（如 `http://192.168.1.100:8080`）

⚠️ **注意端口是 8080**（SQLite 版本默认端口）

### Q5: JWT 错误 "jwt malformed"

**A:** 检查 JWT_ACCESS_SECRET 和 JWT_REFRESH_SECRET 是否已设置且长度足够（建议 32+ 字符）。

### Q6: 如何重置数据库？

**A:** 删除 `dev.db` 文件，然后重新运行：
```bash
Remove-Item dev.db  # Windows
# 或 rm dev.db  # Linux/Mac

npx prisma db push
```

---

## 📚 下一步

- 📖 阅读 [本地运行详细指南](./LOCAL_SETUP.md) - **SQLite 完整教程**
- 📖 阅读 [完整 README](./README.md)
- 📖 查看 [阿里云部署指南](./ALIYUN_DEPLOYMENT.md)
- 📖 了解 [API 端点详情](./README.md#api-文档)
- 📖 查看 [更新日志](./CHANGELOG.md)

---

## 💡 提示

- ✅ 开发时使用 Docker Compose，简单快速
- ✅ 生产部署推荐阿里云，速度快有学生优惠
- ✅ 记得修改默认的 JWT 密钥
- ✅ 使用 Flutter Secure Storage 存储 Token

---

**祝你开发顺利！** 🎉


