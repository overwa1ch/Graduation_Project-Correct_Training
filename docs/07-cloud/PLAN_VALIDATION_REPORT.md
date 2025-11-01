# PLAN_VALIDATION_REPORT.md
**云端计划验证报告**  
**日期:** 2025-01-27  
**状态:** ✅ 无冲突，计划可行

---

## 1. 文档内部一致性检查

### ✅ 认证机制
- **CLOUD_CORE_API.md**: JWT RS256, 15min access, 30day refresh
- **APP_INTEGRATION_GUIDE.md**: JWT RS256, 15min access, 30day refresh
- **ARCHITECTURE_OVERVIEW.md**: JWT RS256, 15min access, 30day refresh
- **一致性:** ✅ 所有文档一致

### ✅ 数据库表结构
- **DATA_SCHEMAS.md**: `users`, `sessions`, `assets`, `consents`, `jobs` + `admin-users`, `admin-session` (分离)
- **ARCHITECTURE_OVERVIEW.md**: 明确说明 Admin 表与 App 用户表分离
- **一致性:** ✅ 表结构定义一致

### ✅ 状态机定义
- **CLOUD_CORE_API.md**: `local_only → uploaded → processing → ready | failed | cancelled`
- **DATA_SCHEMAS.md**: 相同状态流转定义
- **WORKER_CONTRACT.md**: Job 状态 `queued | running | succeeded | failed`
- **一致性:** ✅ 状态定义一致

### ✅ 枚举值与默认值
- **CLOUD_CORE_API.md**: `template: ["squat"]`, `engine: ["MoveNet", "MLKit", "Auto"]` (默认 MoveNet), `strictness: ["strict", "relaxed"]` (默认 strict)
- **DATA_SCHEMAS.md**: 相同的枚举定义
- **一致性:** ✅ 枚举值一致

### ✅ 超时配置
- **CLOUD_CORE_API.md**: Job SLA - REINFER 30min, ADVICE 5min
- **WORKER_CONTRACT.md**: 相同超时 + 可见性超时 (REINFER 45min, ADVICE 10min)
- **一致性:** ✅ 超时配置合理（可见性超时 > Job 超时）

### ✅ 存储配置
- **UPLOAD_POLICIES.md**: AWS S3, SSE-S3/SSE-KMS, 15分钟预签名, 30天留存
- **DATA_SCHEMAS.md**: 相同 S3 配置
- **ARCHITECTURE_OVERVIEW.md**: 相同存储配置
- **一致性:** ✅ 存储配置一致

---

## 2. 与现有实现冲突检查

### ✅ 认证边界
- **现有实现:** Admin Console 使用 Cookie Session (7天)
- **计划:** Core API 使用 JWT RS256
- **结论:** ✅ 无冲突 - 两套独立的认证系统，分离的服务和域名

### ✅ 数据模型
- **现有实现:** `admin-users`, `admin-session` 表
- **计划:** 新增 `users`, `sessions`, `assets`, `consents`, `jobs` 表
- **结论:** ✅ 无冲突 - 文档明确说明表分离，不混用

### ✅ API 路由
- **现有实现:** Next.js Server Actions（无 REST API）
- **计划:** Core API `/v1/*` REST 端点（独立服务）
- **结论:** ✅ 无冲突 - Core API 是新服务，不影响现有 Admin Console

### ✅ 技术栈
- **现有实现:** Next.js 15, Drizzle ORM, PostgreSQL (Supabase)
- **计划:** Core API 可以是任何框架（Node.js/Express, Python/FastAPI, Go, etc.）
- **结论:** ✅ 无冲突 - 独立服务，技术栈灵活

---

## 3. 技术可行性检查

### ✅ JWT RS256 认证
**技术可行性:** ✅ 高

**原因:**
- RS256 是成熟标准（RFC 7518）
- 广泛支持：Node.js (jsonwebtoken), Python (PyJWT), Go (jwt-go)
- 公钥/私钥分离，支持多服务验证
- 15分钟 access token + 30天 refresh token 是常见配置

**实现复杂度:** 中等
- 需要生成 RSA 密钥对（2048bit+）
- 实现 refresh token 黑名单（DB 或 Redis）
- 需要密钥轮换机制（生产环境）

### ✅ AWS S3 对象存储
**技术可行性:** ✅ 高

**原因:**
- AWS S3 是成熟服务
- SDK 支持多语言（AWS SDK for JavaScript/Python/Go）
- 预签名 URL 是标准功能
- SSE-S3/SSE-KMS 是原生支持

**实现复杂度:** 低-中等
- 配置 IAM 角色和权限
- 实现预签名 URL 生成（15分钟有效期）
- 实现单次使用验证（需要额外逻辑）
- 配置生命周期策略（30天自动删除）

**成本估算:** 
- 存储: ~$0.023/GB/月
- 请求: PUT $0.005/1000, GET $0.0004/1000
- 数据传输: 出站流量收费（通常免费入站）

**替代方案:** 
- Supabase Storage (兼容 S3 API)
- MinIO (自托管)
- 云文档已考虑兼容性

### ✅ AWS SQS 队列
**技术可行性:** ✅ 高

**原因:**
- AWS SQS 是成熟的托管队列服务
- SDK 支持完善
- 支持 Dead-Letter Queue
- 可见性超时可配置

**实现复杂度:** 中等
- 配置队列（REINFER, ADVICE, DLQ）
- 实现消息发送和接收
- 实现指数退避重试（最多3次）
- Worker 长轮询或事件驱动接收

**成本估算:**
- 请求: $0.40/百万请求（Standard Queue）
- 数据传输: 免费（同区域）
- 长期运行：成本可控

**替代方案:**
- Redis Streams (自托管)
- RabbitMQ (自托管)
- Google Cloud Pub/Sub

### ✅ PostgreSQL 数据库
**技术可行性:** ✅ 高

**原因:**
- Supabase 已在使用（现有基础设施）
- 表结构简单，无复杂关系
- Drizzle ORM 已集成
- 软删除、外键级联是标准功能

**实现复杂度:** 低-中等
- 创建新表迁移（users, sessions, assets, consents, jobs）
- 实现软删除逻辑（deleted_at）
- 实现索引优化
- 外键级联删除验证逻辑

**成本估算:**
- Supabase Free Tier: 500MB 数据库, 1GB 带宽
- Pro: $25/月起（8GB 数据库）

### ✅ Worker 服务
**技术可行性:** ✅ 中等-高

**原因:**
- REINFER Worker: 需要加载 ML 模型（TensorFlow/PyTorch）
- ADVICE Worker: 需要 AI 模型（LLM/规则引擎）
- 容器化部署（Docker）是标准做法

**实现复杂度:** 高
- 模型加载和推理（内存/GPU 需求）
- 超时处理（REINFER 30min, ADVICE 5min）
- 错误处理和重试
- 可观测性（日志、指标）

**资源需求:**
- REINFER: CPU/GPU（取决于模型大小）
- ADVICE: CPU/GPU（取决于 AI 模型）
- 容器资源：2-8GB RAM（取决于模型）

**部署选项:**
- AWS Lambda（有超时限制，不适合 REINFER 30min）
- AWS ECS/Fargate（推荐）
- AWS EC2（自管理）
- Kubernetes（如果需要大规模）

---

## 4. 资源依赖可行性

### ✅ 依赖服务
- **PostgreSQL (Supabase):** ✅ 已在使用，可直接扩展
- **AWS S3:** ✅ 需要新账户配置（如果使用 AWS）
- **AWS SQS:** ✅ 需要新账户配置（如果使用 AWS）
- **Worker 计算资源:** ⚠️ 需要评估（模型大小、GPU 需求）

### ✅ 开发工具链
- **JWT 库:** ✅ 广泛支持（jsonwebtoken, PyJWT, etc.）
- **S3 SDK:** ✅ AWS SDK 支持完善
- **SQS SDK:** ✅ AWS SDK 支持完善
- **ORM:** ✅ Drizzle ORM 已在使用

### ⚠️ 潜在风险点

1. **Worker 模型依赖**
   - 需要明确：REINFER 使用哪个模型？模型大小？推理时间？
   - 需要明确：ADVICE 使用哪个 AI 模型（LLM/规则）？
   - **建议:** 在实现前先做 POC，评估资源需求

2. **单次使用预签名 URL**
   - AWS S3 预签名 URL 默认不是单次使用
   - 需要额外逻辑验证（记录已使用的 URL，或使用 Lambda@Edge）
   - **建议:** 使用数据库记录已使用的 URL，或接受非严格单次使用（15分钟过期已足够）

3. **可见性超时 vs Job 超时**
   - SQS 最长可见性超时是 12 小时（满足 45 分钟需求）
   - **建议:** ✅ 配置合理

4. **跨服务通信**
   - Core API ↔ SQS: ✅ 标准 SDK
   - Worker ↔ S3: ✅ 标准 SDK
   - Worker ↔ PostgreSQL: ✅ 标准连接
   - **建议:** ✅ 无阻塞问题

---

## 5. 实施优先级建议

### P0 (核心功能)
1. ✅ **Core API 基础框架**
   - JWT RS256 认证（register/login/refresh）
   - Session 管理（创建、查询）
   - 预签名 URL 生成

2. ✅ **数据库迁移**
   - 创建 users, sessions, assets, consents, jobs 表
   - 实现软删除逻辑

3. ✅ **S3 集成**
   - 预签名 URL 生成（15分钟）
   - 文件上传验证（SHA256, size）

### P1 (核心工作流)
4. ✅ **Job 触发**
   - POST /v1/sessions/{id}/jobs/reinfer
   - POST /v1/sessions/{id}/jobs/advice
   - SQS 消息发送

5. ✅ **Worker 基础框架**
   - SQS 消息接收
   - S3 文件下载/上传
   - 数据库更新

### P2 (完整功能)
6. ⚠️ **REINFER Worker**
   - **依赖:** ML 模型选择和集成
   - 模型推理
   - 结果格式化

7. ⚠️ **ADVICE Worker**
   - **依赖:** AI 模型选择（LLM/规则）
   - 建议生成逻辑
   - 结果格式化

### P3 (优化)
8. ✅ **错误处理和重试**
9. ✅ **可观测性（日志、指标）**
10. ✅ **Webhook 支持（可选）**

---

## 6. 总结

### ✅ 冲突检查结果
- **文档内部一致性:** ✅ 完全一致
- **与现有实现冲突:** ✅ 无冲突（独立服务，分离表结构）
- **技术可行性:** ✅ 高（所有技术都是成熟方案）
- **资源依赖:** ✅ 可行（Supabase 已在使用，AWS 服务成熟）

### ⚠️ 需要明确的点
1. **Worker 模型选择**
   - REINFER 使用哪个 ML 模型？
   - ADVICE 使用哪个 AI 模型？
   - 模型大小和资源需求？

2. **单次使用预签名 URL**
   - 是否需要严格单次使用？
   - 如果不需要，15分钟过期已足够

3. **部署环境**
   - AWS 账户是否已准备？
   - Worker 部署到 AWS ECS/Fargate 还是自托管？

### ✅ 可行性结论
**计划完全可行，建议开始实施。**

**推荐实施路径:**
1. Phase 1: Core API + 数据库迁移 + S3 基础集成
2. Phase 2: Job 触发 + SQS + Worker 基础框架
3. Phase 3: REINFER/ADVICE Worker（需要模型选择）
4. Phase 4: 优化和监控

---

**End of PLAN_VALIDATION_REPORT.md**

