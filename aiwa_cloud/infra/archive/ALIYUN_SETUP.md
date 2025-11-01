# 阿里云手动部署指南

本指南提供在阿里云上手动设置资源的详细步骤说明。

## 前置条件

- 阿里云账号及相应权限
- 阿里云CLI已安装并配置（可选）
- 对阿里云服务的基本了解

## 目录

1. [OSS Bucket设置](#1-oss-bucket设置)
2. [MNS队列设置](#2-mns队列设置)
3. [RDS PostgreSQL设置](#3-rds-postgresql设置)
4. [RAM角色和策略配置](#4-ram角色和策略配置)
5. [ACK容器服务配置](#5-ack容器服务配置)
6. [环境变量配置](#6-环境变量配置)

---

## 1. OSS Bucket设置

### 创建OSS Bucket

1. 登录阿里云控制台 → 对象存储OSS
2. 点击"创建Bucket"
3. **Bucket名称**：`aiwa-cloud-storage-{env}`（例如：`aiwa-cloud-storage-prod`）
4. **地域**：选择合适的地域（推荐：华东1-杭州 `oss-cn-hangzhou`）
5. **存储类型**：标准存储
6. **读写权限**：私有（默认）
7. **服务器端加密**：开启，使用OSS完全托管（SSE-OSS）
8. 点击"确定"

### 配置生命周期规则

1. 进入Bucket → 基础设置 → 生命周期
2. 点击"创建规则"
3. **规则名称**：`delete-old-sessions`
4. **应用范围**：整个Bucket
5. **生命周期规则**：
   - ✅ 过期删除
   - 天数：**30天**（对象创建30天后删除）
6. 点击"确定"

### 配置跨域（CORS）

1. 进入Bucket → 权限管理 → 跨域设置
2. 点击"创建规则"
3. 配置如下：
   - **来源**：`*`（或指定域名）
   - **允许Methods**：`GET, PUT, POST, HEAD`
   - **允许Headers**：`*`
   - **暴露Headers**：`ETag`
   - **缓存时间**：`3000`秒
4. 点击"确定"

### 获取访问域名

在Bucket概览页，记录以下信息：
- **Endpoint**：`oss-cn-hangzhou.aliyuncs.com`
- **Bucket域名**：`{bucket-name}.oss-cn-hangzhou.aliyuncs.com`

---

## 2. MNS队列设置

### 开通MNS服务

1. 登录阿里云控制台 → 消息服务MNS
2. 如果未开通，按照提示开通服务
3. 记录**Account ID**（在账户信息中查看）

### 创建REINFER队列

1. 进入MNS控制台 → 队列服务
2. 选择地域（与OSS相同）
3. 点击"创建队列"
4. **队列名称**：`aiwa-reinfer-queue-{env}`
5. **可见性超时**：**2700秒**（45分钟，必须大于REINFER处理超时30分钟）
6. **消息最大长度**：**262144字节**（256 KB）
7. **消息保留周期**：**1209600秒**（14天）
8. **长轮询等待时间**：**20秒**
9. **最大接收次数**：**3**（超过3次后进入死信队列）
10. 点击"确定"

### 创建ADVICE队列

1. 重复上述步骤，创建：
   - **队列名称**：`aiwa-advice-queue-{env}`
   - **可见性超时**：**600秒**（10分钟，必须大于ADVICE处理超时5分钟）

### 创建死信队列

1. 创建 `aiwa-reinfer-dlq-{env}`（标准队列，默认设置）
2. 创建 `aiwa-advice-dlq-{env}`（标准队列，默认设置）
3. 将主队列的死信队列设置为对应的DLQ

### 记录队列信息

- **队列名称**：`aiwa-reinfer-queue-{env}`（不是URL）
- **Account ID**：用于构建MNS endpoint

---

## 3. RDS PostgreSQL设置

### 创建RDS实例

1. 登录阿里云控制台 → 云数据库RDS PostgreSQL版
2. 点击"创建实例"
3. **计费方式**：按量付费（或包年包月）
4. **地域**：选择与OSS相同的地域
5. **数据库类型**：PostgreSQL
6. **版本**：PostgreSQL 15
7. **系列**：基础版（开发）或高可用版（生产）
8. **存储类型**：SSD云盘
9. **实例规格**：
   - 开发环境：`pg.n2.small.1`（1核2GB）
   - 生产环境：`pg.n2.medium.1`（2核4GB）
10. **存储空间**：20GB（可自动扩容）
11. **网络类型**：专有网络VPC
12. **可用区**：单可用区（或多可用区高可用）
13. 点击"下一步"

### 配置实例

1. **实例名称**：`aiwa-cloud-db-{env}`
2. **数据库名称**：`aiwa_cloud`
3. **用户名**：`aiwa_admin`
4. **密码**：设置强密码（记录保存）
5. **字符集**：UTF8
6. 点击"确认订单"并支付

### 配置白名单

1. 进入实例 → 数据安全性 → 白名单设置
2. 添加白名单：
   - 允许ACK容器服务的VPC网段
   - 或添加0.0.0.0/0（测试用，生产环境限制IP）

### 配置安全组

1. 进入ECS控制台 → 安全组
2. 找到RDS关联的安全组，编辑入站规则：
   - 类型：PostgreSQL
   - 协议：TCP
   - 端口：5432
   - 来源：ACK集群安全组

### 获取连接信息

在实例概览页记录：
- **内网地址**：`rm-xxxxxxxxx.pg.rds.aliyuncs.com`
- **端口**：`5432`
- **数据库名**：`aiwa_cloud`
- **用户名**：`aiwa_admin`

连接字符串格式：
```
postgresql://aiwa_admin:{password}@rm-xxxxxxxxx.pg.rds.aliyuncs.com:5432/aiwa_cloud
```

---

## 4. RAM角色和策略配置

### 创建RAM用户（用于API访问）

1. 登录RAM控制台 → 身份管理 → 用户
2. 点击"创建用户"
3. **用户名**：`aiwa-cloud-service-user`
4. **访问方式**：编程访问（获取AccessKey）
5. 点击"确定"
6. **保存AccessKey ID和Secret**（只显示一次）

### 创建自定义策略

1. RAM控制台 → 权限管理 → 策略
2. 点击"创建策略" → 脚本配置
3. **策略名称**：`AIWACloudServicePolicy`
4. **策略内容**：

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "oss:GetObject",
        "oss:PutObject",
        "oss:DeleteObject",
        "oss:ListObjects",
        "oss:GetObjectMeta"
      ],
      "Resource": [
        "acs:oss:*:*:aiwa-cloud-storage-*",
        "acs:oss:*:*:aiwa-cloud-storage-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "mns:SendMessage",
        "mns:ReceiveMessage",
        "mns:DeleteMessage",
        "mns:PeekMessage",
        "mns:GetQueueAttributes"
      ],
      "Resource": [
        "acs:mns:*:*:queues/aiwa-*-queue-*"
      ]
    }
  ]
}
```

5. 点击"确定"

### 授权用户

1. 进入用户详情 → 添加权限
2. 选择自定义策略：`AIWACloudServicePolicy`
3. 点击"确定"

---

## 5. ACK容器服务配置

### 创建ACK集群

1. 登录容器服务控制台 → Kubernetes集群
2. 点击"创建集群"
3. **集群类型**：托管版Kubernetes
4. **地域**：与OSS/RDS相同
5. **集群名称**：`aiwa-cloud-cluster-{env}`
6. **Kubernetes版本**：最新稳定版
7. **专有网络VPC**：选择或创建新VPC
8. **节点配置**：
   - **Worker节点**：
     - Core API：`ecs.t6.large`（2核4GB，2节点）
     - REINFER Worker：`ecs.gn6i-c4g1.xlarge`（4核GPU，1节点）
     - ADVICE Worker：`ecs.t6.medium`（2核2GB，1节点）
9. **容器网络**：Flannel（或Terway）
10. 点击"创建"（约10-15分钟）

### 配置命名空间

```bash
kubectl create namespace aiwa-cloud
```

### 创建Secret（存储敏感信息）

```bash
# 数据库连接
kubectl create secret generic aiwa-db-secret \
  --from-literal=url='postgresql://aiwa_admin:password@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud' \
  -n aiwa-cloud

# 阿里云AccessKey
kubectl create secret generic aiwa-aliyun-secret \
  --from-literal=access-key-id='your_access_key_id' \
  --from-literal=secret-access-key='your_secret_key' \
  -n aiwa-cloud
```

### 创建ConfigMap（存储配置）

```bash
kubectl create configmap aiwa-config \
  --from-literal=aliyun-region='oss-cn-hangzhou' \
  --from-literal=oss-bucket='aiwa-cloud-storage-prod' \
  --from-literal=mns-account-id='your_account_id' \
  --from-literal=mns-reinfer-queue='aiwa-reinfer-queue-prod' \
  --from-literal=mns-advice-queue='aiwa-advice-queue-prod' \
  -n aiwa-cloud
```

### 创建部署配置（Deployment）

#### Core API Deployment

创建文件 `core-api-deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aiwa-core-api
  namespace: aiwa-cloud
spec:
  replicas: 2
  selector:
    matchLabels:
      app: aiwa-core-api
  template:
    metadata:
      labels:
        app: aiwa-core-api
    spec:
      containers:
      - name: core-api
        image: registry.cn-hangzhou.aliyuncs.com/{namespace}/aiwa-core-api:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: aiwa-db-secret
              key: url
        - name: ALIYUN_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aiwa-aliyun-secret
              key: access-key-id
        - name: ALIYUN_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aiwa-aliyun-secret
              key: secret-access-key
        - name: ALIYUN_REGION
          valueFrom:
            configMapKeyRef:
              name: aiwa-config
              key: aliyun-region
        - name: ALIYUN_OSS_BUCKET
          valueFrom:
            configMapKeyRef:
              name: aiwa-config
              key: oss-bucket
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
```

应用配置：
```bash
kubectl apply -f core-api-deployment.yaml
```

#### REINFER Worker Deployment

创建文件 `reinfer-worker-deployment.yaml`（需要GPU节点）：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aiwa-reinfer-worker
  namespace: aiwa-cloud
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aiwa-reinfer-worker
  template:
    metadata:
      labels:
        app: aiwa-reinfer-worker
    spec:
      nodeSelector:
        accelerator: nvidia-tesla-t4  # 或对应的GPU节点标签
      containers:
      - name: reinfer-worker
        image: registry.cn-hangzhou.aliyuncs.com/{namespace}/aiwa-reinfer-worker:latest
        env:
        - name: WORKER_TYPE
          value: "reinfer"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: aiwa-db-secret
              key: url
        # ... 其他环境变量同Core API
        resources:
          requests:
            cpu: 2
            memory: 4Gi
            nvidia.com/gpu: 1
          limits:
            cpu: 4
            memory: 8Gi
            nvidia.com/gpu: 1
```

#### ADVICE Worker Deployment

创建文件 `advice-worker-deployment.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aiwa-advice-worker
  namespace: aiwa-cloud
spec:
  replicas: 2
  selector:
    matchLabels:
      app: aiwa-advice-worker
  template:
    metadata:
      labels:
        app: aiwa-advice-worker
    spec:
      containers:
      - name: advice-worker
        image: registry.cn-hangzhou.aliyuncs.com/{namespace}/aiwa-advice-worker:latest
        env:
        - name: WORKER_TYPE
          value: "advice"
        # ... 其他环境变量
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
```

### 创建服务（Service）和Ingress

#### Core API Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: aiwa-core-api-service
  namespace: aiwa-cloud
spec:
  selector:
    app: aiwa-core-api
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer  # 或ClusterIP + Ingress
```

---

## 6. 环境变量配置

### Core API环境变量

在ACK部署中通过Secret和ConfigMap配置，或手动设置：

```bash
# 数据库
DATABASE_URL=postgresql://aiwa_admin:{password}@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud

# JWT
JWT_ACCESS_SECRET={generate-random-string}
JWT_REFRESH_SECRET={generate-random-string}

# 阿里云OSS
ALIYUN_REGION=oss-cn-hangzhou
ALIYUN_ACCESS_KEY_ID={from-ram-user}
ALIYUN_SECRET_ACCESS_KEY={from-ram-user}
ALIYUN_OSS_BUCKET=aiwa-cloud-storage-prod

# 阿里云MNS
ALIYUN_MNS_ACCOUNT_ID={your_account_id}
ALIYUN_MNS_REINFER_QUEUE_NAME=aiwa-reinfer-queue-prod
ALIYUN_MNS_ADVICE_QUEUE_NAME=aiwa-advice-queue-prod

# 服务器
PORT=3000
NODE_ENV=production
```

### Worker环境变量

```bash
# 数据库（同Core API）
DATABASE_URL=postgresql://aiwa_admin:{password}@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud

# 阿里云配置（同Core API）
ALIYUN_REGION=oss-cn-hangzhou
ALIYUN_ACCESS_KEY_ID={from-ram-user}
ALIYUN_SECRET_ACCESS_KEY={from-ram-user}
ALIYUN_OSS_BUCKET=aiwa-cloud-storage-prod
ALIYUN_MNS_ACCOUNT_ID={your_account_id}
ALIYUN_MNS_REINFER_QUEUE_NAME=aiwa-reinfer-queue-prod
ALIYUN_MNS_ADVICE_QUEUE_NAME=aiwa-advice-queue-prod

# 模型配置（REINFER Worker）
RTMPOSE_MODEL_PATH=/models/rtmpose-m-384x288.onnx

# Worker配置
WORKER_TYPE=reinfer  # 或 advice
LOG_LEVEL=INFO
```

---

## 验证清单

- [ ] OSS Bucket创建并配置生命周期规则
- [ ] MNS队列创建（REINFER、ADVICE、DLQs）
- [ ] RDS PostgreSQL实例运行并可访问
- [ ] RAM用户和策略配置
- [ ] ACK集群创建
- [ ] 所有Deployment运行正常
- [ ] 环境变量配置完成
- [ ] 数据库迁移执行：`npx prisma migrate deploy`
- [ ] Core API健康检查返回200：`curl http://{service-ip}/health`

---

## 下一步

1. 构建并推送Docker镜像到ACR
2. 部署服务到ACK
3. 运行集成测试
4. 配置监控告警

## 故障排查

### 常见问题

1. **容器无法启动**：检查Secret和ConfigMap配置
2. **数据库连接失败**：验证安全组白名单和VPC网络
3. **OSS访问被拒绝**：检查RAM用户权限策略
4. **MNS消息无法接收**：验证Account ID和队列名称

### 有用的命令

```bash
# 查看Pod日志
kubectl logs -n aiwa-cloud deployment/aiwa-core-api

# 检查MNS队列深度（需要MNS CLI或API）
# 在阿里云控制台查看队列属性

# 测试数据库连接
psql postgresql://aiwa_admin:{password}@rm-xxx.pg.rds.aliyuncs.com:5432/aiwa_cloud

# 检查OSS Bucket
ossutil ls oss://aiwa-cloud-storage-prod/
```

---

## 成本估算

### 按1000次会话/月计算：

- ACK集群（按节点计费）：
  - Core API节点：~¥50/月（2节点 × ecs.t6.large）
  - REINFER Worker（GPU）：~¥200/月（1节点 × gn6i-c4g1.xlarge）
  - ADVICE Worker：~¥30/月（1节点 × ecs.t6.medium）
- OSS存储（30天保留）：~¥0.12/GB/月
- MNS消息：~¥0.002/千次请求
- RDS PostgreSQL：~¥150/月（基础版）
- **总计**：约¥430-500/月

**每会话成本**：约¥0.43-0.50

---

## 注意事项

1. **地域选择**：确保OSS、MNS、RDS在同一地域，降低延迟和成本
2. **网络访问**：生产环境建议使用内网访问（VPC内）
3. **数据备份**：配置RDS自动备份（建议7天保留）
4. **安全合规**：使用RAM子账号，遵循最小权限原则
5. **容灾方案**：生产环境建议多可用区部署

