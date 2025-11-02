# 认证功能集成指南

本指南说明如何使用已集成的用户认证功能。

---

## 📁 新增文件

### 配置
- `lib/config/api_config.dart` - API 配置（Base URL 等）

### 服务层
- `lib/services/api_client.dart` - HTTP 客户端封装
- `lib/services/auth_service.dart` - 认证服务（注册/登录/Token 管理）
- `lib/services/auth_state.dart` - 认证状态管理（ChangeNotifier）

### UI 层
- `lib/ui/pages/login_page.dart` - 登录页面
- `lib/ui/pages/register_page.dart` - 注册页面

### 修改的文件
- `lib/main.dart` - 添加认证守卫和路由
- `lib/ui/pages/settings_page.dart` - 添加登出功能和用户信息显示
- `pubspec.yaml` - 添加 http 和 shared_preferences 依赖

---

## 🔧 配置

### API 地址配置

编辑 `lib/config/api_config.dart`：

```dart
// 本地开发
static const String baseUrl = 'http://localhost:8080';

// Android 模拟器
// static const String baseUrl = 'http://10.0.2.2:8080';

// iOS 模拟器
// static const String baseUrl = 'http://localhost:8080';

// 真机（替换为你的电脑 IP）
// static const String baseUrl = 'http://192.168.1.100:8080';
```

获取电脑 IP：
- Windows: `ipconfig | findstr IPv4`
- Mac/Linux: `ifconfig | grep inet`

---

## 🚀 使用流程

### 1. 启动后端 API

确保后端 API 正在运行：

```powershell
cd aiwa_cloud\core-api
npm run dev
```

应该看到：
```
🚀 AIWA Auth API listening on port 8080
```

### 2. 运行 Flutter 应用

```bash
cd aiwa_app
flutter run
```

### 3. 测试认证流程

#### 注册新用户
1. 应用启动后会显示登录页面
2. 点击 "Create New Account" 按钮
3. 输入邮箱和密码（至少 8 位）
4. 点击 "Create Account"
5. 注册成功后自动登录并跳转到应用主页

#### 登录
1. 在登录页面输入已注册的邮箱和密码
2. 点击 "Sign In"
3. 登录成功后跳转到应用主页

#### 登出
1. 进入 Settings 页面
2. 滚动到底部，点击 "Sign Out" 按钮
3. 确认登出
4. 返回登录页面

---

## 📱 UI 特性

### 登录页面
- ✅ 邮箱和密码输入框
- ✅ 表单验证（邮箱格式、密码长度）
- ✅ 密码可见性切换
- ✅ 加载状态指示器
- ✅ 错误提示（SnackBar）
- ✅ 跳转注册页面

### 注册页面
- ✅ 邮箱、密码、确认密码输入框
- ✅ 表单验证（邮箱格式、密码长度、密码匹配）
- ✅ 密码可见性切换
- ✅ 加载状态指示器
- ✅ 错误提示（SnackBar）
- ✅ 返回登录页面

### 设置页面
- ✅ 显示当前用户邮箱
- ✅ 登出按钮（带确认对话框）

---

## 🔒 安全特性

1. **密码加密**
   - 后端使用 Bcrypt 加密
   - 密码不以明文存储

2. **Token 管理**
   - Access Token（15 分钟）
   - Refresh Token（30 天）
   - Token 存储在 SharedPreferences

3. **路由守卫**
   - 未登录用户自动跳转到登录页
   - 已登录用户直接进入应用

4. **数据验证**
   - 邮箱格式验证
   - 密码长度验证（至少 8 位）
   - 前后端双重验证

---

## 🐛 常见问题

### 1. 网络错误：无法连接到服务器

**原因：** API 服务器未运行或地址配置错误

**解决：**
1. 检查后端 API 是否正在运行
2. 检查 `api_config.dart` 中的 `baseUrl` 配置
3. 如果使用模拟器，确保使用正确的 IP 地址

### 2. Android 模拟器无法连接 localhost

**解决：** 将 `baseUrl` 改为 `http://10.0.2.2:8080`

### 3. 真机无法连接

**解决：**
1. 确保手机和电脑在同一局域网
2. 获取电脑 IP 地址
3. 将 `baseUrl` 改为 `http://<电脑IP>:8080`

### 4. 登录后无法保持状态

**原因：** Token 未正确保存

**解决：**
1. 检查控制台日志
2. 确保 SharedPreferences 正常工作
3. 清除应用数据重试

---

## 🧪 测试建议

### 正常场景
- ✅ 注册新用户
- ✅ 登录已有用户
- ✅ 登出
- ✅ 关闭应用后重新打开（应保持登录状态）

### 错误场景
- ✅ 注册重复邮箱（应显示错误）
- ✅ 登录错误密码（应显示错误）
- ✅ 输入无效邮箱（应显示错误）
- ✅ 密码太短（应显示错误）
- ✅ 密码不匹配（注册时，应显示错误）

### 网络场景
- ✅ 断网情况（应显示网络错误）
- ✅ 后端未运行（应显示连接错误）

---

## 📊 数据流

```
用户输入
  ↓
表单验证（前端）
  ↓
AuthState.register/login()
  ↓
AuthService（调用后端 API）
  ↓
API 客户端（HTTP 请求）
  ↓
后端 API（认证处理）
  ↓
返回 Token
  ↓
保存到 SharedPreferences
  ↓
更新 AuthState
  ↓
导航到主页
```

---

## 🎯 后续扩展建议

### 短期
- [ ] 添加"记住我"功能
- [ ] 添加密码强度指示器
- [ ] 添加忘记密码功能（需要后端支持）

### 中期
- [ ] 添加邮箱验证（需要后端支持）
- [ ] 添加第三方登录（Google、Facebook 等）
- [ ] 添加用户资料编辑功能

### 长期
- [ ] 添加生物识别登录（指纹、Face ID）
- [ ] 添加多设备管理
- [ ] 添加登录历史记录

---

## 📞 技术支持

如果遇到问题：
1. 查看控制台日志（前端和后端）
2. 使用 Postman 测试 API 端点
3. 检查网络连接
4. 查看本指南的常见问题部分

---

**完成日期：** 2025-11-02
**版本：** 1.0.0

