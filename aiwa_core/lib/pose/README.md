# AIWA Pose Detection Core

## 概述

`aiwa_core/lib/pose` 是姿态检测的核心抽象层，定义了统一的接口、数据结构和工具，实现了引擎可插拔、命名统一、类型安全的设计目标。

## 文件结构

```
aiwa_core/lib/pose/
├── pose_engine.dart           # 统一接口与基础类型定义
├── keypoint_names.dart        # 标准关键点命名常量
├── neutral_keypoint_series.dart  # 序列化与严格验证
└── frame_streamer.dart        # 流式帧处理工具
```

## 设计原则

### 1. 统一接口（PoseEngine）
所有姿态检测引擎（MLKit、MoveNet 等）通过 `PoseEngine` 接口统一，实现可插拔架构。

### 2. 中立语义（NeutralKeypoint）
不同引擎的输出统一转换为中立的关键点格式，包含：
- 统一命名（如 `nose`、`leftHip`）
- 归一化坐标 `[0, 1]`
- 置信度 `[0, 1]`
- 可选深度坐标

### 3. 类型安全
使用强类型类而非 Map，提供编译期和运行时双重保障。

### 4. 严格验证
序列化/反序列化时进行严格验证，确保数据质量。

## 核心组件

### pose_engine.dart - 接口与基础类型

#### PoseEngine 接口

```dart
abstract class PoseEngine {
  Future<void> init(PoseEngineConfig config);
  Future<NeutralFrame> infer(PoseEngineInput input);
  Future<void> close();
}
```

**生命周期**：
1. `init()` - 初始化引擎（加载模型、配置参数）
2. `infer()` - 单帧推理，返回 `NeutralFrame`
3. `close()` - 释放资源（模型、内存等）

#### NeutralKeypoint 类

统一的关键点表示：

```dart
class NeutralKeypoint {
  final String name;      // 标准名称（如 "nose", "leftHip"）
  final double x;          // 归一化 X 坐标 [0, 1]
  final double y;          // 归一化 Y 坐标 [0, 1]
  final double score;      // 置信度 [0, 1]
  final double? z;         // 可选深度坐标
}
```

**特点**：
- 坐标始终归一化到 `[0, 1]`，便于跨分辨率使用
- 名称使用驼峰风格（如 `leftEye`、`rightFootIndex`）
- 支持 `copyWith()` 方法进行不可变更新

#### NeutralFrame 类

单帧推理结果：

```dart
class NeutralFrame {
  final int frameIndex;           // 帧序号（从 0 开始）
  final int timestampMs;          // 时间戳（毫秒）
  final int width;                // 原始帧宽度（像素）
  final int height;               // 原始帧高度（像素）
  final List<NeutralKeypoint> keypoints;  // 关键点列表
  final bool lowConfidence;       // 是否低置信度
  final bool mirrorApplied;       // 是否已应用镜像
}
```

**用途**：
- 将关键点与时间、尺寸信息绑定
- 便于导出和离线管线使用
- 支持 `toJson()` 序列化

#### PoseEngineInput 类

引擎输入参数：

```dart
class PoseEngineInput {
  final Uint8List? imageBytes;     // 原始图像字节（可选）
  final String? filePath;          // 图像文件路径（可选）
  final int width;                 // 帧宽度
  final int height;                // 帧高度
  final int rotationDeg;           // 旋转角度
  final int frameIndex;            // 帧索引
  final int timestampMs;            // 时间戳
  final bool mirrorHorizontally;   // 是否水平镜像
}
```

**注意**：
- `imageBytes` 和 `filePath` 至少提供一个
- MLKit 引擎优先使用 `filePath`（自动处理 JPEG/PNG）
- MoveNet 引擎必须使用 `imageBytes`（原始像素格式）

#### PoseEngineConfig 类

引擎配置：

```dart
class PoseEngineConfig {
  final bool preferAccurate;      // 是否使用高精度模式
  final bool outputZ;              // 是否输出 Z 坐标
  final double minScore;           // 最低置信度阈值
  final bool returnEmptyWhenLow;   // 低置信时是否返回空列表
}
```

### keypoint_names.dart - 标准命名常量

#### 关键常量

**kNeutralKeypointNames** (33 点)
- MLKit/BlazePose 标准命名列表
- 包含：面部（鼻、眼、耳、口）、上肢（肩、肘、腕、指）、下肢（髋、膝、踝、脚）

**kMoveNet17Names** (17 点)
- MoveNet 标准命名列表
- 包含：面部（鼻、眼、耳）、上肢（肩、肘、腕）、下肢（髋、膝、踝）

**kPrimaryLowerBodyJoints**
- 主要下肢关节：`leftHip`, `rightHip`, `leftKnee`, `rightKnee`, `leftAnkle`, `rightAnkle`
- 用于重点分析

**kPrimaryTrunkJoints**
- 主要躯干关节：`leftShoulder`, `rightShoulder`, `leftHip`, `rightHip`
- 用于核心稳定性分析

#### 使用场景

**场景 1：MoveNet 引擎命名映射**
```dart
// movenet_pose_engine.dart
final name = kMoveNet17Names[i];  // 通过索引获取标准名称
```

**场景 2：关键点验证**
```dart
// neutral_keypoint_series.dart
if (!kNeutralKeypointNameSet.contains(name)) {
  throw NeutralKeypointParseError('Invalid keypoint name');
}
```

### neutral_keypoint_series.dart - 序列化与验证

#### 核心问题：它处理的是什么信息？

它处理的是**"姿态检测的结果"**，即从视频/相机中检测出的人体关键点数据。

**具体例子**：
假设你录了一段深蹲视频：
1. **视频分析**：逐帧检测人体关键点（鼻子、肩膀、髋、膝、踝等）
2. **每帧得到约 17-33 个关键点的位置**（x, y, z）和置信度
3. **这些数据就是"姿态检测结果"**

`neutral_keypoint_series.dart` 的作用：
1. **序列化**：调用 `neutralKeypointSeriesToJson()` 把内存中的姿态检测结果（关键点数据）保存为 JSON 文件
   - 保存为 `neutral_keypoints.json`
   - 供后续读取和分析使用
2. **反序列化**：调用 `parseNeutralKeypointSeries()` 从 JSON 文件读取关键点数据到内存
   - 严格验证数据完整性和格式
   - 转换为业务格式供分析管道使用

#### 核心数据结构

**NeutralKeypointSeries**
完整的关键点时间序列：

```dart
class NeutralKeypointSeries {
  final String version;                    // 版本号（如 "vB1.1"）
  final NeutralVideoInfo video;            // 视频元信息
  final NeutralEngineInfo engine;          // 引擎信息
  final NeutralSamplingInfo sampling;      // 采样信息
  final List<NeutralFrameData> frames;     // 所有帧数据
}
```

**NeutralFrameData**
单帧数据（序列化格式）：

```dart
class NeutralFrameData {
  final int frameIndex;
  final int timestampMs;
  final bool lowConfidence;
  final bool mirrorApplied;
  final List<NeutralKeypointValue> keypoints;
}
```

#### 核心功能

**parseNeutralKeypointSeries(String jsonStr)**
严格解析 JSON 字符串（**推荐使用的主入口**）：

- ✅ 验证 JSON 结构完整性
- ✅ 检查版本号（必须 "vB1.1"）
- ✅ 验证关键点名称（必须在 `kNeutralKeypointNameSet` 中）
- ✅ 验证坐标范围（x, y, score 必须在 [0, 1]）
- ✅ 验证时间戳单调递增
- ✅ 抛出 `NeutralKeypointParseError` 提供详细错误信息

**parseNeutralKeypointSeriesFromMap(Map<String, dynamic> root)**
内部实现函数（**不推荐直接使用**）：
- 从已解析的 Map 解析
- 仅作为 `parseNeutralKeypointSeries()` 的内部实现
- 不应直接调用

**neutralKeypointSeriesToJson(NeutralKeypointSeries series)**
序列化为 JSON Map：

- 保持与解析器兼容的格式
- 包含完整的元数据（版本、视频、引擎、采样信息）
- ✅ 正确省略 null 的 z 值（2025-11-08 修复）

#### 序列化（保存）：把检测结果存成 JSON 文件

**流程**：
1. 视频分析完成，得到 `NeutralKeypointSeries`（内存对象）
2. 调用 `neutralKeypointSeriesToJson()` 转为 JSON Map
3. 使用 `JsonEncoder.withIndent('  ')` 格式化
4. 保存为 `neutral_keypoints.json`

**当前实现**：
```dart
// aiwa_app/lib/services/video_analysis_service.dart:990
await neutralFile.writeAsString(
  const JsonEncoder.withIndent('  ').convert(neutralKeypointSeriesToJson(neutralSeries)),
);
```

**✅ 已优化**（2025-11-08）：
- 统一使用 `neutralKeypointSeriesToJson()`
- 之前存在重复的 `_neutralSeriesToJson()` 私有函数，已删除
- 修复了 z 值序列化 bug（正确省略 null 值）

#### 反序列化（读取）：从 JSON 文件恢复数据

**流程**：
1. 读取 `neutral_keypoints.json`
2. 调用 `parseNeutralKeypointSeries()` 解析为 `NeutralKeypointSeries`
3. 转换为业务格式（`poseSeries`）供分析管道使用

**当前使用情况**：

**✅ 已使用（测试代码）**：
```dart
// aiwa_core/test/golden_compare_test.dart:20
final neutralKp = parseNeutralKeypointSeries(await File(kpPath).readAsString());
final poseSeries = poseSeriesFromNeutral(neutralKp);
```
- ✅ 使用严格解析 `parseNeutralKeypointSeries()`
- ✅ 验证版本号、字段类型、坐标范围等
- ✅ 类型安全，错误提示友好

**⚠️ 技术债务（aiwa_app 中）**：
```dart
// aiwa_app/lib/services/keypoint_overlay_generator.dart:45
final keypointsJson = jsonDecode(await keypointsFile.readAsString()) as Map<String, dynamic>;
final frames = keypointsJson['frames'] as List<dynamic>;
final videoInfo = keypointsJson['video'] as Map<String, dynamic>;
final samplingInfo = keypointsJson['sampling'] as Map<String, dynamic>;
```
- ❌ 使用简单的 `jsonDecode()`，不进行严格验证
- ❌ 不验证版本号、数据完整性、坐标范围等
- ❌ 字段缺失或类型错误可能导致崩溃
- ⚠️ 当前场景（骨架视频生成）可以接受，但未来需要改进

**为什么当前可以接受**：
- 数据来源可信（自己生成）
- 使用场景简单（只需部分字段）
- 性能优先（视频编码已经很慢）

**未来改进方向**：
- 跨版本读取时：需要严格验证
- 云端同步时：必须严格验证
- 数据导入时：必须严格验证

#### 完整数据流

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 视频分析阶段（aiwa_app）                                  │
│                                                             │
│  视频文件 (video.mp4)                                       │
│      ↓                                                      │
│  PoseEngine 逐帧检测（MLKit/其他引擎）                      │
│      ↓                                                      │
│  每帧得到 17-33 个关键点的 Map 数据                        │
│      ↓                                                      │
│  _buildNeutralSeries() 构建 NeutralKeypointSeries          │
│  （包含元信息：video、engine、sampling）                   │
│      ↓                                                      │
│  neutralKeypointSeriesToJson() 序列化为 Map                │
│  （✅ 已统一使用标准函数，2025-11-08 修复）                │
│      ↓                                                      │
│  JsonEncoder.withIndent('  ').convert() 格式化             │
│      ↓                                                      │
│  保存为 neutral_keypoints.json（磁盘文件）                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. 读取阶段（使用情况不一致）                                │
│                                                             │
│  读取 neutral_keypoints.json                                │
│      ↓                                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 场景 A：测试代码（✅ 严格解析）                      │   │
│  │                                                      │   │
│  │  parseNeutralKeypointSeries() 严格解析               │   │
│  │  - 验证版本号                                        │   │
│  │  - 验证字段类型                                      │   │
│  │  - 验证坐标范围 [0,1]                               │   │
│  │  - 验证分数范围 [0,1]                               │   │
│  │  - 验证时间戳单调性                                 │   │
│  │  - 验证关键点名称合法性                             │   │
│  └─────────────────────────────────────────────────────┘   │
│      ↓                                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 场景 B：骨架视频生成（⚠️ 简单解析）                 │   │
│  │                                                      │   │
│  │  jsonDecode() 简单解析                              │   │
│  │  - 不验证数据完整性                                    │   │
│  │  - 字段缺失可能崩溃                                  │   │
│  │  - 类型错误可能被忽略                                │   │
│  │  ⚠️ 技术债务：未来需要改进                          │   │
│  └─────────────────────────────────────────────────────┘   │
│      ↓                                                      │
│  得到 NeutralKeypointSeries 或 Map 对象                    │
│      ↓                                                      │
│  poseSeriesFromNeutral() 转换为 PoseSeries                 │
│  （供 OfflinePipeline 使用）                                │
└─────────────────────────────────────────────────────────────┘
```

#### 使用流程

**构建序列**：
```dart
final series = NeutralKeypointSeries(
  version: 'vB1.1',
  video: NeutralVideoInfo(...),
  engine: NeutralEngineInfo(...),
  sampling: NeutralSamplingInfo(...),
  frames: frameDataList,
);
```

**序列化保存**：
```dart
final json = neutralKeypointSeriesToJson(series);
await file.writeAsString(
  const JsonEncoder.withIndent('  ').convert(json)
);
```

**反序列化读取**（推荐）：
```dart
final jsonStr = await file.readAsString();
final series = parseNeutralKeypointSeries(jsonStr);  // 使用主入口
```

#### 关键要点总结

**✅ 序列化（已优化）**：
- **统一使用**：`neutralKeypointSeriesToJson()`
- **已修复**：z 值序列化 bug（正确省略 null）
- **代码质量**：消除重复代码，统一标准

**⚠️ 反序列化（使用不一致）**：
- **测试代码**：✅ 使用 `parseNeutralKeypointSeries()` 严格解析
- **aiwa_app**：⚠️ 使用 `jsonDecode()` 简单解析（技术债务）
- **推荐**：使用 `parseNeutralKeypointSeries()` 作为主入口

**📝 未来改进**：
- 跨版本读取时：需要严格验证
- 云端同步时：必须严格验证
- 数据导入时：必须严格验证

### frame_streamer.dart - 流式帧处理

#### 核心类

**FrameStreamer**
流式帧处理器：

```dart
class FrameStreamer {
  Future<FrameStreamResult> run(Stream<RawImageFrame> frameStream);
}
```

**功能**：
- 接收原始图像帧流
- 按配置的 `stride` 采样帧
- 统一管理时间戳和帧索引
- 调用 `PoseEngine` 进行推理
- 收集所有结果并返回

**FrameStreamerConfig**
流处理配置：

```dart
class FrameStreamerConfig {
  final double fps;              // 源视频帧率
  final int stride;            // 采样步长（每 N 帧处理 1 帧）
  final bool mirror;             // 是否水平镜像
  final String engineName;        // 引擎名称（元数据）
  final String modelName;         // 模型名称（元数据）
  final String sdkVersion;        // SDK 版本（元数据）
  final String videoBasename;    // 视频文件名（元数据）
  
  double get effectiveFps => fps / stride;  // 有效帧率
}
```

**FrameStreamResult**
处理结果：

```dart
class FrameStreamResult {
  final FrameStreamerConfig config;
  final List<NeutralFrame> frames;
  final int width;
  final int height;
  final double frameIntervalMs;
  final int durationMs;
  
  Map<String, dynamic> toNeutralKeypointsJson();  // 导出为 JSON
}
```

#### 使用场景

**场景 1：视频文件批量处理**
```dart
final streamer = FrameStreamer(
  engine: createPoseEngine('MLKit'),
  engineConfig: PoseEngineConfig(...),
  config: FrameStreamerConfig(...),
);

final result = await streamer.run(frameStream);
final json = result.toNeutralKeypointsJson();
```

**场景 2：实时相机流处理**
```dart
// 从相机获取帧流
final cameraStream = ...;
final result = await streamer.run(cameraStream);
```

## 数据流转

### 完整流程

```
1. 引擎推理阶段
   ┌─────────────────────────────────┐
   │ pose_engine.dart                 │
   │ - 定义 PoseEngine 接口          │
   │ - 定义 NeutralKeypoint/Frame    │
   └──────────────┬──────────────────┘
                  │
                  ▼
   ┌─────────────────────────────────┐
   │ aiwa_app/lib/pose/              │
   │ - MlKitPoseEngine               │
   │ - MovenetPoseEngine             │
   │ (实现 PoseEngine 接口)          │
   └──────────────┬──────────────────┘
                  │
                  ▼
   ┌─────────────────────────────────┐
   │ 输出 NeutralFrame               │
   │ (包含 NeutralKeypoint 列表)     │
   └──────────────┬──────────────────┘

2. 命名统一阶段
   ┌─────────────────────────────────┐
   │ keypoint_names.dart             │
   │ - kMoveNet17Names[i]            │
   │ - kNeutralKeypointNames         │
   └──────────────┬──────────────────┘
                  │
                  ▼
   ┌─────────────────────────────────┐
   │ 确保所有引擎输出使用统一命名     │
   └──────────────┬──────────────────┘

3. 序列化阶段
   ┌─────────────────────────────────┐
   │ neutral_keypoint_series.dart    │
   │ - NeutralKeypointSeries        │
   │ - neutralKeypointSeriesToJson() │
   └──────────────┬──────────────────┘
                  │
                  ▼
   ┌─────────────────────────────────┐
   │ 保存为 neutral_keypoints.json   │
   └──────────────┬──────────────────┘

4. 反序列化阶段
   ┌─────────────────────────────────┐
   │ neutral_keypoint_series.dart    │
   │ - parseNeutralKeypointSeries()  │
   │ - 严格验证                      │
   └──────────────┬──────────────────┘
                  │
                  ▼
   ┌─────────────────────────────────┐
   │ 返回 NeutralKeypointSeries     │
   │ 供后续分析/可视化使用            │
   └─────────────────────────────────┘
```

## 使用示例

### 示例 1：基本引擎使用

```dart
import 'package:aiwa_core/pose/pose_engine.dart';
import 'package:aiwa_app/pose/pose_engine_factory.dart';

// 1. 创建引擎
final engine = createPoseEngine('MLKit');

// 2. 初始化
await engine.init(PoseEngineConfig(
  preferAccurate: true,
  outputZ: false,
  minScore: 0.2,
  returnEmptyWhenLow: false,
));

// 3. 推理单帧
final frame = await engine.infer(PoseEngineInput(
  filePath: '/path/to/frame.jpg',
  width: 1920,
  height: 1080,
  frameIndex: 0,
  timestampMs: 0,
  rotationDeg: 0,
  mirrorHorizontally: false,
));

// 4. 使用结果
for (final kp in frame.keypoints) {
  print('${kp.name}: (${kp.x}, ${kp.y}), score=${kp.score}');
}

// 5. 释放资源
await engine.close();
```

### 示例 2：构建并保存序列

```dart
import 'package:aiwa_core/pose/neutral_keypoint_series.dart';
import 'dart:convert';
import 'dart:io';

// 构建序列
final series = NeutralKeypointSeries(
  version: 'vB1.1',
  video: NeutralVideoInfo(
    basename: 'workout_video',
    fpsIntended: 30.0,
    width: 1920,
    height: 1080,
    durationMs: 10000,
  ),
  engine: NeutralEngineInfo(
    name: 'MLKit',
    model: 'accurate',
    sdkVersion: '0.14.0',
  ),
  sampling: NeutralSamplingInfo(
    stride: 2,
    effectiveFps: 15.0,
  ),
  frames: frameDataList,
);

// 序列化保存
final json = neutralKeypointSeriesToJson(series);
final file = File('neutral_keypoints.json');
await file.writeAsString(jsonEncode(json));
```

### 示例 3：读取并验证序列

```dart
import 'package:aiwa_core/pose/neutral_keypoint_series.dart';
import 'dart:convert';
import 'dart:io';

try {
  // 读取 JSON
  final file = File('neutral_keypoints.json');
  final jsonStr = await file.readAsString();
  
  // 严格解析（自动验证）
  final series = parseNeutralKeypointSeries(jsonStr);
  
  // 使用数据
  print('Video: ${series.video.basename}');
  print('Frames: ${series.frames.length}');
  print('Effective FPS: ${series.effectiveFps}');
  
  for (final frame in series.frames) {
    print('Frame ${frame.frameIndex}: ${frame.keypoints.length} keypoints');
  }
} on NeutralKeypointParseError catch (e) {
  print('Parse error: $e');
}
```

### 示例 4：使用 FrameStreamer

```dart
import 'package:aiwa_core/pose/frame_streamer.dart';
import 'package:aiwa_app/pose/pose_engine_factory.dart';

// 创建流处理器
final streamer = FrameStreamer(
  engine: createPoseEngine('MLKit'),
  engineConfig: PoseEngineConfig(
    preferAccurate: true,
    outputZ: false,
    minScore: 0.2,
  ),
  config: FrameStreamerConfig(
    fps: 30.0,
    stride: 2,  // 每 2 帧处理 1 帧
    mirror: true,
    engineName: 'MLKit',
    modelName: 'accurate',
    sdkVersion: '0.14.0',
    videoBasename: 'workout_video',
  ),
);

// 处理帧流
final frameStream = ...;  // Stream<RawImageFrame>
final result = await streamer.run(frameStream);

// 导出结果
final json = result.toNeutralKeypointsJson();
await File('neutral_keypoints.json').writeAsString(jsonEncode(json));
```

## 版本控制

### 当前版本
- **vB1.1** - 当前使用的版本号

### 版本兼容性
- `parseNeutralKeypointSeries()` 严格检查版本号
- 不兼容的版本会抛出 `NeutralKeypointParseError`
- 更新版本时需要更新解析器

## 错误处理

### NeutralKeypointParseError

序列化解析错误：

```dart
try {
  final series = parseNeutralKeypointSeries(jsonStr);
} on NeutralKeypointParseError catch (e) {
  // 错误信息包含详细的路径和类型信息
  print('Parse error at ${e.message}');
}
```

**常见错误**：
- 版本号不匹配
- 关键点名称不在标准集合中
- 坐标超出 [0, 1] 范围
- 时间戳不单调递增
- JSON 结构不完整

## 测试

运行测试以验证功能：

```bash
# 在 aiwa_core 目录下
dart test test/pose/
```

测试覆盖：
- ✅ 接口定义正确性
- ✅ 命名常量完整性
- ✅ 序列化/反序列化一致性
- ✅ 严格验证逻辑
- ✅ 流式处理功能

## 扩展指南

### 添加新引擎

1. 在 `aiwa_app/lib/pose/` 创建新的引擎实现
2. 实现 `PoseEngine` 接口
3. 使用 `keypoint_names.dart` 中的标准名称
4. 在 `pose_engine_factory.dart` 中注册

### 添加新关键点

1. 更新 `keypoint_names.dart` 中的常量列表
2. 更新适配器（如 `keypoint_adapter.dart`）
3. 更新验证逻辑（`neutral_keypoint_series.dart`）
4. 运行测试确保兼容性

### 更新版本

1. 修改 `neutral_keypoint_series.dart` 中的版本号
2. 更新解析器以支持新格式
3. 保持向后兼容或提供迁移工具
4. 更新文档

## 注意事项

1. **坐标归一化**：所有坐标必须归一化到 `[0, 1]`，相对于原始帧尺寸
2. **命名统一**：使用 `keypoint_names.dart` 中的标准名称，不要硬编码
3. **类型安全**：优先使用强类型类，避免直接使用 Map
4. **严格验证**：读取 JSON 时始终使用 `parseNeutralKeypointSeries()` 进行验证
5. **资源管理**：使用完引擎后必须调用 `close()` 释放资源
6. **版本控制**：更新格式时更新版本号，确保兼容性检查

## 参考资料

- [Material Design 3](https://m3.material.io/)
- [Google ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
- [TensorFlow Lite MoveNet](https://www.tensorflow.org/hub/tutorials/movenet)
- [Dart Stream API](https://api.dart.dev/stable/dart-async/Stream-class.html)

