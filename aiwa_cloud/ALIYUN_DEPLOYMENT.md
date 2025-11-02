# 阿里云部署指南

> **适用于毕业设计快速部署**  
> 最小配置：仅需 RDS PostgreSQL + ECS（约200元/月）

---

## 📋 目录

1. [快速开始](#快速开始)（最小配置）
2. [详细步骤](#详细步骤)
3. [成本估算](#成本估算)
4. [扩展功能](#扩展功能)（可选）
5. [故障排查](#故障排查)

---

## 🚀 快速开始

### 最小配置（仅登录功能）

**所需资源：**
- ✅ RDS PostgreSQL（数据库）
- ✅ ECS 云服务器（运行 API）
- ❌ OSS 对象存储（暂不需要）
- ❌ MNS 消息队列（暂不需要）

**预计费用：** 约 200 元/月

---

## 📝 详细步骤

### 第一步：创建 RDS PostgreSQL 数据库

#### 1. 登录阿里云控制台

访问 [阿里云控制台](https://console.aliyun.com/) → 云数据库 RDS → PostgreSQL 版

#### 2. 创建实例

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| **计费方式** | 按量付费 | 适合毕业设计，可随时释放 |
| **地域** | 华东1（杭州） | 选择最近的地域 |
| **数据库版本** | PostgreSQL 15 | 最新稳定版 |
| **系列** | 基础版 | 单机版，成本最低 |
| **规格** | pg.n2.small.1 | 1核2GB，约150元/月 |
| **存储空间** | 20GB | 足够毕业设计使用 |
| **网络类型** | 专有网络 VPC | 推荐 |

点击"立即购买"并完成支付。

#### 3. 配置数据库

实例创建完成后（约5-10分钟）：

1. **设置白名单**
   - 进入实例详情 → 数据安全性 → 白名单设置
   - 添加：`0.0.0.0/0`（允许所有IP，测试用）
   - 生产环境：只添加 ECS 的内网 IP

2. **创建数据库账号**
   - 进入实例详情 → 账号管理 → 创建账号
   - **账号名称**：`aiwa_admin`
   - **账号类型**：高权限账号
   - **密码**：设置强密码（记录保存！）

3. **创建数据库**
   - 进入实例详情 → 数据库管理 → 创建数据库
   - **数据库名称**：`aiwa_cloud`
   - **支持字符集**：UTF8
   - **授权账号**：`aiwa_admin`（读写权限）

4. **获取连接信息**
   
   在实例概览页找到：
   - **内网地址**：`rm-xxxxxxxxxxxxx.pg.rds.aliyuncs.com`
   - **端口**：`5432`
   
   连接字符串格式：
   ```
   postgresql://aiwa_admin:你的密码@rm-xxxxxxxxxxxxx.pg.rds.aliyuncs.com:5432/aiwa_cloud
   ```

---

### 第二步：购买 ECS 云服务器

#### 1. 创建 ECS 实例

访问 控制台 → 云服务器 ECS → 实例列表 → 创建实例

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| **计费方式** | 按量付费 | 灵活，用多少付多少 |
| **地域** | 华东1（杭州） | 与 RDS 同地域 |
| **实例规格** | ecs.t6.medium | 2核2GB，约50元/月 |
| **镜像** | Ubuntu 22.04 | 或 CentOS 8 |
| **网络** | 与 RDS 同一 VPC | 重要！ |
| **公网IP** | 分配 | 需要公网访问 |
| **安全组** | 放行 22, 3000 端口 | SSH + API |

#### 2. 配置安全组

进入实例详情 → 安全组 → 配置规则 → 添加规则：

| 端口 | 协议 | 授权对象 | 说明 |
|------|------|----------|------|
| 22 | TCP | 你的IP | SSH登录 |
| 3000 | TCP | 0.0.0.0/0 | API访问 |

---

### 第三步：部署应用

#### 1. 连接到 ECS

```bash
ssh root@你的ECS公网IP
```

#### 2. 安装 Docker 和 Docker Compose

```bash
# 更新软件包
apt update && apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 安装 Docker Compose
apt install docker-compose -y

# 验证安装
docker --version
docker-compose --version
```

#### 3. 上传项目代码

**方法A：使用 Git（推荐）**

```bash
# 安装 git
apt install git -y

# 克隆项目
git clone https://github.com/你的用户名/你的仓库.git
cd 你的仓库/aiwa_cloud
```

**方法B：使用 SCP 上传**

在本地电脑执行：
```bash
scp -r aiwa_cloud root@你的ECS公网IP:/root/
```

#### 4. 配置环境变量

```bash
cd aiwa_cloud/core-api
cp env.example .env
nano .env  # 或使用 vim
```

编辑 `.env` 文件，填写以下内容：

```bash
# 数据库（使用阿里云 RDS 内网地址）
DATABASE_URL=postgresql://aiwa_admin:你的密码@rm-xxxxxxxxxxxxx.pg.rds.aliyuncs.com:5432/aiwa_cloud

# JWT密钥（必须生成随机值！）
JWT_ACCESS_SECRET=your_random_access_secret_32_characters_min
JWT_REFRESH_SECRET=your_random_refresh_secret_32_characters_min

# 服务器
PORT=3000
NODE_ENV=production
CORS_ORIGIN=*
```

生成随机密钥：
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

保存并退出（`Ctrl+X` → `Y` → `Enter`）

#### 5. 启动服务

```bash
# 返回 aiwa_cloud 目录
cd /root/你的仓库/aiwa_cloud

# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f auth-api
```

#### 6. 测试 API

```bash
# 健康检查
curl http://localhost:3000/health

# 注册用户
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

如果返回 token，说明部署成功！

#### 7. 配置数据库（首次部署）

```bash
# 进入容器
docker exec -it aiwa-auth-api sh

# 运行数据库迁移
npx prisma migrate deploy

# 退出容器
exit
```

---

### 第四步：配置域名（可选）

#### 使用阿里云域名

1. 在阿里云购买域名（约50元/年）
2. 添加 A 记录指向 ECS 公网 IP
3. 等待 DNS 生效（5-10分钟）
4. 访问：`http://你的域名.com:3000/health`

#### 配置 HTTPS（可选）

使用 Let's Encrypt 免费证书：

```bash
# 安装 Certbot
apt install certbot -y

# 获取证书
certbot certonly --standalone -d 你的域名.com
```

---

## 💰 成本估算

### 最小配置（按量付费）

| 服务 | 规格 | 月费用 |
|------|------|--------|
| RDS PostgreSQL | 1核2GB 基础版 | ¥150 |
| ECS | 2核2GB | ¥50 |
| 公网流量 | 1GB/月 | ¥1 |
| **总计** | | **¥201/月** |

### 学生优惠

阿里云学生优惠：
- ECS：约 ¥10/月（2核2GB）
- RDS：约 ¥80/月（学生特惠）
- **总计：约 ¥90/月**

申请地址：[阿里云学生计划](https://www.aliyun.com/minisite/goods)

---

## 🔄 扩展功能（未来需要时）

### 添加文件存储（OSS）

如果后续需要存储用户头像、训练视频等：

1. **创建 OSS Bucket**
   - 控制台 → 对象存储 OSS → 创建 Bucket
   - 名称：`aiwa-storage-prod`
   - 地域：与 ECS 同地域
   - 读写权限：私有

2. **创建 RAM 子账号**
   - 控制台 → 访问控制 RAM → 用户管理
   - 创建用户，获取 AccessKey
   - 授予 OSS 读写权限

3. **更新环境变量**
   ```bash
   USE_ALIYUN_OSS=true
   ALIYUN_REGION=oss-cn-hangzhou
   ALIYUN_ACCESS_KEY_ID=你的AccessKeyId
   ALIYUN_SECRET_ACCESS_KEY=你的AccessKeySecret
   ALIYUN_OSS_BUCKET=aiwa-storage-prod
   ```

4. **重启服务**
   ```bash
   docker-compose restart auth-api
   ```

### 数据库扩展表

需要存储训练数据时，可以在 `schema.prisma` 中取消注释 `TrainingSession` 表。

---

## 🐛 故障排查

### 问题1：无法连接数据库

**症状：** `Connection refused` 或 `timeout`

**解决：**
1. 检查 RDS 白名单是否包含 ECS 内网 IP
2. 检查 `DATABASE_URL` 是否使用**内网地址**
3. 确认 ECS 和 RDS 在同一 VPC

```bash
# 测试数据库连接
docker exec -it aiwa-auth-api sh
apt install postgresql-client
psql "postgresql://aiwa_admin:密码@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud"
```

### 问题2：Docker 容器无法启动

**症状：** `docker-compose up` 报错

**解决：**
```bash
# 查看详细日志
docker-compose logs auth-api

# 检查 .env 文件
cat core-api/.env

# 清理重建
docker-compose down -v
docker-compose up --build
```

### 问题3：API 无法访问

**症状：** `curl: (7) Failed to connect`

**解决：**
1. 检查安全组是否放行 3000 端口
2. 检查容器是否运行：`docker ps`
3. 检查端口监听：`netstat -tuln | grep 3000`

### 问题4：JWT 错误

**症状：** `Invalid token` 或 `jwt malformed`

**解决：**
- 确认 `JWT_ACCESS_SECRET` 和 `JWT_REFRESH_SECRET` 已设置
- 密钥长度至少 32 字符
- 重新生成密钥并重启服务

---

## 📱 Flutter 应用集成

在 Flutter 应用中配置 API 地址：

```dart
// lib/config/api_config.dart
class ApiConfig {
  // 开发环境（本地）
  static const String devBaseUrl = 'http://localhost:3000';
  
  // 生产环境（阿里云 ECS）
  static const String prodBaseUrl = 'http://你的ECS公网IP:3000';
  // 或使用域名: 'https://api.yourdomain.com'
  
  static String get baseUrl {
    return const bool.fromEnvironment('dart.vm.product')
        ? prodBaseUrl
        : devBaseUrl;
  }
}
```

---

## 🎓 毕业答辩建议

### 技术亮点

1. **云端部署**
   - 使用阿里云 RDS PostgreSQL（关系型数据库）
   - 使用 Docker 容器化部署
   - 前后端分离架构

2. **安全性**
   - JWT 认证
   - Bcrypt 密码加密
   - HTTPS 传输（可选）

3. **可扩展性**
   - 数据库预留扩展字段
   - 支持后续添加文件存储（OSS）
   - 模块化设计

### 演示要点

1. 展示阿里云控制台（RDS、ECS）
2. 演示 API 调用（Postman 或 curl）
3. 展示 Flutter 应用与云端交互
4. 展示数据库中的用户数据

---

## 📞 技术支持

- **阿里云文档**: https://help.aliyun.com/
- **RDS PostgreSQL**: https://help.aliyun.com/product/26090.html
- **ECS**: https://help.aliyun.com/product/25365.html

---

## 📝 更新日志

- **v3.0** (2025-11-02): 简化版，专注登录功能 + 阿里云部署
- **v2.0** (2025-10-31): 移除 AWS，添加 Railway 支持
- **v1.0** (2025-10-30): 初始版本（AWS 架构）

---

**祝你毕业设计顺利！🎉**


