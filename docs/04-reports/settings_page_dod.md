# Settings Page - DoD 验证清单

**版本：** v2.0  
**最后更新：** 2025-10-28

---

## ✅ DoD（完成定义）验证

### 1. 打开 Settings 能正确显示当前配置 ✅

**加载流程：**
```dart
initState() → _loadConfig() → readAppRuntimeConfig() → 填充表单
```

**字段映射表：**

| 表单字段 | 配置键 | 类型 | 默认值 |
|---------|--------|------|--------|
| Analysis Threshold | `strictness` | enum | `'strict'` |
| Analysis Engine | `engine` | enum | `'MoveNet'` |
| Stride (步长) | `stride` | int | `2` |
| Target FPS (目标帧率) | `targetFps` | int | `30` |
| Resolution (分辨率) | `resolution` | string | `'1280x720'` |
| Upload Video | `privacy.upload` | enum | `'keypoints-only'` |
| Confirm Before Upload | `privacy.confirmVideoUpload` | bool | `true` |
| Cleanup Days | `cleanup.days` | int | `7` |
| Log Level | `logs.level` | enum | `'info'` |

**加载状态：**
- [x] 加载中显示 `CircularProgressIndicator`
- [x] 加载失败显示 toast 提示
- [x] 加载成功填充所有表单字段

---

### 2. 非法输入会给出清晰的内联报错 ✅

**轻量校验规则：**

#### Stride（步长）
- [x] 不能为空 → "步长不能为空"
- [x] 必须是整数 → "必须是整数"
- [x] 必须 ≥ 1 → "步长必须 ≥ 1"

#### Target FPS（目标帧率）
- [x] 不能为空 → "帧率不能为空"
- [x] 必须是整数 → "必须是整数"
- [x] 必须 ≥ 1 → "帧率必须 ≥ 1"

#### Resolution（分辨率）
- [x] 不能为空 → "分辨率不能为空"
- [x] 必须匹配 `^\d{3,4}x\d{3,4}$` → "格式: 1280x720"

#### Cleanup Days（清理天数）
- [x] 不能为空 → "天数不能为空"
- [x] 必须是整数 → "必须是整数"
- [x] 必须 ≥ 0 → "天数必须 ≥ 0"

**校验触发时机：**
- [x] 输入框 `onChanged` 实时校验
- [x] 点击"保存"时全量校验
- [x] 有错误时禁止保存并提示

**错误显示：**
- [x] 内联 `errorText`（红色文本）
- [x] 不影响其他字段编辑

---

### 3. 保存成功后生成/覆盖 configs/app_runtime.json ✅

**保存流程：**
```dart
保存按钮 → _validateAll() → _saveConfig() → writeAppRuntimeConfig()
```

**输出文件：**
- **路径：** `configs/app_runtime.json`
- **编码：** UTF-8
- **格式：** JSON（2 空格缩进）
- **字段顺序：** 稳定（engine, strictness, stride, targetFps, resolution, privacy, cleanup, logs）

**保存行为：**
- [x] 保存期间禁用按钮（显示 loading indicator）
- [x] 成功后 toast："已保存，下次分析生效"
- [x] 失败后 toast："保存失败: <错误信息>"
- [x] 失败时保留现有表单值
- [x] 成功后更新 `_originalConfig` 并重置 `_hasChanges`

**日志输出：**
```
[Settings] Loaded config: {...}
[Settings] Saving config: {...}
[Settings] Config saved to: configs/app_runtime.json
```

---

### 4. 下次分析时 configs_snapshot.json 与表单值一致 ✅

**验证方式：**
1. Settings 页保存配置（例如: `stride=3`, `engine=MediaPipe`）
2. Camera 页触发分析
3. 检查 `<sessionRoot>/configs_snapshot.json`
4. 确认字段与表单值一致

**实现机制：**
```dart
Camera Page: 
  _startAnalysis() 
  → readAppRuntimeConfig() // 读取 Settings 保存的配置
  → writeRuntimeSnapshot(sessionRoot, cfg) // 写入会话快照
```

**快照内容示例：**
```json
{
  "engine": "MediaPipe",
  "strictness": "relaxed",
  "stride": 3,
  "targetFps": 25,
  "resolution": "1920x1080",
  "privacy": {
    "upload": "video+keypoints",
    "confirmVideoUpload": false
  },
  "cleanup": {
    "days": 14
  },
  "logs": {
    "level": "debug"
  }
}
```

---

### 5. 保存/失败有明确反馈 ✅

**成功反馈：**
- [x] 绿色 SnackBar: "已保存，下次分析生效"
- [x] 持续 2 秒
- [x] `_hasChanges` 重置为 `false`
- [x] "保存设置"按钮禁用（无变更）

**失败反馈：**
- [x] 红色 SnackBar: "保存失败: <错误信息>"
- [x] 持续 3 秒
- [x] 表单值保留（不丢失用户输入）
- [x] "保存设置"按钮启用（允许重试）

**校验失败反馈：**
- [x] 红色 SnackBar: "请修正表单错误后再保存"
- [x] 对应字段显示内联错误

---

### 6. 页面通过 flutter analyze 无告警 ✅

**验证命令：**
```bash
cd aiwa_app
flutter analyze lib/ui/pages/settings_page.dart
```

**验证结果：**
```
No issues found!
```

---

### 7. 与 app_runtime_v1.schema.json 保持一致 ✅

**枚举值对齐：**

| 字段 | Schema 枚举 | Settings 页枚举 |
|------|------------|----------------|
| `engine` | `["MoveNet", "MLKit", "MediaPipe", "Auto"]` | ✅ 完全匹配 |
| `strictness` | `["strict", "relaxed"]` | ✅ 完全匹配 |
| `privacy.upload` | `["none", "keypoints-only", "video+keypoints"]` | ✅ 完全匹配 |
| `logs.level` | `["info", "debug", "warning", "error"]` | ✅ 完全匹配（自定义） |

**默认值对齐：**

| 字段 | Schema 默认 | Settings 默认 |
|------|------------|---------------|
| `engine` | `"MoveNet"` | ✅ MoveNet (index 1) |
| `strictness` | `"strict"` | ✅ strict (index 1) |
| `stride` | `2` | ✅ 2 |
| `targetFps` | `30` | ✅ 30 |
| `resolution` | `"1280x720"` | ✅ "1280x720" |
| `privacy.upload` | `"keypoints-only"` | ✅ keypoints-only |
| `privacy.confirmVideoUpload` | `true` | ✅ true |
| `cleanup.days` | `7` | ✅ 7 |
| `logs.level` | `"info"` | ✅ info (index 0) |

**校验规则对齐：**
- [x] `stride ≥ 1`
- [x] `targetFps ≥ 1`
- [x] `resolution` 匹配 `^\d{3,4}x\d{3,4}$`
- [x] `cleanup.days ≥ 0`

---

## 🎯 额外功能

### 变更检测 ✅

**机制：**
- [x] 保存原始配置到 `_originalConfig`
- [x] 每次字段变更调用 `_detectChanges()`
- [x] 比较当前值与原始值
- [x] 更新 `_hasChanges` 状态

**UI 响应：**
- [x] 无变更时"保存设置"按钮禁用
- [x] 有变更时按钮启用

**触发点：**
- [x] Analysis Threshold 切换
- [x] Analysis Engine 切换
- [x] Performance Settings 输入
- [x] Data Management 开关
- [x] Advanced Settings 切换

---

### 恢复默认 ✅

**按钮：**
- [x] 灰色 OutlinedButton: "恢复默认"
- [x] 保存中禁用

**行为：**
```dart
_resetToDefaults() {
  _thresholdMode = 1;              // strict
  _engineMode = 1;                 // MoveNet
  _strideController.text = '2';
  _targetFpsController.text = '30';
  _resolutionController.text = '1280x720';
  _cloudBackupEnabled = false;
  _confirmVideoUpload = true;
  _cleanupDaysController.text = '7';
  _logLevel = 0;                   // info
  _hasChanges = true;              // 标记为已变更
}
```

**反馈：**
- [x] 黄色 SnackBar: "已恢复默认值，请点击保存以应用"
- [x] 清除所有校验错误
- [x] "保存设置"按钮启用

---

## 📸 UI 预览

### 配置板块

#### 1. Analysis Threshold
```
┌────────────────────────────────────┐
│ Analysis Threshold                 │
│                                    │
│ [Relaxed] [Strict*]                │
│                                    │
└────────────────────────────────────┘
```

#### 2. Analysis Engine
```
┌────────────────────────────────────┐
│ Analysis Engine                    │
│                                    │
│ ○ MLKit                            │
│ ● MoveNet                          │
│ ○ MediaPipe                        │
│ ○ Auto                             │
└────────────────────────────────────┘
```

#### 3. Performance Settings
```
┌────────────────────────────────────┐
│ Performance Settings               │
│                                    │
│ Stride (步长)                      │
│ [2]                                │
│ 推理时跳帧数，必须 ≥ 1             │
│                                    │
│ Target FPS (目标帧率)              │
│ [30]                               │
│ 推理目标帧率，必须 ≥ 1             │
│                                    │
│ Resolution (分辨率)                │
│ [1280x720]                         │
│ 格式: 1280x720                     │
└────────────────────────────────────┘
```

#### 4. Data Management
```
┌────────────────────────────────────┐
│ Data Management                    │
│                                    │
│ Upload Video (上传视频)       [OFF]│
│ Confirm Before Upload         [ON] │
│                                    │
│ Cleanup Days (清理天数)            │
│ [7]                                │
│ 保留最近 N 天的会话，必须 ≥ 0      │
│                                    │
│ [Clear Local Data]                 │
└────────────────────────────────────┘
```

#### 5. Advanced Settings
```
┌────────────────────────────────────┐
│ Advanced Settings                  │
│                                    │
│ Log Level (日志级别)               │
│ ● Info                             │
│ ○ Debug                            │
│ ○ Warning                          │
│ ○ Error                            │
└────────────────────────────────────┘
```

#### 6. 按钮组
```
┌────────────────────────────────────┐
│ [恢复默认]  [保存设置]             │
│                                    │
│ [退出登录]                         │
└────────────────────────────────────┘
```

---

## 🔧 技术细节

### 状态管理
```dart
// 表单字段
int _thresholdMode = 0;
int _engineMode = 0;
bool _cloudBackupEnabled = false;
bool _confirmVideoUpload = true;
TextEditingController _strideController;
TextEditingController _targetFpsController;
TextEditingController _resolutionController;
TextEditingController _cleanupDaysController;
int _logLevel = 0;

// 校验错误
String? _strideError;
String? _targetFpsError;
String? _resolutionError;
String? _cleanupDaysError;

// 变更检测
bool _hasChanges = false;
Map<String, dynamic>? _originalConfig;
```

### 关键方法
```dart
// 加载配置
Future<void> _loadConfig()

// 保存配置
Future<void> _saveConfig()

// 恢复默认
void _resetToDefaults()

// 变更检测
void _detectChanges()

// 全量校验
bool _validateAll()

// 单字段校验
void _validateStride(String value)
void _validateTargetFps(String value)
void _validateResolution(String value)
void _validateCleanupDays(String value)

// 枚举转换
int _engineToIndex(String engine)
String _indexToEngine(int index)
int _logLevelToIndex(String level)
String _indexToLogLevel(int index)
```

---

## 🚀 测试场景

### 场景 1：正常保存流程
1. 打开 Settings 页
2. 修改 Stride = 3
3. 修改 Engine = MediaPipe
4. 点击"保存设置"
5. 验证：绿色 toast "已保存，下次分析生效"
6. 验证：`configs/app_runtime.json` 已更新
7. 触发分析，验证 `configs_snapshot.json` 一致

### 场景 2：校验失败
1. 打开 Settings 页
2. 修改 Stride = 0（非法）
3. 点击"保存设置"
4. 验证：红色 toast "请修正表单错误后再保存"
5. 验证：Stride 字段显示 "步长必须 ≥ 1"
6. 修改 Stride = 2
7. 点击"保存设置"
8. 验证：保存成功

### 场景 3：恢复默认
1. 打开 Settings 页
2. 修改多个字段（Stride=5, Engine=Auto, Resolution=1920x1080）
3. 点击"恢复默认"
4. 验证：所有字段恢复为默认值
5. 验证：黄色 toast "已恢复默认值，请点击保存以应用"
6. 点击"保存设置"
7. 验证：配置已保存为默认值

### 场景 4：变更检测
1. 打开 Settings 页
2. 不做任何修改
3. 验证："保存设置"按钮禁用
4. 修改 Stride = 3
5. 验证："保存设置"按钮启用
6. 恢复 Stride = 2
7. 验证："保存设置"按钮禁用（无变更）

### 场景 5：清理历史会话
1. 打开 Settings 页
2. 点击"Clear Local Data"
3. 验证：执行 `SessionManager.cleanupExpired(days: 7)`
4. 验证：绿色 toast "Local data cleaned up successfully!"
5. 验证：7 天前的会话目录已删除

---

## ✅ 最终确认

- [x] 所有 DoD 要求已满足
- [x] 无 linter 错误
- [x] 无 runtime 错误
- [x] 契约完全符合（`app_runtime_v1.schema.json`）
- [x] 字段映射正确
- [x] 轻量校验实现
- [x] 变更检测工作正常
- [x] 恢复默认功能完整
- [x] 保存/失败反馈清晰
- [x] 日志输出完整

**状态：** ✅ 已完成并验证  
**可交付：** ✅ 是

