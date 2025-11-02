# 快速开始指南

> 5 分钟快速体验 AIWA Auth API

---

## 🎯 目标

- 在本地运行认证 API
- 测试注册/登录功能
- 准备部署到阿里云

---

## ⚡ 快速开始

### 前置要求

- ✅ Docker 和 Docker Compose
- ✅ Node.js 20+（可选，本地开发用）
- ✅ Git

### 第一步：克隆项目

```bash
# 克隆仓库
git clone <你的仓库地址>
cd Graduation_Project-Correct_Training/aiwa_cloud
```

### 第二步：启动服务

```bash
# 使用 Docker Compose 一键启动
docker-compose up
```

等待容器启动（约 30 秒），你会看到：

```
aiwa-auth-api | 🚀 AIWA Auth API listening on port 3000
aiwa-auth-api | 📝 Environment: development
```

### 第三步：测试 API

#### 1. 健康检查

```bash
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
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
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
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

#### 4. 刷新 Token

```bash
# 使用上面获取的 refresh_token
curl -X POST http://localhost:3000/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"你的refresh_token"}'
```

---

## 🔍 查看数据库

### 方法1：使用 Prisma Studio

```bash
cd core-api
npx prisma studio
```

浏览器打开：http://localhost:5555

### 方法2：使用 psql

```bash
# 连接到数据库
docker exec -it aiwa-postgres psql -U aiwa -d aiwa_auth

# 查看用户
SELECT id, email, status, created_at FROM users;

# 退出
\q
```

---

## 🛠️ 本地开发（不使用 Docker）

### 1. 启动数据库

```bash
docker-compose up postgres -d
```

### 2. 安装依赖

```bash
cd core-api
npm install
```

### 3. 配置环境

```bash
cp env.example .env
```

编辑 `.env`，生成 JWT 密钥：

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

将输出的字符串填入 `JWT_ACCESS_SECRET` 和 `JWT_REFRESH_SECRET`。

### 4. 运行迁移

```bash
npx prisma migrate dev
```

### 5. 启动开发服务器

```bash
npm run dev
```

API 运行在：http://localhost:3000

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
  // 本地开发
  static const String baseUrl = 'http://localhost:3000';
  
  // 阿里云部署后（替换为实际地址）
  // static const String baseUrl = 'http://你的ECS公网IP:3000';

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

### Q1: Docker 容器启动失败

**A:** 检查端口占用：

```bash
# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :5432

# Linux/Mac
lsof -i :3000
lsof -i :5432
```

如果端口被占用，停止占用的进程或修改 `docker-compose.yml` 中的端口。

### Q2: 数据库连接失败

**A:** 确保 PostgreSQL 容器已启动：

```bash
docker ps | grep postgres
```

重启数据库：

```bash
docker-compose restart postgres
```

### Q3: Flutter 无法连接到本地 API

**A:** 
- **Android 模拟器**: 使用 `http://10.0.2.2:3000`
- **iOS 模拟器**: 使用 `http://localhost:3000`
- **真机**: 使用电脑的局域网 IP（如 `http://192.168.1.100:3000`）

### Q4: JWT 错误 "jwt malformed"

**A:** 检查 JWT_ACCESS_SECRET 和 JWT_REFRESH_SECRET 是否已设置且长度足够（建议 32+ 字符）。

---

## 📚 下一步

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


