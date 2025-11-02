# 部署检查清单

> 部署前请逐项检查，确保万无一失

---

## 📋 本地开发环境检查

### 环境准备
- [ ] 已安装 Docker Desktop（Windows/Mac）或 Docker（Linux）
- [ ] 已安装 Docker Compose
- [ ] 已安装 Node.js 20+
- [ ] 已安装 Git

### 代码检查
- [ ] 已克隆项目到本地
- [ ] 代码在最新的 main/master 分支
- [ ] 无未提交的重要更改

### 环境配置
- [ ] 已复制 `core-api/env.example` 为 `core-api/.env`
- [ ] 已填写 `DATABASE_URL`（本地开发用默认值即可）
- [ ] 已生成并填写 `JWT_ACCESS_SECRET`（32字符以上）
- [ ] 已生成并填写 `JWT_REFRESH_SECRET`（32字符以上）

### 本地测试
- [ ] 运行 `docker-compose up` 无错误
- [ ] 访问 `http://localhost:3000/health` 返回正常
- [ ] 测试注册接口成功
- [ ] 测试登录接口成功
- [ ] 测试刷新Token成功

---

## 🚀 阿里云部署检查

### 1. 阿里云 RDS PostgreSQL

#### 创建实例
- [ ] 已登录阿里云控制台
- [ ] 选择地域：华东1（杭州）或最近地域
- [ ] 数据库版本：PostgreSQL 15
- [ ] 规格：1核2GB 基础版（或更高）
- [ ] 存储空间：20GB SSD
- [ ] 网络：专有网络 VPC

#### 配置数据库
- [ ] 已设置白名单（允许 ECS 内网 IP 或 0.0.0.0/0 测试）
- [ ] 已创建数据库：`aiwa_cloud`
- [ ] 已创建账号：`aiwa_admin`（或自定义）
- [ ] 已记录密码（强密码）
- [ ] 已测试连接（使用 psql 或 DBeaver）

#### 获取连接信息
- [ ] 已记录内网地址：`rm-xxxxx.pg.rds.aliyuncs.com`
- [ ] 已记录端口：`5432`
- [ ] 连接字符串格式正确：
  ```
  postgresql://aiwa_admin:密码@rm-xxxxx.pg.rds.aliyuncs.com:5432/aiwa_cloud
  ```

### 2. 阿里云 ECS 云服务器

#### 购买实例
- [ ] 已购买 ECS（推荐：2核2GB，按量付费）
- [ ] 地域与 RDS 相同
- [ ] 网络与 RDS 在同一 VPC
- [ ] 已分配公网 IP
- [ ] 操作系统：Ubuntu 22.04 或 CentOS 8

#### 配置安全组
- [ ] 已放行 SSH 端口：22
- [ ] 已放行 API 端口：3000
- [ ] 已记录公网 IP 地址

#### 连接测试
- [ ] 可以通过 SSH 连接到 ECS
- [ ] 可以从 ECS 连接到 RDS（内网）

### 3. 环境搭建

#### 安装依赖
- [ ] 已安装 Docker
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  ```
- [ ] 已安装 Docker Compose
  ```bash
  apt install docker-compose -y  # Ubuntu
  # 或 yum install docker-compose -y  # CentOS
  ```
- [ ] 已安装 Git
  ```bash
  apt install git -y
  ```

#### 上传代码
- [ ] 方法A：Git clone（推荐）
  ```bash
  git clone <your-repo-url>
  cd aiwa_cloud
  ```
- [ ] 方法B：SCP 上传
  ```bash
  scp -r aiwa_cloud root@ECS公网IP:/root/
  ```

### 4. 配置应用

#### 环境变量
- [ ] 已创建 `core-api/.env` 文件
- [ ] `DATABASE_URL` 使用 RDS **内网地址**
- [ ] `JWT_ACCESS_SECRET` 与本地开发不同（重新生成）
- [ ] `JWT_REFRESH_SECRET` 与本地开发不同（重新生成）
- [ ] `NODE_ENV=production`
- [ ] `PORT=3000`
- [ ] `CORS_ORIGIN` 设置为实际域名（或 `*` 测试）

#### 数据库迁移
- [ ] 已进入容器：`docker exec -it aiwa-auth-api sh`
- [ ] 已运行迁移：`npx prisma migrate deploy`
- [ ] 数据库表已创建（users, refresh_tokens）

### 5. 启动服务

#### 部署
- [ ] 运行 `docker-compose up -d --build`
- [ ] 容器启动成功：`docker ps` 显示 aiwa-auth-api
- [ ] 查看日志无错误：`docker-compose logs -f auth-api`

#### 健康检查
- [ ] 内网访问成功：`curl http://localhost:3000/health`
- [ ] 公网访问成功：`http://ECS公网IP:3000/health`
- [ ] 返回 JSON：`{"status":"ok",...}`

### 6. 功能测试

#### API 测试（使用 Postman 或 curl）
- [ ] 注册新用户成功
  ```bash
  curl -X POST http://ECS公网IP:3000/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"password123"}'
  ```
- [ ] 返回 token 和 refresh_token
- [ ] 登录成功
- [ ] Token 刷新成功

#### 数据库验证
- [ ] 用户数据已写入数据库
- [ ] refresh_tokens 表有记录

### 7. Flutter 应用集成

#### 配置
- [ ] Flutter 项目中已配置 API 地址
  ```dart
  static const String baseUrl = 'http://ECS公网IP:3000';
  ```
- [ ] 已添加 http 依赖
- [ ] 已添加 flutter_secure_storage 依赖

#### 测试
- [ ] Flutter 应用可以注册用户
- [ ] Flutter 应用可以登录
- [ ] Token 正确保存到 secure storage
- [ ] 自动 Token 刷新机制工作正常

---

## 🔒 安全检查

### 密码和密钥
- [ ] 数据库密码是强密码（包含大小写、数字、符号）
- [ ] JWT 密钥长度 ≥ 32 字符
- [ ] JWT 密钥是随机生成的（未使用示例值）
- [ ] 生产环境密钥与开发环境不同

### 网络安全
- [ ] 生产环境 RDS 白名单限制为 ECS 内网 IP（不是 0.0.0.0/0）
- [ ] ECS 安全组规则配置合理
- [ ] 考虑使用 HTTPS（可选，使用 Nginx + Let's Encrypt）

### 数据备份
- [ ] 已启用 RDS 自动备份（建议 7 天保留）
- [ ] 了解如何手动备份数据库

---

## 📊 性能监控

### 基础监控
- [ ] 查看 Docker 容器状态：`docker stats`
- [ ] 查看 RDS 性能监控（阿里云控制台）
- [ ] 查看 ECS CPU/内存使用率

### 日志管理
- [ ] 了解如何查看应用日志：`docker-compose logs -f auth-api`
- [ ] 了解如何查看数据库慢查询日志
- [ ] 考虑日志清理策略

---

## 💰 成本控制

### 资源使用
- [ ] 已确认 RDS 规格（1核2GB 约 ¥150/月）
- [ ] 已确认 ECS 规格（2核2GB 约 ¥50/月）
- [ ] 是否使用学生优惠（约 55% 折扣）

### 节省建议
- [ ] 考虑使用按量付费（灵活但需监控）
- [ ] 考虑包年包月（更便宜但不灵活）
- [ ] 不使用时可以停止 ECS（但保留数据）

---

## 🎓 答辩准备

### 演示材料
- [ ] 准备架构图（前端-后端-数据库）
- [ ] 准备 API 测试截图（Postman）
- [ ] 准备阿里云控制台截图（RDS + ECS）
- [ ] 准备 Flutter 应用演示视频/截图

### 技术文档
- [ ] 项目 README.md 完整
- [ ] API 文档清晰
- [ ] 数据库 Schema 文档
- [ ] 部署文档完整

### 常见问题准备
- [ ] 为什么选择阿里云？
- [ ] 如何保证数据安全？
- [ ] 如何扩展功能？
- [ ] 成本如何控制？

---

## ✅ 最终检查

### 部署完成标志
- [ ] ✅ 所有服务运行正常
- [ ] ✅ API 响应正常
- [ ] ✅ 数据库连接正常
- [ ] ✅ Flutter 应用可以连接云端
- [ ] ✅ 功能测试全部通过

### 文档齐全
- [ ] ✅ README.md
- [ ] ✅ ALIYUN_DEPLOYMENT.md
- [ ] ✅ QUICK_START.md
- [ ] ✅ 本检查清单

---

## 📞 问题排查

遇到问题时按以下顺序排查：

1. **查看日志**
   ```bash
   docker-compose logs -f auth-api
   ```

2. **检查容器状态**
   ```bash
   docker ps
   docker stats
   ```

3. **测试数据库连接**
   ```bash
   docker exec -it aiwa-auth-api sh
   npx prisma db pull
   ```

4. **检查网络**
   - ECS 安全组
   - RDS 白名单
   - VPC 配置

5. **查阅文档**
   - [ALIYUN_DEPLOYMENT.md](./ALIYUN_DEPLOYMENT.md)
   - [README.md](./README.md)

---

## 🎉 完成！

如果所有检查项都已完成，恭喜你成功部署了 AIWA Auth API！

**下一步：**
- 继续开发 Flutter 应用
- 添加更多功能（用户信息、头像上传等）
- 准备毕业答辩材料

**祝你答辩顺利！** 🚀

