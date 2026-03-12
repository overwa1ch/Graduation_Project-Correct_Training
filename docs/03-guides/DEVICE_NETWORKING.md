# AIWA 真机联网开发指南

本文档说明如何让 Flutter 应用在真机上连接本地后端（core-api），以及管理后台的启动方式。

---

## 一、架构概览

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Flutter 真机   │────▶│  core-api :3002   │────▶│  SQLite 数据库   │
│  (aiwa_app)     │     │  (认证/用户 API)   │     │  (users 等)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                         │
        │                         │
        │                 ┌───────┴───────┐
        │                 │  my-app :3003   │
        │                 │  (管理后台)     │
        └────────────────▶│  调用 core-api  │
                          └───────────────┘
```

- **core-api**：认证 API，端口 3002
- **my-app**：管理后台（Next.js），端口 3003，通过 HTTP 调用 core-api
- **aiwa_app**：Flutter 移动端，需能访问 core-api

---

## 二、真机连接方式

### 方式 A：USB 调试 + adb reverse（推荐）

**适用**：真机通过 USB 连接电脑，开发调试时使用。

**步骤**：

1. 手机开启 USB 调试，用数据线连接电脑
2. 执行端口转发：
   ```bash
   adb reverse tcp:3002 tcp:3002
   ```
3. 确保 `aiwa_app/lib/config/api_config.dart` 中：
   ```dart
   static const String baseUrl = 'http://127.0.0.1:3002';
   ```
4. 运行 Flutter 应用：
   ```bash
   cd aiwa_app && flutter run -d <设备ID>
   ```

**原理**：手机访问 `127.0.0.1:3002` 时，通过 adb 转发到电脑的 3002 端口，不依赖 WiFi。

**注意**：每次重新插拔 USB 后需重新执行 `adb reverse`。可使用脚本：
```bash
# Windows PowerShell
.\aiwa_app\scripts\adb-reverse.ps1
```

---

### 方式 B：WiFi 局域网

**适用**：真机与电脑在同一 WiFi，或需要脱离 USB 测试。

**步骤**：

1. 获取电脑局域网 IP（如 `192.168.2.90`）：
   ```bash
   # Windows
   ipconfig | findstr IPv4

   # Mac/Linux
   ifconfig | grep inet
   ```
2. 修改 `aiwa_app/lib/config/api_config.dart`：
   ```dart
   static const String baseUrl = 'http://192.168.2.90:3002';
   ```
3. 确保 core-api 监听所有网卡（`aiwa_cloud/core-api/src/main.ts`）：
   ```ts
   await fastify.listen({ port: CONFIG.port, host: '0.0.0.0' });
   ```
4. 添加 Windows 防火墙规则（管理员 PowerShell）：
   ```powershell
   netsh advfirewall firewall add rule name="AIWA core-api 3002" dir=in action=allow protocol=TCP localport=3002
   ```
5. 确保手机和电脑在同一 WiFi 下

---

## 三、Android 明文 HTTP 配置

真机访问 `http://` 需允许明文流量，在 `aiwa_app/android/app/src/main/AndroidManifest.xml` 中：

```xml
<application
    ...
    android:usesCleartextTraffic="true">
```

---

## 四、超时与错误处理

- **请求超时**：`api_config.dart` 中 `timeoutSeconds` 默认 60 秒，弱网环境可适当增大
- **"Network error"**：多为连接失败，检查 baseUrl、core-api 是否启动、防火墙
- **"Request timeout"**：请求发出但未在规定时间内收到响应，可排查网络或服务端性能

---

## 五、启动顺序（完整开发环境）

**重要**：必须先启动 core-api，再启动 my-app，避免端口冲突。

1. **启动 core-api**（端口 3002）：
   ```bash
   cd aiwa_cloud/core-api && pnpm dev
   ```

2. **（可选）启动管理后台**（端口 3003）：
   ```bash
   cd aiwa_cloud/my-app && pnpm dev
   ```
   访问：http://localhost:3003

3. **真机 USB 连接时建立转发**：
   ```bash
   adb reverse tcp:3002 tcp:3002
   ```

4. **运行 Flutter 应用**：
   ```bash
   cd aiwa_app && flutter run -d <设备ID>
   ```

---

## 六、端口与配置对照

| 服务     | 默认端口 | 配置位置                          |
|----------|----------|-----------------------------------|
| core-api | 3002     | `aiwa_cloud/core-api/.env` 的 PORT |
| my-app   | 3003     | `aiwa_cloud/my-app/.env.local` 的 PORT |
| Flutter  | -        | `aiwa_app/lib/config/api_config.dart` 的 baseUrl |

**注意**：`my-app` 的 `API_BASE_URL` 需与 core-api 端口一致（如 `http://localhost:3002`）。

---

## 七、常见问题

### 1. 注册/登录提示「没有网络」或「Network error」

- 检查 baseUrl 是否正确
- 真机 USB：确认已执行 `adb reverse tcp:3002 tcp:3002`
- 真机 WiFi：确认 IP、防火墙、core-api 监听 `0.0.0.0`

### 2. 请求超时（Request timeout）

- 增加 `timeoutSeconds`
- WiFi 方式：检查防火墙是否放行 3002 端口
- 优先尝试 USB + adb reverse

### 3. Internal Server Error（500）

- 检查 core-api 日志
- 确认数据库已初始化：`cd aiwa_cloud/core-api && pnpm prisma db push`
- 确认 `.env` 中 `DATABASE_URL` 正确（SQLite 示例：`file:./dev.db`）

### 4. 管理后台无法连接 core-api（API error: 404）

- **端口冲突**：若 my-app 与 core-api 同时占用 3002，my-app 的请求会打到自身并返回 404。解决：先启动 core-api（3002），再启动 my-app（3003）。my-app 已配置 `-p 3003`。
- 确认 core-api 已启动：访问 http://localhost:3002/health 应返回 `{"status":"ok"}`
- 检查 `my-app/.env.local` 中 `API_BASE_URL=http://localhost:3002` 与 `ADMIN_API_KEY` 与 core-api 的 `.env` 一致
