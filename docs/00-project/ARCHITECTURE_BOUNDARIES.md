# 架构边界决策规则

本文档提供明确的决策树和规则表，帮助开发者在 30 秒内判断代码应该放在 `aiwa_core` 还是 `aiwa_app`。

> 📖 **相关文档**：
> - [系统架构概览](./architecture.md) - 整体架构说明
> - [aiwa_core Pipeline 文档](../../aiwa_core/lib/pipeline/README.md) - 核心管线详细说明
> - [aiwa_core Pose 文档](../../aiwa_core/lib/pose/README.md) - 姿态检测核心层

---

## 🚀 新人快速上手（3 分钟）

如果你是第一次接触这个项目，请按以下步骤快速上手：

### 第一步：理解核心原则

1. **核心优先原则**：如果不确定，优先考虑 `aiwa_core`
2. **禁止重复**：不要在 `aiwa_app` 中重新实现 `aiwa_core` 已有的功能
3. **统一导入**：使用 `import 'package:aiwa_core/aiwa_core.dart';` 一行导入

### 第二步：使用统一导出

```dart
// ✅ 推荐：一行导入核心功能
import 'package:aiwa_core/aiwa_core.dart';

// ❌ 避免：分散导入多个模块
import 'package:aiwa_core/core/errors.dart';
import 'package:aiwa_core/pipeline/quality.dart';
// ... 更多导入
```

### 第三步：实现功能前先检查

在开始编写代码前，先问自己：
1. 这个功能是否涉及核心算法/业务逻辑？
2. `aiwa_core` 是否已经提供了类似功能？
3. 查阅 `aiwa_core/lib/*/README.md` 了解已有能力

### 第四步：完成功能后让 AI 检查

使用 [AI 代码检查提示词](./AI_CODE_REVIEW_PROMPT.md) 让 AI 自动检查是否存在代码漂移。

---

## 🎯 快速决策树

```
┌─ 这段代码会被多个模块使用吗？（aiwa_app、CLI、云端 Worker）
│  ├─ 是 → ✅ aiwa_core
│  └─ 否 ↓
│
├─ 这段代码涉及核心算法/业务逻辑吗？
│  │  （角度计算、平滑算法、计数、质量评估、Schema 验证）
│  ├─ 是 → ✅ aiwa_core
│  └─ 否 ↓
│
├─ 这段代码只涉及 UI/展示/动画吗？
│  ├─ 是 → ❌ aiwa_app/lib/ui/
│  └─ 否 ↓
│
├─ 这段代码涉及平台特定功能吗？
│  │  （相机、文件系统、原生通道、Flutter Widget）
│  ├─ 是 → ❌ aiwa_app/lib/services/ 或 aiwa_app/lib/platform/
│  └─ 否 ↓
│
└─ 这段代码涉及云端 API/后端集成吗？
   ├─ 是 → ❌ aiwa_app/lib/services/auth/ 或 aiwa_cloud/
   └─ 否 → ⚠️ 优先考虑 aiwa_core（默认原则：核心优先）
```

---

## 📋 具体规则表

### ✅ 必须放在 aiwa_core 的功能

| 功能类型 | 文件位置 | 示例 |
|---------|---------|-----|
| **关键点名称常量** | `aiwa_core/lib/pose/keypoint_names.dart` | `kNeutralKeypointNames`, `kMoveNet17Names` |
| **平滑算法** | `aiwa_core/lib/core/one_euro.dart` | `OneEuroFilter` |
| **角度计算** | `aiwa_core/lib/core/angles.dart` | `angleABC`, `trunkAngle` |
| **质量评估** | `aiwa_core/lib/pipeline/quality.dart` | `computeQualityFromKeypoints`, `Quality` |
| **Schema 验证** | `aiwa_core/lib/result/result_reader.dart` | `validateResultSchema` |
| **结果模型** | `aiwa_core/lib/result/result_schema.dart` | `AnalysisResult`, `Scores`, `Evidence` |
| **规则解析** | `aiwa_core/lib/spec/rule_parser.dart` | `parseRuleYaml`, `RuleSet` |
| **计数逻辑** | `aiwa_core/lib/pipeline/counting.dart` | `countReps`, `Rep` |
| **阶段分割** | `aiwa_core/lib/pipeline/phases.dart` | `segmentDownUp`, `PhaseSeg` |
| **核心管线** | `aiwa_core/lib/pipeline/offline_pipeline.dart` | `OfflinePipeline` |
| **错误类型** | `aiwa_core/lib/core/errors.dart` | `AiwaError`, `AngleComputeFailed` |
| **舍入工具** | `aiwa_core/lib/core/rounding.dart` | `round1` |
| **姿态引擎接口** | `aiwa_core/lib/pose/pose_engine.dart` | `PoseEngine`, `NeutralFrame` |
| **关键点序列** | `aiwa_core/lib/pose/neutral_keypoint_series.dart` | `NeutralKeypointSeries`, `parseNeutralKeypointSeries` |
| **帧流处理** | `aiwa_core/lib/pose/frame_streamer.dart` | `FrameStreamer` |

### ❌ 必须放在 aiwa_app 的功能

| 功能类型 | 文件位置 | 示例 |
|---------|---------|-----|
| **UI 组件** | `aiwa_app/lib/ui/widgets/` | `ScoreCard`, `ProgressIndicator` |
| **页面** | `aiwa_app/lib/ui/pages/` | `HomePage`, `CameraPage` |
| **主题配置** | `aiwa_app/lib/theme/` | `SemanticColors`, `ThemeData` |
| **平台通道** | `aiwa_app/lib/services/native/` | `NativeFrameExtractor` |
| **认证状态** | `aiwa_app/lib/services/auth/` | `AuthState`, `AuthService` |
| **API 客户端** | `aiwa_app/lib/services/auth/` | `ApiClient` |
| **视频分析编排** | `aiwa_app/lib/services/analysis/` | `VideoAnalysisService`（调用核心管线） |
| **姿态引擎实现** | `aiwa_app/lib/pose/` | `MlKitPoseEngine`, `MovenetPoseEngine`（实现 `PoseEngine` 接口） |
| **配置管理** | `aiwa_app/lib/services/config/` | `ConfigSync`（读写 app_runtime.json） |

---

## ⚠️ 灰色地带判断指南

### 场景 1：视频分析编排逻辑

**问题**：视频分析的整体流程应该放在哪里？

**答案**：
- ✅ **核心管线**（帧→关键点→角度→计数→评分）→ `aiwa_core/lib/pipeline/offline_pipeline.dart`
- ❌ **平台集成**（视频解码、UI 进度通知、文件 I/O）→ `aiwa_app/lib/services/analysis/video_analysis_service.dart`

**判断依据**：
- 如果逻辑可以在纯 Dart 环境（无 Flutter、无平台依赖）运行 → `aiwa_core`
- 如果需要 Flutter Widget、平台通道、文件系统 → `aiwa_app`

### 场景 2：配置管理

**问题**：配置解析和配置读写应该放在哪里？

**答案**：
- ✅ **规则解析**（rule.yaml → RuleSet 对象）→ `aiwa_core/lib/spec/rule_parser.dart`
- ❌ **运行时配置读写**（app_runtime.json 的读写）→ `aiwa_app/lib/services/config/config_sync.dart`

**判断依据**：
- 如果配置是业务规则、算法参数 → `aiwa_core`
- 如果配置是应用运行时设置（UI 偏好、缓存策略）→ `aiwa_app`

### 场景 3：证据降级策略

**问题**：证据解析逻辑应该放在哪里？

**答案**：
- ✅ **证据解析函数**（从 `AnalysisResult` 提取快照路径、时间窗）→ `aiwa_core/lib/result/result_reader.dart`（`resolveSnapshotPath`, `resolveEvidenceWindow`）
- ❌ **UI 适配器**（将证据转换为 UI 展示格式）→ `aiwa_app/lib/adapters/`（如需要）

**判断依据**：
- 如果逻辑只依赖核心数据模型，不依赖 UI → `aiwa_core`
- 如果需要 Flutter Widget、Material Design → `aiwa_app`

---

## 🚫 禁止区域

### aiwa_core MUST NOT 包含

- ❌ Flutter SDK 依赖（`flutter`、`material`、`widgets`）
- ❌ 平台特定代码（`MethodChannel`、`Platform.isAndroid`、`dart:io` 的文件系统操作）
- ❌ 网络请求库（`http`、`dio`）
- ❌ UI 相关代码（Widget、Theme、Animation）
- ❌ 应用运行时配置（app_runtime.json 的读写）

**验证方法**：`aiwa_core` 应该可以在纯 Dart 环境（无 Flutter）下运行测试。

### aiwa_app MUST NOT 重新实现

- ❌ 角度计算逻辑（应使用 `aiwa_core/lib/core/angles.dart`）
- ❌ 平滑算法（应使用 `aiwa_core/lib/core/one_euro.dart`）
- ❌ 计数逻辑（应使用 `aiwa_core/lib/pipeline/counting.dart`）
- ❌ 质量评估（应使用 `aiwa_core/lib/pipeline/quality.dart`）
- ❌ Schema 验证（应使用 `aiwa_core/lib/result/result_reader.dart`）
- ❌ 关键点名称常量（应使用 `aiwa_core/lib/pose/keypoint_names.dart`）
- ❌ 结果模型解析（应使用 `aiwa_core/lib/result/result_schema.dart`）

**验证方法**：在实现新功能前，先检查 `aiwa_core` 是否已有类似功能。

---

## ⚠️ 常见误判 TOP 5

### 误判 1：在 aiwa_app 中定义关键点名称常量

**错误示例**：
```dart
// ❌ aiwa_app/lib/services/analysis/video_analysis_service.dart
const List<String> myKeypointNames = ['leftHip', 'rightHip', ...];
```

**正确做法**：
```dart
// ✅ 使用核心库已有常量
import 'package:aiwa_core/aiwa_core.dart';
final isValid = kNeutralKeypointNameSet.contains(name);
```

### 误判 2：在 aiwa_app 中实现角度计算

**错误示例**：
```dart
// ❌ aiwa_app/lib/services/analysis/angle_calculator.dart
double calculateAngle(double x1, double y1, ...) {
  // 手动实现角度计算
}
```

**正确做法**：
```dart
// ✅ 使用核心库已有函数
import 'package:aiwa_core/aiwa_core.dart';
final angle = angleABC(hip, knee, ankle);
```

### 误判 3：在 aiwa_app 中实现质量评估

**错误示例**：
```dart
// ❌ aiwa_app/lib/services/analysis/quality_checker.dart
bool checkQuality(List<Frame> frames) {
  // 手动统计覆盖率、低置信度
}
```

**正确做法**：
```dart
// ✅ 使用核心库已有函数
import 'package:aiwa_core/aiwa_core.dart';
final quality = computeQualityFromKeypoints(frames);
```

### 误判 4：在 aiwa_app 中手动解析 result.json

**错误示例**：
```dart
// ❌ aiwa_app/lib/services/analysis/result_parser.dart
final json = jsonDecode(content);
final scores = json['scores'] as Map<String, dynamic>;
final form = scores['form'] as num;
```

**正确做法**：
```dart
// ✅ 使用核心库已有函数
import 'package:aiwa_core/aiwa_core.dart';
final result = await readResultJson(sessionRoot);
final form = result.scores.form;
```

### 误判 5：在 aiwa_core 中使用 Flutter 依赖

**错误示例**：
```dart
// ❌ aiwa_core/lib/pipeline/widget_helper.dart
import 'package:flutter/material.dart';
class MyWidget extends StatelessWidget { ... }
```

**正确做法**：
- 核心库必须是纯 Dart，无 Flutter 依赖
- UI 相关代码放在 `aiwa_app/lib/ui/`

---

## ✅ 提交前自检清单

在提交代码前，请完成以下检查：

### 代码归属检查

- [ ] **我检查了 `aiwa_core/lib/*/README.md` 模块文档**
  - [ ] 查阅了 `aiwa_core/lib/pipeline/README.md`
  - [ ] 查阅了 `aiwa_core/lib/pose/README.md`
  - [ ] 查阅了 `aiwa_core/lib/result/` 相关文档

- [ ] **我使用统一导出导入核心库**
  - [ ] 使用 `import 'package:aiwa_core/aiwa_core.dart';` 而不是分散导入

- [ ] **我确认了代码归属**
  - [ ] 如果涉及核心算法/业务逻辑 → 已放在或计划放在 `aiwa_core`
  - [ ] 如果只涉及 UI/平台 → 已放在 `aiwa_app`

### 重复实现检查

- [ ] **我避免了重复实现**
  - [ ] 没有在 `aiwa_app` 中重新实现 `aiwa_core` 已有的功能
  - [ ] 如果核心库没有但应该有，我考虑了将其添加到核心库

### 禁止区域检查

- [ ] **aiwa_core 代码检查**（如果修改了核心库）
  - [ ] 没有引入 Flutter 依赖
  - [ ] 没有使用平台特定代码（MethodChannel、Platform.isAndroid）
  - [ ] 可以在纯 Dart 环境运行测试

- [ ] **aiwa_app 代码检查**（如果修改了应用层）
  - [ ] 没有重新实现角度计算、平滑算法、计数逻辑
  - [ ] 没有重新实现质量评估、Schema 验证
  - [ ] 没有重新定义关键点名称常量

### AI 检查（推荐）

- [ ] **我使用了 AI 代码检查**
  - [ ] 复制了 [AI 检查提示词](./AI_CODE_REVIEW_PROMPT.md)
  - [ ] 让 AI 检查了代码漂移问题
  - [ ] 根据 AI 建议修复了问题

---

## 🔍 不确定时的处理流程

1. **查阅本文档的规则表**，看是否有匹配的场景
2. **查阅 `aiwa_core/lib/*/README.md`**，了解核心库已有功能
3. **使用快速决策树**，按步骤判断
4. **如果仍不确定**：
   - 优先考虑 `aiwa_core`（默认原则：核心优先）
   - 如果后续发现需要平台依赖，再迁移到 `aiwa_app`

---

## 📝 更新记录

- **2025-01-XX**：初始版本，建立决策树和规则表

---

## 🔗 相关资源

- [aiwa_core 统一导出](../../aiwa_core/lib/aiwa_core.dart) - 一行导入核心功能
- [系统架构概览](./architecture.md) - 整体架构说明
- [核心管线文档](../../aiwa_core/lib/pipeline/README.md) - 分析管线详细说明
- [姿态检测核心层](../../aiwa_core/lib/pose/README.md) - 姿态检测抽象层说明
- [AI 代码检查提示词](./AI_CODE_REVIEW_PROMPT.md) - 完成功能后让 AI 检查
- [代码漂移检测工具](../../scripts/README.md) - 自动化检测脚本

---

## 🛠️ 自动化工具

### 代码漂移快速扫描

运行以下命令检测代码漂移：

```bash
dart scripts/check_drift.dart
```

**检测内容**：
- 是否在 `aiwa_app` 中重新实现了核心算法
- 是否使用了核心库的统一导出
- 是否遵循了架构边界规则

### 合约回归测试

运行以下命令验证核心库输出格式：

```bash
cd aiwa_app
flutter test test/integration/core_contract_test.dart
```

**验证内容**：
- `result.json` 格式是否可解析
- `neutral_keypoints.json` 格式是否可解析
- 规则文件格式是否可解析

**更新黄金样本**：
当核心库输出格式变更时，更新 `aiwa_app/test/fixtures/golden/` 中的文件。

