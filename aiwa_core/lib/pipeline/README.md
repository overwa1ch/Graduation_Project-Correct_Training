# AIWA Pipeline 分析层

## 概述

`aiwa_core/lib/pipeline` 是姿态分析的核心处理层，负责将原始姿态关键点数据转换为可量化的分析结果。该层实现了从关键点序列到角度数据、动作计数、质量评估、评分计算的完整离线分析流程。

## 文件结构

```
aiwa_core/lib/pipeline/
├── pose_input_converter.dart    # 格式转换：Neutral → Pipeline 内部格式
├── pose_series.dart              # 数据结构定义
├── offline_pipeline.dart         # 核心处理管道
├── phases.dart                   # 阶段分割（下蹲/起身）
├── counting.dart                 # 动作计数
└── quality.dart                  # 质量评估
```

## 设计原则

### 1. 离线处理
一次性处理完整的关键点序列，适合视频回放分析场景，不依赖实时流。

### 2. 模块化设计
各功能模块独立，职责清晰：
- **格式转换**：统一外部数据格式
- **阶段分割**：识别运动阶段
- **动作计数**：统计训练次数
- **质量评估**：评估数据可靠性

### 3. 可配置性
通过 `RuleSet` 和 `Strictness` 控制评分标准、阈值参数，支持不同训练场景。

### 4. 容错性
处理缺失关键点、低置信度数据，提供清晰的错误提示。

## 核心组件

### pose_input_converter.dart - 格式转换

将 `NeutralKeypointSeries`（snake_case 命名）转换为 `PoseSeries`（camelCase 命名），供 Pipeline 内部使用。

**主要功能**：
- 关键点名称转换：`left_hip` → `leftHip`
- FPS 计算：基于采样步长和视频帧率
- 元数据提取：引擎信息、分辨率、镜像状态等

**使用示例**：
```dart
final neutralSeries = NeutralKeypointSeries(...);
final poseSeries = poseSeriesFromNeutral(neutralSeries);
```

### pose_series.dart - 数据结构定义

定义 Pipeline 内部使用的核心数据结构：

#### PoseLandmark
单个关键点：
```dart
class PoseLandmark {
  final double x, y;        // 归一化坐标 [0, 1]
  final double? z;          // 可选深度坐标
  final double score;        // 置信度 [0, 1]
  bool get isReliable => score >= 0.5;
}
```

#### PoseFrame
单帧数据：
```dart
class PoseFrame {
  final int index;           // 帧序号
  final int timestampMs;     // 时间戳（毫秒）
  final bool lowConfidence;  // 是否低置信度
  final Map<String, PoseLandmark> keypoints;  // 关键点映射
}
```

#### PoseSeries
完整序列：
```dart
class PoseSeries {
  final double fps;                    // 帧率
  final List<PoseFrame> frames;        // 帧列表
  final PoseSeriesMetadata metadata;   // 元数据
}
```

#### kPoseSeriesRequiredJoints
必需的关键点列表（8个）：
- `leftHip`, `rightHip`
- `leftKnee`, `rightKnee`
- `leftAnkle`, `rightAnkle`
- `leftShoulder`, `rightShoulder`

### offline_pipeline.dart - 核心处理管道

`OfflinePipeline` 是分析流程的主控制器，协调各模块完成从原始关键点到最终分析结果的转换。

#### 处理流程

1. **关键点过滤与平滑**
   - 提取必需关键点（8个）
   - 缺失值插值（最大间隔 3 帧）
   - OneEuro 滤波平滑

2. **角度计算**
   - 左右膝关节角度（hip-knee-ankle）
   - 躯干前倾角度（shoulder-hip 相对于垂直方向）

3. **角度平滑**
   - 使用 OneEuro 滤波器减少抖动

4. **阶段分割**（调用 `phases.dart`）
   - 识别下蹲阶段（角度减小）
   - 识别起身阶段（角度增大）
   - 最小时长阈值：默认 250ms

5. **动作计数**（调用 `counting.dart`）
   - 识别深蹲动作
   - 记录开始、最低点（valley）、结束时间
   - 判断是否达标（qualified）

6. **质量评估**（调用 `quality.dart`）
   - 计算覆盖率（coverage）
   - 判断低置信度（lowConfidence）

7. **指标计算**
   - 深度：最低点膝关节角度
   - 稳定性：膝内扣角度（valgus）
   - 躯干控制：最大前倾角度
   - 节奏：离心/向心时长及比例

8. **评分计算**
   - Form 分数：深度 + 躯干控制
   - Stability 分数：膝内扣控制
   - Tempo 分数：节奏控制
   - Overall 分数：加权综合

9. **问题检测**
   - `DEPTH_INSUFFICIENT`：深度不足
   - `KNEE_VALGUS`：膝内扣
   - `TRUNK_LEAN_EXCESSIVE`：躯干过度前倾

10. **反馈生成**
    - 基于动作完成情况生成训练建议

#### 使用示例

```dart
// 加载规则
final ruleSet = await loadRuleSet();

// 创建 Pipeline
final pipeline = OfflinePipeline(ruleSet, Strictness.strict);

// 运行分析
final result = await pipeline.run(poseSeries);

// 获取输出
final anglesCsv = result.anglesCsv;      // CSV 格式的角度数据
final resultJson = result.resultJson;     // JSON 格式的分析结果
```

#### 输出格式

**angles.csv**：
```csv
t_ms,knee_L,knee_R,trunk_deg
0,120.5,118.3,15.2
33,115.2,113.1,16.8
...
```

**result.json**：
```json
{
  "meta": {
    "template": "squat",
    "fps": 30.0,
    "ruleVersion": "v1.1",
    "strictness": "strict"
  },
  "quality": {
    "coverage": 0.850,
    "lowConfidence": false
  },
  "repCount": 5,
  "attemptsCount": 6,
  "reps": [...],
  "scores": {
    "form": 85.5,
    "stability": 90.2,
    "tempo": 88.0,
    "overall": 87.9
  },
  "issues": [...],
  "evidence": [...]
}
```

### phases.dart - 阶段分割

基于膝关节角度变化趋势识别下蹲和起身阶段。

#### PhaseSeg 类
```dart
class PhaseSeg {
  final int startMs, endMs;  // 阶段起止时间
  final bool isDown;         // true=下蹲, false=起身
}
```

#### 算法原理
- **下蹲阶段**：角度减小（`diff < 0`）
- **起身阶段**：角度增大（`diff > 0`）
- **最小时长**：默认 250ms，过滤短暂波动

#### 使用示例
```dart
final phaseSegs = segmentDownUp(
  tMs: timestamps,
  kneeMain: mainKneeAngles,
  minMs: 250,
);
```

### counting.dart - 动作计数

识别并统计深蹲动作次数，判断每个动作是否达标。

#### Rep 类
```dart
class Rep {
  final int startMs;        // 动作开始时间
  final int valleyMs;       // 最低点时间
  final int endMs;          // 动作结束时间
  final double valleyAngle; // 最低点角度
  final bool qualified;     // 是否达标
}
```

#### 算法原理
1. 使用左右膝关节角度的最小值作为主角度
2. 在时间窗口内寻找局部最小值（valley）
3. 验证 valley 前后存在更高角度（完整动作）
4. 检查最小间隔（避免重复计数）
5. 判断是否达到深度要求（qualified）

#### 使用示例
```dart
final reps = countReps(
  tMs: timestamps,
  kneeL: leftKneeAngles,
  kneeR: rightKneeAngles,
  minIntervalMs: 600,      // 最小间隔 600ms
  windowMs: 150,            // 检测窗口 150ms
  minValleyKneeAngle: 80,  // 严格模式：80°
  detectionThreshold: 100, // 检测阈值：100°
);
```

### quality.dart - 质量评估

评估姿态检测数据的质量，判断输入数据是否足够进行后续分析。

#### Quality 类
```dart
class Quality {
  final double coverage;      // 覆盖率 [0.0, 1.0]，三位小数
  final bool lowConfidence;    // 是否低置信度
}
```

#### 评估标准
- **必需关键点**：6 个下半身关键点（hip、knee、ankle）
- **可靠性要求**：所有关键点 `score >= 0.5`
- **覆盖率计算**：完整帧数 / 总帧数
- **低置信度阈值**：`coverage < 0.7`

#### 使用示例
```dart
final quality = computeQualityFromKeypoints(frames);
// quality.coverage = 0.850
// quality.lowConfidence = false
```

## 数据流

```
NeutralKeypointSeries (snake_case 命名)
    ↓ [pose_input_converter.dart]
    ├─ 名称转换：left_hip → leftHip
    ├─ FPS 计算
    └─ 元数据提取
    ↓
PoseSeries (camelCase 命名)
    ↓ [offline_pipeline.dart]
    ├─ 关键点过滤与平滑
    │   ├─ 提取必需关键点（8个）
    │   ├─ 缺失值插值（maxGap=3）
    │   └─ OneEuro 滤波
    ├─ 角度计算
    │   ├─ 膝关节角度（左右）
    │   └─ 躯干角度
    ├─ 角度平滑（OneEuro）
    ├─ [phases.dart] 阶段分割
    │   └─ 识别下蹲/起身阶段
    ├─ [counting.dart] 动作计数
    │   └─ 识别深蹲次数，判断是否达标
    ├─ [quality.dart] 质量评估
    │   └─ 计算覆盖率和低置信度标志
    ├─ 指标计算
    │   ├─ 深度、稳定性、躯干控制
    │   └─ 节奏（离心/向心）
    ├─ 评分计算
    │   ├─ Form、Stability、Tempo
    │   └─ Overall（加权综合）
    ├─ 问题检测
    │   ├─ 深度不足
    │   ├─ 膝内扣
    │   └─ 躯干过度前倾
    └─ 反馈生成
    ↓
angles.csv + result.json
```

## 依赖关系

### 内部依赖
- `../core/angles.dart` - 角度计算工具（V2、angleABC、trunkAngle）
- `../core/one_euro.dart` - OneEuro 滤波器
- `../core/rounding.dart` - 舍入工具（round1）
- `../core/errors.dart` - 异常定义（AngleComputeFailed、MetricsComputeFailed）
- `../core/perf_timer.dart` - 性能计时器（可选）
- `../pose/keypoint_names.dart` - 关键点名称常量
- `../spec/rule_models.dart` - 规则模型（RuleSet、Strictness）
- `../result/csv_export.dart` - CSV 导出工具

### 外部依赖
- `dart:math` - 数学函数

## 错误处理

### AngleComputeFailed
当无法计算角度时抛出：
- 没有有效的膝关节角度
- 没有有效的躯干角度
- 无法推导主膝关节角度轨迹

### MetricsComputeFailed
当无法计算指标时抛出：
- 缺少关键点的角度值
- 无效的时间窗口
- 无法确定特定指标

## 性能考虑

### 可选性能计时
使用 `PerfTimer` 可选的性能监控：
```dart
final timer = PerfTimer();
final result = await pipeline.run(poseSeries, timer: timer);
// timer 记录各阶段耗时
```

### 处理阶段
- `filtering` - 关键点过滤
- `angles` - 角度计算
- `phaseSeg` - 阶段分割
- `scoring` - 评分计算
- `quality` - 质量评估

## 使用场景

### 1. 视频分析
处理完整视频的关键点序列，生成离线分析报告。

### 2. 实时反馈（预处理）
可预先处理关键点序列，为实时反馈提供基础数据。

### 3. 批量处理
支持批量处理多个视频的分析任务。

## 扩展性

### 添加新的评估指标
1. 在 `_collectRepMetrics` 中添加计算逻辑
2. 在 `_computeScores` 中添加评分函数
3. 在 `resultJson` 中添加输出字段

### 支持新的动作类型
1. 修改 `counting.dart` 的动作识别算法
2. 调整 `phases.dart` 的阶段识别逻辑
3. 更新 `RuleSet` 的配置参数

## 注意事项

1. **输入要求**：确保输入的关键点序列包含必需的 8 个关键点
2. **数据质量**：低覆盖率（< 0.7）可能影响分析准确性
3. **规则配置**：根据训练场景选择合适的 `Strictness` 和 `RuleSet`
4. **异常处理**：捕获 `AngleComputeFailed` 和 `MetricsComputeFailed` 异常

## 相关文档

- [Pose Detection Core](../pose/README.md) - 姿态检测核心层
- [Architecture Overview](../../../docs/00-project/architecture.md) - 整体架构说明
- [Rule Models](../spec/rule_models.dart) - 规则模型定义

