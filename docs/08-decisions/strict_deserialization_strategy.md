# 严格反序列化策略决策记录

**创建日期**：2025-11-02  
**状态**：📝 技术决策记录  
**相关文件**：
- `aiwa_core/lib/pose/neutral_keypoint_series.dart` - 严格反序列化实现
- `aiwa_app/lib/services/keypoint_overlay_generator.dart` - 当前简单解析实现
- `aiwa_app/lib/adapters/result_adapter.dart` - 结果适配器

---

## 📋 背景

当前 `aiwa_app` 中读取 JSON 数据时使用简单的 `jsonDecode`，而 `aiwa_core` 中已经实现了严格的 `parseNeutralKeypointSeries` 反序列化功能，但该功能在 App 中未被实际使用。

### 当前状态

#### 1. 骨架视频生成：使用简单 `jsonDecode`

```dart
// aiwa_app/lib/services/keypoint_overlay_generator.dart:45-54
final keypointsJson = jsonDecode(await keypointsFile.readAsString()) as Map<String, dynamic>;
final frames = keypointsJson['frames'] as List<dynamic>;
final videoInfo = keypointsJson['video'] as Map<String, dynamic>;
final samplingInfo = keypointsJson['sampling'] as Map<String, dynamic>;
```

**特点**：
- ✅ 快速、简单
- ❌ 不验证数据完整性
- ❌ 字段缺失可能崩溃
- ❌ 类型错误可能被忽略

#### 2. 结果页面显示：也使用简单 `jsonDecode`

```dart
// aiwa_app/lib/adapters/result_adapter.dart:218-244
final content = await file.readAsString(encoding: utf8);
final json = jsonDecode(content);
if (json is! Map<String, dynamic>) {
  throw ResultReadException('result.json is not a JSON object');
}
```

**特点**：
- ✅ 快速解析
- ✅ 有部分验证（`assertResultContract`）
- ❌ 不验证关键点数据的完整性

#### 3. 严格反序列化：已实现但未使用

```dart
// aiwa_core/lib/pose/neutral_keypoint_series.dart:137-271
NeutralKeypointSeries parseNeutralKeypointSeries(String jsonStr) {
  // - 验证版本号
  // - 验证所有字段类型
  // - 验证坐标范围 [0,1]
  // - 验证分数范围 [0,1]
  // - 验证时间戳单调性
  // - 验证关键点名称合法性
}
```

**特点**：
- ✅ 严格验证所有字段
- ✅ 类型安全
- ✅ 数据完整性保证
- ❌ 更慢、更复杂

---

## 🤔 为什么当前不需要严格反序列化？

### 1. 数据来源可信
- `neutral_keypoints.json` 和 `result.json` 由同一应用生成
- 格式已知，无需严格验证

### 2. 使用场景简单
- 骨架视频：只需读取坐标和元信息
- 结果页面：只需读取分数和次数
- 不需要完整的数据结构

### 3. 性能考虑
- `jsonDecode` 更快
- 严格解析需要遍历所有字段

---

## 🚀 上线后的场景分析

### 场景 1：数据仍然是自己生成的（当前主要场景）

**结论**：✅ **不需要**严格反序列化

**原因**：
- 数据来源可信（自己生成）
- 格式已知且稳定
- 性能更好

**建议**：继续使用简单 `jsonDecode`

---

### 场景 2：跨版本兼容（需要严格验证）

**场景**：用户升级后需要读取旧版本数据

**问题**：
- 旧版本可能生成 vB1.0，新版本需要 vB1.1
- 需要验证版本号，并可能进行数据迁移

**结论**：✅ **需要**严格反序列化

**实现建议**：
```dart
final series = parseNeutralKeypointSeries(jsonStr);
if (series.version != 'vB1.1') {
  // 执行数据迁移逻辑
  return migrateToV1_1(series);
}
```

---

### 场景 3：云端同步（未来可能）

**场景**：从云端下载的数据，来源不可控

**问题**：
- 数据来源不可控
- 需要防止恶意/损坏数据
- 需要保证数据完整性

**结论**：✅ **必须**使用严格反序列化

**实现建议**：
```dart
// 从云端下载的数据，来源不可控
final cloudData = await downloadFromCloud(sessionId);
// 必须严格验证，防止恶意数据
final series = parseNeutralKeypointSeries(cloudData);
```

**参考文档**：`docs/07-cloud/APP_INTEGRATION_GUIDE.md`

---

### 场景 4：数据导入（用户手动导入）

**场景**：用户可以从外部导入 JSON 文件

**问题**：
- 数据来源未知
- 需要友好的错误提示
- 防止应用崩溃

**结论**：✅ **需要**严格反序列化

**实现建议**：
```dart
// 用户可能从其他设备、其他版本导入
final importedData = await pickFile();
// 必须验证，防止格式错误导致崩溃
try {
  final series = parseNeutralKeypointSeries(importedData);
} on NeutralKeypointParseError catch (e) {
  // 友好提示用户文件格式错误
  showErrorDialog('文件格式错误: ${e.message}');
}
```

---

## 💡 推荐方案：混合策略

根据数据来源选择解析方式：

```dart
/// 智能加载（根据来源自动选择）
class KeypointDataLoader {
  /// 加载本地生成的数据（快速路径）
  static Future<Map<String, dynamic>> loadLocal(String path) async {
    final content = await File(path).readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
  
  /// 加载外部数据（严格验证）
  static Future<NeutralKeypointSeries> loadExternal(String jsonStr) async {
    return parseNeutralKeypointSeries(jsonStr);
  }
  
  /// 智能加载（根据来源自动选择）
  static Future<NeutralKeypointSeries> loadSmart({
    required String path,
    required bool isLocal, // 是否本地生成
  }) async {
    if (isLocal) {
      // 本地数据：快速解析
      final json = await loadLocal(path);
      // 可选：只做基本验证（版本号）
      if (json['version'] != 'vB1.1') {
        throw Exception('Unsupported version: ${json['version']}');
      }
      // 转换为 NeutralKeypointSeries（不严格验证）
      return _convertFromMap(json);
    } else {
      // 外部数据：严格验证
      final content = await File(path).readAsString();
      return parseNeutralKeypointSeries(content);
    }
  }
}
```

---

## 📊 决策总结表

| 场景 | 是否需要严格反序列化 | 优先级 | 实现时机 |
|------|---------------------|--------|----------|
| 本地生成的数据（当前） | ❌ 不需要 | P0 | 已实现 |
| 跨版本读取 | ✅ 需要 | P1 | 版本升级时 |
| 云端同步 | ✅ 必须 | P2 | 云端功能上线时 |
| 用户导入 | ✅ 必须 | P2 | 导入功能实现时 |

---

## 🎯 实施建议

### 当前（上线初期）

**保持现状**，使用简单 `jsonDecode`：
- ✅ 数据自产自用
- ✅ 性能更好
- ✅ 代码更简单

### 未来（功能扩展时）

在以下场景引入严格反序列化：

#### 1. 版本升级检测（P1）

```dart
// 在读取时检查版本
final json = jsonDecode(content);
if (json['version'] != 'vB1.1') {
  // 使用严格解析，获取详细错误信息
  try {
    final series = parseNeutralKeypointSeries(content);
  } catch (e) {
    // 提示用户升级数据格式
    showMigrationDialog();
  }
}
```

#### 2. 云端同步功能（P2）

```dart
// 云端数据必须严格验证
final cloudData = await downloadFromCloud(sessionId);
final series = parseNeutralKeypointSeries(cloudData);
```

#### 3. 数据导入功能（P2）

```dart
// 用户导入的文件必须严格验证
final importedFile = await pickFile();
final series = parseNeutralKeypointSeries(await importedFile.readAsString());
```

---

## 📝 类比说明

- **简单解析** = 自己写的笔记，直接看
- **严格反序列化** = 接收他人文件，需要验证格式和内容

当前 App 是"自己写自己读"，所以用简单解析即可；未来如果需要"接收外部数据"，就需要严格反序列化。

---

## 🔗 相关文档

- `aiwa_core/lib/pose/neutral_keypoint_series.dart` - 严格反序列化实现
- `docs/07-cloud/APP_INTEGRATION_GUIDE.md` - 云端集成指南
- `docs/protocols/schemas/analysis_result_v2.schema.json` - 结果数据 Schema

---

## 📌 后续行动

- [ ] 监控版本升级场景，评估是否需要引入版本检测
- [ ] 云端同步功能实现时，使用严格反序列化
- [ ] 数据导入功能实现时，使用严格反序列化
- [ ] 考虑添加混合策略的 `KeypointDataLoader` 工具类

---

## 🔧 代码质量改进（已实施）

**实施日期**：2025-11-08

### 已修复的问题

#### 1. 序列化函数重复和 Bug

**问题描述**：
- `_neutralSeriesToJson()` (aiwa_app) 与 `neutralKeypointSeriesToJson()` (aiwa_core) 功能重复
- `_neutralSeriesToJson()` 存在 z 值处理 bug：总是包含 `'z': kp.z`，即使 z 为 null
- 导致生成的 JSON 包含不必要的 null 值

**修复方案**：
1. ✅ 删除 `aiwa_app/lib/services/video_analysis_service.dart` 中的 `_neutralSeriesToJson()` 方法（原第 971-1004 行）
2. ✅ 替换两处调用为 `neutralKeypointSeriesToJson()`：
   - 第 990 行：正常保存时
   - 第 1146 行：降级保存时
3. ✅ 统一使用 aiwa_core 提供的标准序列化函数

**修复效果**：

```dart
// 修复前（_neutralSeriesToJson）
{
  "name": "nose",
  "x": 0.5,
  "y": 0.5,
  "z": null,  // ❌ 不必要的 null
  "score": 0.9
}

// 修复后（neutralKeypointSeriesToJson）
{
  "name": "nose",
  "x": 0.5,
  "y": 0.5,
  // ✅ z 字段被正确省略
  "score": 0.9
}
```

**兼容性**：
- ✅ 向后兼容：两种格式都能被正确解析
- ✅ JSON 更简洁，符合 vB1.1 规范

#### 2. 规范确认

**确认事项**：
- ✅ 使用 `parseNeutralKeypointSeries()` 作为主要入口（当前代码已遵循）
- ✅ `parseNeutralKeypointSeriesFromMap()` 仅作为内部实现

### 严格反序列化使用决策

**当前结论**：
- ✅ aiwa_app 中**不需要**使用严格反序列化（性能优先）
  - 骨架视频生成只需部分字段
  - 数据自产自用，格式可信
  - 性能优先（视频编码已经很慢）
- ✅ 但应该使用统一的序列化函数 `neutralKeypointSeriesToJson()`
- ⚠️ 可选：添加基础验证（版本号、frames 非空检查）

**未来场景**：
- 跨版本读取时：需要严格验证
- 云端同步时：必须严格验证
- 数据导入时：必须严格验证

---

**记录人**：AI 助手  
**审核状态**：待审核  
**版本**：v1.1（2025-11-08 更新）





