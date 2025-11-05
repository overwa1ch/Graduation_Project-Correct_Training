# Config Sync Layer

**版本:** v1.0  
**契约依据:**
- `docs/protocols/schemas/app_runtime_v1.schema.json` (配置字段/默认值/枚举)
- `docs/protocols/artifacts_layout.md` (配置文件路径约定)

## 概述

配置同步层负责 Settings 表单与 `configs/app_runtime.json` 的双向同步。

**职责：**
- ✅ Settings 表单 ↔ `configs/app_runtime.json` 双向同步（全局）
- ✅ 每次分析时生成会话级只读快照 `configs_snapshot.json`
- ✅ 产出 CLI/Isolate 可用的参数三元组
- ✅ 枚举和数值合法化（不合法回退默认+警告）

**非职责：**
- ❌ 不做事件订阅
- ❌ 不做 Schema 运行时强校验（留给 CI）
- ❌ 不做 UI

---

## 快速开始

### 1. 读取当前配置

```dart
import 'package:aiwa_app/services/config_sync.dart';

final cfg = await readAppRuntimeConfig();
print('Engine: ${cfg['engine']}');        // "MoveNet"
print('Strictness: ${cfg['strictness']}'); // "strict"
print('Stride: ${cfg['stride']}');         // 2
```

### 2. 保存表单配置

```dart
// 用户在 Settings 中修改配置
await writeAppRuntimeConfig({
  'engine': 'MLKit',
  'strictness': 'relaxed',
  'stride': 3,
});

// 配置已保存到 configs/app_runtime.json
```

### 3. 生成会话快照

```dart
// 分析开始时，记录当次生效的配置
final effectiveCfg = await readAppRuntimeConfig();

await writeRuntimeSnapshot(
  'build/offline_out/20251028_101320_7f2c',
  effectiveCfg,
);

// 快照已保存到: build/offline_out/20251028_101320_7f2c/configs_snapshot.json
```

### 4. 构建 CLI 参数

```dart
// 统一生成 CLI/Isolate 参数
final args = buildCliArgs(
  pickedInput: '/path/to/video.mp4',
  sessionRoot: 'build/offline_out/session_001',
);

// args.inputPath: '/path/to/video.mp4'
// args.sessionRoot: 'build/offline_out/session_001'
// args.configPath: 'configs/app_runtime.json'
```

---

## 核心 API

### `readAppRuntimeConfig({String? pathOverride})`

读取 App 运行配置（全局，不随会话变）

**返回:**
- `Future<Map<String, dynamic>>` - 配置 Map（已合并默认值）

**行为:**
- 若文件不存在，返回默认值（不抛错）
- 若 JSON 解析失败，抛 `ConfigInvalid`
- 自动合并默认值（文件优先级高于默认值）

---

### `writeAppRuntimeConfig(Map<String, dynamic> cfg, {String? pathOverride})`

写入 App 运行配置（全局，不随会话变）

**合并策略:**
1. 加载默认值
2. 若本地文件存在，合并现有配置（现有优先）
3. 叠加表单输入（表单优先级最高）

**异常:**
- `FileSystemException` - 写入失败
- `ConfigInvalid` - 解析失败

**合法化:**
- 枚举值大小写不敏感（自动规范化）
- 数值范围检查（不合法回退默认）
- 分辨率格式检查（`\d{3,4}x\d{3,4}`）

---

### `writeRuntimeSnapshot(String sessionRoot, Map<String, dynamic> effectiveCfg)`

生成运行快照（会话级只读记录）

**参数:**
- `sessionRoot`: 会话根目录
- `effectiveCfg`: 当次生效的配置（已合并、已合法化）

**异常:**
- `FileSystemException` - 写入失败

**行为:**
- 写入路径: `${sessionRoot}/configs_snapshot.json`
- 原样写入 `effectiveCfg`（不再二次合并/加工）

---

### `buildCliArgs({required String pickedInput, required String sessionRoot, String configPath})`

生成 CLI/Isolate 参数（统一出口）

**返回:**
- `({String inputPath, String sessionRoot, String configPath})`

**目的:**
- 上层调用时一个函数拿全，避免分散拼接导致路径不一致

---

## 默认配置

基于 `app_runtime_v1.schema.json`：

```json
{
  "engine": "MoveNet",
  "strictness": "strict",
  "stride": 2,
  "targetFps": 30,
  "resolution": "1280x720",
  "privacy": {
    "upload": "keypoints-only",
    "confirmVideoUpload": true
  },
  "cleanup": {
    "days": 7
  },
  "logs": {
    "level": "info"
  }
}
```

---

## 字段合法化规则

### 枚举值

| 字段 | 有效值 | 规范化 |
|------|--------|--------|
| `engine` | MoveNet, MLKit, MediaPipe, Auto | 大小写不敏感 |
| `strictness` | strict, relaxed | 大小写不敏感 |
| `privacy.upload` | none, keypoints-only, video+keypoints | 严格匹配 |

**不合法枚举 → 回退默认 + 警告**

### 数值范围

| 字段 | 范围 | 默认值 |
|------|------|--------|
| `stride` | ≥ 1 | 2 |
| `targetFps` | ≥ 1 | 30 |
| `cleanup.days` | ≥ 0 | 7 |

**超出范围 → 回退默认 + 警告**

### 分辨率

格式：`\d{3,4}x\d{3,4}`

示例：
- ✅ `1280x720`
- ✅ `1920x1080`
- ❌ `foo` → 回退 `1280x720`

### 布尔值

- `privacy.confirmVideoUpload` 缺失 → 默认 `true`

---

## 合并策略

### 优先级（从低到高）

1. **默认值** - 来自 schema
2. **现有文件** - 已保存的配置
3. **表单输入** - 用户当前修改

### 示例

```dart
// 初始状态：默认值
// { engine: "MoveNet", stride: 2, strictness: "strict" }

// 1. 第一次保存（表单）
await writeAppRuntimeConfig({ engine: "MLKit", stride: 1 });
// 结果：{ engine: "MLKit", stride: 1, strictness: "strict" }

// 2. 第二次保存（仅改 engine）
await writeAppRuntimeConfig({ engine: "MoveNet" });
// 结果：{ engine: "MoveNet", stride: 1, strictness: "strict" }
//       ↑ 表单覆盖        ↑ 现有保留     ↑ 默认保留
```

### 深度合并

嵌套对象支持深度合并：

```dart
// 现有配置
// { privacy: { upload: "none", confirmVideoUpload: false } }

// 表单仅修改 upload
await writeAppRuntimeConfig({
  'privacy': { 'upload': 'keypoints-only' }
});

// 结果：confirmVideoUpload 保留
// { privacy: { upload: "keypoints-only", confirmVideoUpload: false } }
```

---

## 异常处理

### `ConfigInvalid`

契约违反异常（JSON 解析失败、Schema 不符合）

```dart
class ConfigInvalid implements Exception {
  final String message;
}
```

**常见场景:**
- `invalid json at <path>: <error>`
- `app_runtime.json is not a JSON object`

### `FileSystemException`

文件系统异常（写入失败）

```dart
// Dart 标准异常
throw FileSystemException('Failed to write app_runtime.json', path, ...);
```

**常见场景:**
- 目录不存在（自动创建，应不会触发）
- 权限不足
- 磁盘空间不足

---

## 测试

运行单元测试：

```bash
cd aiwa_app
flutter test test/config_sync_test.dart
```

**测试覆盖（24 个测试用例）:**
- ✅ 读取缺省（返回默认值）
- ✅ 写入后文件存在且字段顺序稳定
- ✅ 合并优先级（表单 > 现有 > 默认）
- ✅ 枚举规范化（大小写不敏感）
- ✅ 非法值回退（数值/分辨率/枚举）
- ✅ 浮点数取整
- ✅ privacy 嵌套对象
- ✅ 快照原样写入
- ✅ 参数组装
- ✅ JSON 解析失败（抛异常）
- ✅ 未知字段保留（前向兼容）
- ✅ cleanup.days 边界值
- ✅ 深度嵌套合并

---

## 文件路径

### 全局配置

- 路径：`configs/app_runtime.json`（相对项目根目录）
- 作用：Settings 表单读写
- 生命周期：持久化，跨会话

### 会话快照

- 路径：`${sessionRoot}/configs_snapshot.json`
- 作用：只读记录，追溯当次分析配置
- 生命周期：随会话保存，用于回溯

---

## 与其他层集成

### 与事件层集成

```dart
import 'package:aiwa_app/services/event_bus.dart';
import 'package:aiwa_app/services/config_sync.dart';

// 1. 读取配置
final cfg = await readAppRuntimeConfig();

// 2. 生成参数
final args = buildCliArgs(
  pickedInput: videoPath,
  sessionRoot: sessionRoot,
);

// 3. 启动分析
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 'aiwa_cli/bin/aiwa_cli.dart',
    '--input', args.inputPath,
    '--out', args.sessionRoot,
    '--config', args.configPath,
  ],
);

// 4. 生成快照
await writeRuntimeSnapshot(args.sessionRoot, cfg);

// 5. 监听事件
await for (final event in stream) {
  // 处理事件...
}
```

---

## 常见问题

### Q: 配置文件不存在怎么办？

A: `readAppRuntimeConfig()` 自动返回默认值（不抛错），首次使用时无需手动创建。

---

### Q: 如何覆盖配置文件路径？

A: 使用 `pathOverride` 参数：

```dart
final cfg = await readAppRuntimeConfig(
  pathOverride: 'custom/path/config.json',
);
```

---

### Q: 表单只修改部分字段，其他字段会丢失吗？

A: 不会。合并策略保证未修改字段保留：
- 表单优先级最高（覆盖）
- 现有配置次之（保留）
- 默认值最低（补充）

---

### Q: 如何处理不合法的配置值？

A: 自动回退默认值并记录警告：

```
[ConfigSync] Warning: engine "InvalidEngine" normalized to "MoveNet"
[ConfigSync] Warning: invalid resolution "foo", using default
```

---

### Q: `configs_snapshot.json` 和 `app_runtime.json` 有什么区别？

A:
- `app_runtime.json` - 全局配置，Settings 读写
- `configs_snapshot.json` - 会话快照，只读，用于追溯

---

### Q: 未知字段会被保留吗？

A: 会保留（前向兼容），便于版本升级：

```dart
await writeAppRuntimeConfig({
  'engine': 'MoveNet',
  'futureFeature': { 'nested': 'data' }, // 保留
});
```

---

## 技术细节

- **语言:** Dart (Flutter)
- **空安全:** 严格空安全
- **依赖:** 无第三方包（纯 Dart）
- **编码:** UTF-8（无 BOM）
- **JSON 格式:** 2 空格缩进，字段顺序稳定
- **平台:** 全平台（Android/iOS/macOS/Windows/Linux/Web）

---

## 更多资源

- **契约规范:** `docs/protocols/schemas/app_runtime_v1.schema.json`
- **产物规范:** `docs/protocols/artifacts_layout.md`
- **源代码:** `lib/services/config_sync.dart`
- **单元测试:** `test/config_sync_test.dart`

---

## 许可

遵循项目主许可证。

