# MoveNet 快速开始指南

## 步骤 1: 下载模型文件

### 选项 A: 下载 MoveNet Lightning（推荐）

```bash
# 使用 curl
curl -L -o aiwa_app/assets/models/movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/int8/4.tflite

# 或使用 wget
wget -O aiwa_app/assets/models/movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/int8/4.tflite
```

### 选项 B: 手动下载

1. 访问 TensorFlow Hub: https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/int8/4
2. 点击下载模型文件
3. 重命名为 `movenet_lightning.tflite`
4. 放置到 `aiwa_app/assets/models/` 目录

### 验证模型文件

```bash
# Windows PowerShell
Get-Item aiwa_app\assets\models\movenet_lightning.tflite | Select-Object Name, Length

# Linux/macOS
ls -lh aiwa_app/assets/models/movenet_lightning.tflite
```

**预期输出**: 文件大小约 3MB

---

## 步骤 2: 配置引擎

### 方式 A: 通过设置页面（推荐）

1. 运行应用: `flutter run`
2. 进入"设置"页面
3. 在"推理引擎"选项中选择 **MoveNet**
4. 保存设置

### 方式 B: 手动编辑配置文件

编辑或创建配置文件（如果应用已运行，配置文件会自动生成）：

**位置**: `<AppSupport>/aiwa/configs/app_runtime.json`

**Windows**: `%LOCALAPPDATA%\aiwa\configs\app_runtime.json`  
**macOS**: `~/Library/Application Support/aiwa/configs/app_runtime.json`  
**Linux**: `~/.local/share/aiwa/configs/app_runtime.json`

**内容**:
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

## 步骤 3: 运行应用

```bash
cd aiwa_app

# 清理构建（首次使用新依赖建议执行）
flutter clean

# 获取依赖
flutter pub get

# 运行应用
flutter run
```

### Android 设备

```bash
flutter run -d <device_id>
```

### iOS 设备

```bash
# 首次需要安装 pods
cd ios
pod install
cd ..

flutter run -d <device_id>
```

---

## 步骤 4: 测试 MoveNet

### 测试视频分析

1. 在应用中点击"录制/选择视频"
2. 选择一个包含人体的视频
3. 开始分析
4. 观察控制台输出，确认使用的引擎：

**预期日志**:
```
[VideoAnalysis] Creating pose engine: MoveNet
[PoseEngineFactory] ✅ Using MoveNet Lightning (192x192, 17 points)
[MovenetPoseEngine] Loading model: assets/models/movenet_lightning.tflite
[MovenetPoseEngine] Input shape: [1, 192, 192, 3]
[MovenetPoseEngine] Output shape: [1, 17, 3]
[MovenetPoseEngine] Initialized successfully
```

### 验证关键点输出

在前 3 帧，会输出调试信息：
```
[VideoAnalysis] 🔍 Frame 0 (frameIndex=0) debug:
[VideoAnalysis]   Keypoints detected: 17
[VideoAnalysis]   Low confidence: false
[VideoAnalysis]   Sample keypoint (nose):
[VideoAnalysis]     x: 0.512, y: 0.345, score: 0.89
```

---

## 常见问题

### Q1: 模型文件未找到

**错误信息**:
```
[MovenetPoseEngine] Failed to load MoveNet model: Unable to open file
```

**解决方案**:
1. 确认模型文件在 `aiwa_app/assets/models/movenet_lightning.tflite`
2. 执行 `flutter clean && flutter pub get`
3. 重新运行应用

### Q2: 依赖版本冲突

**错误信息**:
```
Because aiwa_app depends on tflite_flutter ^0.10.4...
```

**解决方案**:
```bash
flutter pub upgrade
flutter pub get
```

### Q3: iOS 编译失败

**错误信息**:
```
ld: framework not found TensorFlowLiteC
```

**解决方案**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

### Q4: 关键点检测为空

**症状**: `Keypoints detected: 0`

**可能原因**:
1. 视频中无人体
2. 图像质量太低
3. 模型推理失败

**解决方案**:
1. 使用包含清晰人体的测试视频
2. 检查日志中是否有错误信息
3. 尝试切换回 MLKit 对比

---

## 性能调优

### 使用 MoveNet Thunder（更高精度）

1. 下载 Thunder 模型:
```bash
curl -L -o aiwa_app/assets/models/movenet_thunder.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/int8/4.tflite
```

2. 修改配置:
```json
{
  "engine": "MoveNet-Thunder",
  ...
}
```

### 调整采样率

在配置文件中调整 `stride`（帧采样间隔）:
```json
{
  "stride": 2,  // 每 2 帧处理 1 帧（默认）
  // "stride": 1,  // 处理所有帧（更准确，更慢）
  // "stride": 3,  // 每 3 帧处理 1 帧（更快，可能降低准确性）
}
```

---

## 切换引擎对比

### 测试不同引擎的性能

1. **测试 MLKit**:
   ```json
   {"engine": "MLKit"}
   ```

2. **测试 MoveNet Lightning**:
   ```json
   {"engine": "MoveNet"}
   ```

3. **测试 MoveNet Thunder**:
   ```json
   {"engine": "MoveNet-Thunder"}
   ```

4. 使用相同视频，记录：
   - 推理时间（日志中的 `p95MsPerFrame`）
   - 检测到的关键点数量
   - 置信度分布
   - 分析结果准确性

### 推荐配置

| 场景 | 推荐引擎 | 原因 |
|------|---------|------|
| 实时录制 | MoveNet Lightning | 速度快，延迟低 |
| 视频分析 | MLKit | 精度高，关键点多 |
| 批量处理 | MoveNet Lightning | 速度快，资源占用低 |
| 精度优先 | MLKit / MoveNet Thunder | 更准确的关键点检测 |

---

## 下一步

### 1. 查看详细文档
- [完整实现文档](./MOVENET_IMPLEMENTATION.md)
- [架构设计](./pose/README.md)

### 2. 扩展功能
- 实现 MediaPipe 支持
- 添加 Auto 模式（自动选择引擎）
- 优化图像预处理性能

### 3. 贡献代码
- 报告问题或建议
- 提交 Pull Request
- 优化现有实现

---

## 支持

如有问题或建议，请：
1. 查看 [故障排除](#常见问题)
2. 查看 [完整文档](./MOVENET_IMPLEMENTATION.md#故障排除)
3. 提交 Issue

---

**祝使用愉快！** 🎉

