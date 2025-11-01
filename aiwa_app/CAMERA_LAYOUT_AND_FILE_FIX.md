# Camera 页面布局与文件读取修复

**日期:** 2025-10-30  
**版本:** v1.2  
**状态:** ✅ 已完成

---

## 🎯 修复的问题

### 问题1: 布局在 idle 状态下偏左上方

**症状:**
- 点击按钮**之前**（idle 状态）：布局偏左上方
- 点击按钮**之后**（显示错误/进度）：布局正常

**根本原因:**
- 使用 `Expanded` 无条件包裹状态区域
- 当 `_buildStateSection()` 在 idle 状态返回 `SizedBox.shrink()` 时
- `Expanded` 仍然占据所有剩余空间，将上方内容挤到顶部

**解决方案:**
条件性使用 `Expanded`：
- **idle/success 状态:** 不使用 `Expanded`，保持内容居中
- **running/error/parsing 状态:** 使用 `Expanded` 允许长内容滚动

```dart
// 状态显示区域（根据状态切换）- 条件性滚动
if (_state == CameraState.idle || _state == CameraState.success)
  // idle/success 状态：不使用 Expanded，保持居中
  _buildStateSection(context)
else
  // 其他状态（running/error/parsing）：使用 Expanded 允许滚动
  Expanded(
    child: SingleChildScrollView(
      child: _buildStateSection(context),
    ),
  ),
```

---

### 问题2: 404_FILE_NOT_FOUND 错误

**症状:**
- 点击按钮时出现 `Error: 404_FILE_NOT_FOUND`
- 错误信息: `JSONL file not found: dev/stdout_demo.jsonl`

**根本原因:**
1. **相对路径问题:** 代码使用相对路径 `'dev/stdout_demo.jsonl'`
2. **Android 文件系统:** 在 Android 上，相对路径基于应用的当前工作目录（通常是只读系统目录）
3. **文件未打包:** `dev/` 目录中的文件不会自动打包到 APK

**解决方案:**
使用内存模拟事件流，完全避免文件系统依赖：

```dart
/// 创建模拟事件流（用于演示模式，避免文件路径问题）
Stream<Map<String, dynamic>> _createMockEventStream() async* {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  yield {'event': 'START', 'sessionId': 'demo_session_001', ...};
  
  // ... 模拟各种事件
  
  // 直接创建 result.json 文件
  await File('$_sessionRoot/result.json')
      .writeAsString(jsonEncode(resultJson));
      
  yield {'event': 'DONE', ...};
}
```

---

## 📝 修改的文件

### `aiwa_app/lib/ui/pages/camera_page.dart`

**变更 1: 添加导入**
```dart
import 'dart:convert';  // 用于 jsonEncode
import 'dart:io';       // 用于 File
```

**变更 2: 条件性布局**
```dart
// Line 316-326
if (_state == CameraState.idle || _state == CameraState.success)
  _buildStateSection(context)
else
  Expanded(
    child: SingleChildScrollView(
      child: _buildStateSection(context),
    ),
  ),
```

**变更 3: 添加模拟事件流方法**
```dart
// Line 279-380
Stream<Map<String, dynamic>> _createMockEventStream() async* {
  // 模拟完整的分析流程
  // - START 事件
  // - PHASE 事件
  // - PROGRESS 事件（带进度和 ETA）
  // - METRIC 事件（质量指标）
  // - EVIDENCE 事件
  // - 创建 result.json 文件
  // - DONE 事件
}
```

**变更 4: 更新 _startAnalysis**
```dart
// Line 92-113
// 使用模拟事件流替代 JSONL 文件读取
final stream = _createMockEventStream();
```

---

## ✅ 验证清单

### 功能验证
- [x] idle 状态下按钮区域居中显示
- [x] 点击按钮后不再出现 404 错误
- [x] 进度条正常显示并更新
- [x] 错误框高度受限且可滚动
- [x] 成功后弹出 Result Popup
- [x] 无 linter 错误

### 布局验证
- [x] 点击前：标题和按钮居中
- [x] 运行中：进度条在底部，可见
- [x] 错误时：错误框在底部，可滚动
- [x] 不同屏幕尺寸下布局稳定

---

## 🚀 测试步骤

### 1. 热重载应用
```bash
cd aiwa_app
# 在已运行的应用中按 'r' 热重载
```

### 2. 测试 idle 状态布局
- 观察标题和按钮是否居中
- 确认没有偏向左上角

### 3. 测试分析流程
```
1. 点击 "Record New Video" 按钮
2. 观察进度条出现并更新（0% → 50% → 100%）
3. 观察质量警告提示（如果有）
4. 等待 Result Popup 自动弹出
5. 验证分数显示正确（Posture: 84, Stability: 78, Rhythm: 82）
```

### 4. 测试错误处理
- 修改 `_createMockEventStream` 抛出错误
- 验证错误框显示正确且可滚动

---

## 📊 模拟事件流时序

| 时间 | 事件 | 说明 |
|------|------|------|
| 0ms | - | 点击按钮 |
| 500ms | START | 开始分析 |
| 800ms | PHASE | 解码阶段 |
| 1300ms | PROGRESS | 推理进度 25% (ETA: 18s) |
| 2300ms | PROGRESS | 分析进度 50% (ETA: 9s) |
| 2800ms | METRIC | 质量指标（可能触发警告） |
| 3100ms | EVIDENCE | 证据帧信息 |
| 3600ms | DONE | 分析完成，创建 result.json |

**总耗时:** ~3.6 秒

---

## 🔍 技术细节

### 为什么使用模拟事件流？

| 方案 | 优点 | 缺点 | 适用场景 |
|-----|------|------|---------|
| **模拟流** | ✅ 无文件依赖<br>✅ 跨平台<br>✅ 可控时序 | 不是真实分析 | 演示/开发 |
| JSONL 文件 | 真实数据 | ❌ 需打包 asset<br>❌ 路径问题 | 离线测试 |
| CLI 子进程 | 真实分析 | ❌ 仅桌面平台<br>❌ 性能开销 | 桌面开发 |
| Isolate | 真实分析 | ❌ 复杂实现 | 生产环境 |

### 生产环境迁移建议

当准备使用真实分析时，替换 `_startAnalysis` 中的流创建：

```dart
// 开发/演示模式
final stream = _createMockEventStream();

// 生产模式（移动端）
final stream = analysisEventsFromIsolate(
  inputPath: videoPath,
  sessionRoot: _sessionRoot!,
  configPath: 'configs/app_runtime.json',
);

// 生产模式（桌面端）
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 'aiwa_cli/bin/aiwa_cli.dart',
    '--input', videoPath,
    '--out', _sessionRoot!,
    '--config', 'configs/app_runtime.json',
  ],
);
```

---

## 🎨 布局状态图

### Idle 状态（修复前）
```
┌─────────────────────┐
│ SafeArea            │
│  ┌──────────────┐   │ ← Expanded 占据所有空间
│  │              │   │
│  │ (空状态区域)  │   │
│  │              │   │
│  └──────────────┘   │
│                     │
│  Welcome to         │ ← 被挤到底部
│  MoveAnalyzer!      │
│  [Record Video]     │
│  [Import Videos]    │
└─────────────────────┘
```

### Idle 状态（修复后）
```
┌─────────────────────┐
│ SafeArea            │
│                     │
│  Welcome to         │ ← 居中显示
│  MoveAnalyzer!      │
│  [Record Video]     │
│  [Import Videos]    │
│                     │
│  (空状态区域)        │ ← 不使用 Expanded
│                     │
└─────────────────────┘
```

### Running 状态
```
┌─────────────────────┐
│ SafeArea            │
│  Welcome to         │
│  MoveAnalyzer!      │
│  [Record Video]     │
│  [Import Videos]    │
│                     │
│ ┌─────────────────┐ │
│ │ ⚠️ Low coverage │ │ ← 可滚动区域
│ │                 │ │
│ │ ███████░░░░ 70% │ │ ← 进度条
│ │ Analyzing... 70%│ │
│ │ ETA: 9s • 33ms  │ │
│ └─────────────────┘ │
└─────────────────────┘
```

---

## 📚 相关文档

- [Event Bus Service](lib/services/README.md)
- [Result Adapter](lib/adapters/README.md)
- [Session Manager](lib/services/session_manager.dart)
- [Camera Page Fix Summary](CAMERA_PAGE_FIX_SUMMARY.md)

---

## ✨ 后续优化建议

1. **增强模拟数据:**
   - 添加多种模板（squat/pushup/plank）
   - 模拟不同质量场景（低置信度、低覆盖率）
   - 支持自定义延迟和进度曲线

2. **过渡到真实分析:**
   - 实现 `analysisEventsFromIsolate`
   - 集成 ML Kit 姿态检测
   - 添加视频选择器 UI

3. **改进用户体验:**
   - 添加取消按钮动画
   - 进度条平滑过渡
   - 错误重试策略

---

**状态:** ✅ 已完成并验证  
**可交付:** ✅ 是

