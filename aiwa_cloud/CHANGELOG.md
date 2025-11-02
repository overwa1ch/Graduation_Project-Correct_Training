# 更新日志

## [3.0.0] - 2025-11-02

### 🎯 重大更改 - 简化架构，迁移到阿里云

#### 新增
- ✅ 阿里云 RDS PostgreSQL 支持
- ✅ 阿里云 OSS 预留接口（可选）
- ✅ 完整的阿里云部署文档
- ✅ Docker Compose 本地开发环境
- ✅ 环境变量配置模板

#### 删除
- ❌ AWS SDK 及相关代码
- ❌ Railway 部署配置
- ❌ Workers 模块（AI功能在Flutter本地）
- ❌ Sessions/Jobs/Results 模块（简化为纯认证）
- ❌ Terraform 基础设施代码
- ❌ 复杂的云端架构

#### 保留
- ✅ 用户注册/登录功能
- ✅ JWT 认证（Access + Refresh Token）
- ✅ Bcrypt 密码加密
- ✅ Prisma ORM
- ✅ Fastify 框架

#### 架构变化

**之前（v2.0）：**
```
Flutter App → Auth API → PostgreSQL
            ↓
      Railway 部署
```

**现在（v3.0）：**
```
Flutter App → Auth API → 阿里云 RDS PostgreSQL
            ↓
      阿里云 ECS（Docker）
            ↓
      可选：阿里云 OSS（文件存储）
```

#### 数据库变化

只保留核心表：
- `users` - 用户账户
- `refresh_tokens` - 刷新令牌

预留扩展表（注释状态）：
- `TrainingSession` - 训练会话记录
- `TrainingData` - 训练数据引用

#### 成本优化

| 平台 | 配置 | 月费用 |
|------|------|--------|
| Railway (v2.0) | PostgreSQL + 1 服务 | $10 (¥70) |
| 阿里云 (v3.0) | RDS + ECS | ¥200 |
| 阿里云学生 (v3.0) | 同上 | ¥90 |

**优势：**
- 国内访问速度快
- 学生优惠支持
- 更适合毕业设计答辩

#### 文档更新

- 📖 新增 `ALIYUN_DEPLOYMENT.md` - 阿里云完整部署指南
- 📖 更新 `README.md` - 简化项目说明
- 📖 更新 `env.example` - 阿里云配置模板
- 📖 新增 `CHANGELOG.md` - 版本更新记录

---

## [2.0.0] - 2025-10-31

### Railway 版本（已废弃）

#### 新增
- Railway 一键部署支持
- 简化的认证服务
- Nixpacks 构建配置

#### 删除
- AWS 依赖
- Workers 模块

---

## [1.0.0] - 2025-10-30

### AWS 版本（已废弃）

#### 新增
- 完整的云端架构
- AWS S3 + SQS + Lambda
- Python Workers（REINFER + ADVICE）
- Terraform 基础设施代码

---

## 迁移指南

### 从 v2.0 迁移到 v3.0

如果你之前部署在 Railway：

1. **导出数据**
   ```bash
   # 从 Railway 导出数据库
   railway run pg_dump $DATABASE_URL > backup.sql
   ```

2. **创建阿里云 RDS**
   - 参考 `ALIYUN_DEPLOYMENT.md` 创建实例

3. **导入数据**
   ```bash
   # 导入到阿里云 RDS
   psql postgresql://user:pass@rds-host:5432/db < backup.sql
   ```

4. **更新环境变量**
   - 修改 `DATABASE_URL` 为 RDS 地址
   - 保持 JWT 密钥不变（保证用户 Token 有效）

5. **部署到阿里云 ECS**
   - 按照 `ALIYUN_DEPLOYMENT.md` 步骤操作

### 从 v1.0 迁移到 v3.0

如果你之前部署在 AWS：

v1.0 架构过于复杂，建议：
1. 只迁移用户数据（`users` 和 `refresh_tokens` 表）
2. 删除其他表（Sessions/Jobs/Assets）
3. 按照 v3.0 全新部署

---

## 未来计划

### v3.1.0（计划中）
- [ ] 用户信息扩展（昵称、头像）
- [ ] 邮箱验证功能
- [ ] 密码重置功能

### v3.2.0（计划中）
- [ ] 阿里云 OSS 文件存储实现
- [ ] 用户头像上传
- [ ] 文件管理 API

### v4.0.0（未来）
- [ ] 训练数据云端存储
- [ ] 用户统计分析
- [ ] 社交功能（好友、排行榜）

---

## 技术栈版本

### 后端
- Node.js: 20+
- TypeScript: 5.3
- Fastify: 4.26
- Prisma: 5.9
- PostgreSQL: 15

### 云服务
- 阿里云 RDS PostgreSQL
- 阿里云 ECS（可选）
- 阿里云 OSS（可选）

### 开发工具
- Docker: 24+
- Docker Compose: 2.0+

---

## 贡献者

- AI Assistant - 架构设计与实现

---

## 许可证

MIT License


