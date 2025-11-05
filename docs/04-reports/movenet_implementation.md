# MoveNet 姿态检测实现文档

**实现日期**: 2025年11月2日  
**版本**: v1.0

## 概述

成功实现了 MoveNet 姿态检测引擎，作为 ML Kit 的替代方案。MoveNet 是 Google 开发的轻量级姿态估计模型，提供更快的推理速度和较小的模型体积。

## 实现内容

### 1. 添加依赖

**文件**: `aiwa_app/pubspec.yaml`

新增依赖：
- `tflite_flutter: ^0.10.4` - TensorFlow Lite Flutter 插件
- `image: ^4.1.7` - 图像处理库（解码、resize、格式转换）

### 2. 模型文件准备

**目录**: `aiwa_app/assets/models/`

支持的模型：
- **MoveNet Lightning** (192x192): 约 3MB，快速推理
- **MoveNet Thunder** (256x256): 约 5MB，更高精度

模型文件需要从 TensorFlow Hub 下载并放置在 `assets/models/` 目录。详见 `assets/models/README.md`。

### 3. 核心实现

#### 3.1 MovenetPoseEngine

**文件**: `aiwa_app/lib/pose/movenet_pose_engine.dart`

核心功能：
- 实现 `PoseEngine` 接口（与 `MlKitPoseEngine` 统一接口）
- 支持 Lightning 和 Thunder 两种模型
- 图像预处理：解码 → Resize（中心裁剪）→ 归一化 → 模型输入
- 输出解析：MoveNet [y, x, confidence] → `NeutralKeypoint`
- 错误处理：图像格式错误降级为空帧，TFLite 异常抛出

关键特性：
- **输入格式**: RGB 图像，像素值归一化到 [0, 1]
- **输出格式**: 17 个关键点，每点包含 [y, x, confidence]
- **坐标系统**: 归一化坐标 [0, 1]，注意 y 在前 x 在后
- **置信度阈值**: 可配置，默认 0.3

#### 3.2 PoseEngineFactory

**文件**: `aiwa_app/lib/pose/pose_engine_factory.dart`

工厂方法：
- `createPoseEngine(String engineName)`: 根据配置创建引擎
- 支持的引擎名称：
  - `'MLKit'` / `'BlazePose'`: 33 点 ML Kit
  - `'MoveNet'`: 17 点 MoveNet Lightning
  - `'MoveNet-Thunder'`: 17 点 MoveNet Thunder
  - `'Auto'`: 自动选择（当前默认 MLKit）
  - `'MediaPipe'`: 占位（未实现）

工具函数：
- `getEngineInfo(String engineName)`: 获取引擎元数据
- `isValidEngineName(String engineName)`: 验证引擎名称
- `getAvailableEngines()`: 列出可用引擎

#### 3.3 VideoAnalysisService 重构

**文件**: `aiwa_app/lib/services/video_analysis_service.dart`

主要改动：
1. **引擎创建**:
   ```dart
   final config = await readAppRuntimeConfig();
   final engineName = (config['engine'] as String?) ?? 'MLKit';
   engine = createPoseEngine(engineName);
   await engine.init(PoseEngineConfig(...));
   ```

2. **统一推理接口**:
   ```dart
   // 旧方式（硬编码 ML Kit）
   detector = ml.PoseDetector(...);
   poses = await detector.processImage(inputImage);
   
   // 新方式（可插拔引擎）
   engine = createPoseEngine(engineName);
   neutralFrame = await engine.infer(engineInput);
   ```

3. **方法签名更新**:
   - `_inferPoses()`: 参数从 `ml.PoseDetector` 改为 `PoseEngine`
   - 使用统一的 `NeutralFrame` 输出格式

4. **资源管理**:
   ```dart
   finally {
     await engine?.close();  // 替代 detector?.close()
   }
   ```

### 4. 架构优势

#### 可插拔设计
- 所有引擎实现统一的 `PoseEngine` 接口
- 通过配置文件切换引擎，无需修改代码
- 易于扩展新引擎（如 MediaPipe）

#### 统一数据格式
- 所有引擎输出 `NeutralFrame`
- 关键点使用统一命名（`kMoveNet17Names`）
- 坐标归一化到 [0, 1]

#### 错误处理
- 图像预处理失败：返回低置信度空帧
- TFLite 推理失败：抛出 `StateError`
- 上层捕获异常并执行降级策略

## 使用方法

### 1. 下载模型文件

```bash
# 下载 MoveNet Lightning
curl -o aiwa_app/assets/models/movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/int8/4.tflite
```

### 2. 配置引擎

编辑 `app_runtime.json`（或通过设置页面）:

```json
{
  "engine": "MoveNet",
  "strictness": "strict",
  ...
}
```

### 3. 运行分析

```bash
cd aiwa_app
flutter pub get
flutter run
```

应用将自动使用配置的引擎进行姿态检测。

## 性能对比

| 引擎 | 关键点数 | 模型大小 | 推理速度 | 精度 | 平台支持 |
|------|---------|---------|---------|------|---------|
| ML Kit | 33 | 内置 | 快 | 高 | Android/iOS |
| MoveNet Lightning | 17 | ~3MB | 很快 | 中 | Android/iOS（CPU）|
| MoveNet Thunder | 17 | ~5MB | 中 | 高 | Android/iOS（CPU）|

**建议**:
- **移动设备**: 优先使用 MoveNet Lightning（速度快）
- **精度要求高**: 使用 ML Kit 或 MoveNet Thunder
- **实时处理**: MoveNet Lightning
- **离线分析**: ML Kit 或 MoveNet Thunder

## 已知限制

1. **iOS GPU 加速**: TFLite 在 iOS 上不支持 GPU，仅 CPU 推理
2. **Z 坐标**: MoveNet 不提供深度信息（Z 坐标）
3. **关键点数量**: MoveNet 仅 17 点，少于 ML Kit 的 33 点
4. **模型下载**: 用户需手动下载模型文件（约 3-5MB）

## 坐标系统说明

### MoveNet 输出格式
- **原始输出**: `[1, 17, 3]` 张量
- **每个关键点**: `[y, x, confidence]`（注意 y 在前）
- **坐标范围**: `[0, 1]`，相对于模型输入尺寸（192 或 256）

### 坐标转换流程
1. MoveNet 输出相对于模型输入（192x192）的归一化坐标
2. 考虑预处理时的缩放和裁剪
3. 映射回原始图像尺寸
4. 归一化为相对于原始图像的 [0, 1] 坐标
5. 输出为 `NeutralKeypoint`

### 示例
```dart
// MoveNet 输出（相对于 192x192）
[y_norm: 0.5, x_norm: 0.5, confidence: 0.9]

// 转换为原始图像坐标（假设原图 720x1280）
x_pixel = x_norm * scale + offset_x
y_pixel = y_norm * scale + offset_y

// 归一化为 NeutralKeypoint
x_normalized = x_pixel / 720
y_normalized = y_pixel / 1280
```

## 调试技巧

### 1. 验证模型加载

```dart
import 'package:flutter/services.dart';

Future<void> testModel() async {
  try {
    final data = await rootBundle.load('assets/models/movenet_lightning.tflite');
    print('✅ 模型文件大小: ${data.lengthInBytes} bytes');
  } catch (e) {
    print('❌ 模型文件加载失败: $e');
  }
}
```

### 2. 查看引擎信息

```dart
final engineInfo = getEngineInfo('MoveNet');
print('Engine: ${engineInfo['name']}');
print('Keypoints: ${engineInfo['keypointCount']}');
print('Input size: ${engineInfo['inputSize']}');
```

### 3. 日志输出

启用调试日志以查看推理详情：
```dart
debugPrint('[MovenetPoseEngine] Keypoints detected: ${neutralFrame.keypoints.length}');
```

## 未来扩展

### 1. MediaPipe 支持
实现 `MediaPipePoseEngine` 类，支持 MediaPipe Pose 模型（33 点）。

### 2. Auto 模式
根据设备性能自动选择最佳引擎：
- 高性能设备：MoveNet Thunder
- 中等设备：MoveNet Lightning
- 低性能设备：ML Kit

### 3. 模型缓存
缓存已下载的模型，减少首次启动时间。

### 4. GPU 加速
在支持的平台（Android）上启用 GPU 委托。

## 故障排除

### 问题 1: 模型文件未找到
**错误**: `Failed to load MoveNet model: Unable to open file`

**解决**:
1. 确认模型文件在 `assets/models/` 目录
2. 运行 `flutter pub get` 重新加载 assets
3. 检查 `pubspec.yaml` 中是否声明了 assets 路径

### 问题 2: iOS 编译失败
**错误**: `ld: framework not found TensorFlowLiteC`

**解决**:
1. 清理构建缓存: `flutter clean`
2. 删除 `ios/Pods` 目录
3. 重新安装: `cd ios && pod install`

### 问题 3: 图像预处理失败
**错误**: `Failed to decode image`

**解决**:
1. 检查输入图像格式（支持 JPEG、PNG）
2. 确认 `image` 包版本正确
3. 查看日志确定具体错误原因

## 测试建议

### 单元测试
```dart
test('MovenetPoseEngine initialization', () async {
  final engine = MovenetPoseEngine();
  await engine.init(PoseEngineConfig());
  expect(engine._initialized, isTrue);
  await engine.close();
});
```

### 集成测试
1. 使用相同视频分别测试 MLKit 和 MoveNet
2. 比较关键点输出差异
3. 记录推理时间和内存使用

### 性能基准
```dart
final stopwatch = Stopwatch()..start();
final frame = await engine.infer(input);
stopwatch.stop();
print('Inference time: ${stopwatch.elapsedMilliseconds}ms');
```

## 参考资料

- [TensorFlow Hub - MoveNet](https://tfhub.dev/s?deployment-format=lite&q=movenet)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Image Package Documentation](https://pub.dev/packages/image)
- [MoveNet 论文](https://arxiv.org/abs/2104.11686)

## 版本历史

### v1.0 (2025-11-02)
- ✅ 实现 MovenetPoseEngine 基础功能
- ✅ 创建 PoseEngineFactory 工厂方法
- ✅ 重构 VideoAnalysisService 使用统一接口
- ✅ 支持 Lightning 和 Thunder 两种模型
- ✅ 完整的错误处理和降级策略
- ✅ 详细的调试日志和文档

---

**作者**: AIWA Team  
**最后更新**: 2025年11月2日

