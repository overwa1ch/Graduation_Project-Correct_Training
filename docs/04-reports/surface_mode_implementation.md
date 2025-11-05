# Surface 模式视频编码实现

## 概述

完全重写了 Android 视频编码逻辑，从 **ByteBuffer 输入模式** 切换到 **Surface 输入模式**，以解决画面扭曲问题。

## 实现日期
2025年11月2日

## 问题背景

### 原方案的问题
- **ByteBuffer 输入模式**：手动处理 YUV 转换、stride、padding
- **格式匹配困难**：NV12 vs NV21 vs I420，不同设备编码器期望不同
- **UV 顺序问题**：U/V 交换无效，问题更深层
- **设备特定行为**：MTK 编码器等有特殊要求
- **调试困难**：格式转换链路长，问题定位困难

### 为什么选择 Surface 模式

1. **系统处理格式转换**
   - 避免手动 RGB→YUV 转换
   - 避免手动处理 stride/padding
   - 避免手动处理 YUV 格式细节（NV12/NV21/I420）

2. **硬件加速路径**
   - GPU 处理，性能更好
   - 数据拷贝更少
   - 格式处理在驱动层，更统一

3. **编码器直接对接**
   - Surface → GPU驱动 → MediaCodec 硬件编码器
   - 驱动层自动匹配格式
   - 减少中间环节

## 实现架构

### 核心流程

```
Bitmap (ARGB)
  ↓
OpenGL Texture (TextureRenderer)
  ↓
Surface (InputSurface/EGL)
  ↓
MediaCodec (Surface input)
  ↓
H.264 编码
```

### 关键组件

#### 1. InputSurface.kt
管理 EGL 上下文和 Surface

**功能**：
- EGL 初始化（Display、Context、Surface）
- 设置 presentation time
- SwapBuffers 提交帧到编码器
- 资源清理

**关键方法**：
- `eglSetup()`: 初始化 EGL 环境
- `makeCurrent()`: 激活 EGL 上下文
- `setPresentationTime()`: 设置帧时间戳
- `swapBuffers()`: 提交帧
- `release()`: 释放 EGL 资源

#### 2. TextureRenderer.kt
使用 OpenGL ES 2.0 渲染 Bitmap 到纹理

**功能**：
- Shader 编译和链接
- Bitmap → GL Texture 上传
- 全屏四边形渲染
- 纹理坐标处理（垂直翻转）

**关键方法**：
- `surfaceCreated()`: 初始化 shader 和纹理
- `drawBitmap()`: 渲染 Bitmap 到当前 Surface
- `release()`: 释放 GL 资源

#### 3. VideoEncoder.kt
使用 Surface 模式的编码器

**主要改变**：
- 使用 `COLOR_FormatSurface` 而不是 `COLOR_FormatYUV420Flexible`
- 调用 `createInputSurface()` 创建输入 Surface
- 对每一帧：
  1. 解码 JPEG → Bitmap
  2. 绘制 skeleton overlay
  3. 使用 OpenGL 渲染到 Surface
  4. 设置 presentation time
  5. SwapBuffers 提交到编码器
- 使用 `signalEndOfInputStream()` 结束输入

## 配置更改

### build.gradle.kts
```kotlin
minSdk = 26  // 从 21 提升到 26
```

**理由**：
- `MediaCodec.createInputSurface()` 需要 API 18+（已满足）
- 放弃约 5-10% 的旧设备
- 简化代码，专注于 Surface 模式

## 关键代码变更

### 1. MediaCodec 配置
```kotlin
// 旧代码
setInteger(MediaFormat.KEY_COLOR_FORMAT, 
    MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)

// 新代码
setInteger(MediaFormat.KEY_COLOR_FORMAT, 
    MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
```

### 2. 帧提交流程
```kotlin
// 旧代码（ByteBuffer）
val inputImage = mediaCodec.getInputImage(inputBufferIndex)
bitmapToImagePlanes(bitmap, inputImage)  // 手动 YUV 转换
val yuvData = imageToByteBuffer(inputImage)
inputBuffer.put(yuvData)
mediaCodec.queueInputBuffer(...)

// 新代码（Surface）
textureRenderer.drawBitmap(overlayBitmap, width, height)
inputSurface.setPresentationTime(presentationTimeNs)
inputSurface.swapBuffers()  // 系统处理格式转换
```

### 3. 结束输入
```kotlin
// 旧代码
mediaCodec.queueInputBuffer(..., MediaCodec.BUFFER_FLAG_END_OF_STREAM)

// 新代码
mediaCodec.signalEndOfInputStream()
```

## 删除的代码

移除了所有手动 YUV 处理代码：
- `bitmapToImagePlanes()`: RGB→YUV 转换，处理 stride/padding
- `imageToByteBuffer()`: Image planes → ByteBuffer 提取
- `getColorFormatName()`: 格式调试辅助函数
- 所有 stride 相关日志和调试代码
- UV 顺序处理逻辑

## 优势

### 1. 解决格式匹配问题
- 系统/驱动自动处理格式转换
- 不需要区分 NV12/NV21/I420
- 不需要处理 UV 顺序

### 2. 减少错误点
- 不需要手动 RGB→YUV 转换
- 不需要手动处理 stride/padding
- 不需要手动计算 buffer size

### 3. 更好的性能（虽然不是重点）
- GPU 硬件加速
- 减少 CPU 负担
- 减少数据拷贝

### 4. 更清晰的代码
- 编码逻辑更简洁
- 调试路径更直接
- 维护成本更低

## 潜在限制

### 1. API 级别要求
- 需要 API 26+
- 放弃约 5-10% 旧设备（Android 8.0 以下）

### 2. 失去直接数据访问
- 不能直接读取/修改 YUV 像素数据
- 需要通过 Surface/OpenGL 接口

### 3. OpenGL 依赖
- 需要 EGL 初始化和管理
- 需要 shader 编译和渲染
- 增加一定复杂度

## 测试建议

### 1. 基本功能测试
- 录制视频并检查画面是否正常
- 检查 skeleton overlay 是否正确绘制
- 验证视频时长和帧数是否正确

### 2. 不同设备测试
- 不同 Android 版本（26, 28, 30, 33, 35）
- 不同厂商（Samsung, Xiaomi, OPPO, etc.）
- 不同芯片（高通、MTK、Exynos）

### 3. 边界情况测试
- 不同分辨率（720p, 1080p, 4K）
- 不同帧率（15fps, 30fps, 60fps）
- 长视频（100+ 帧）

### 4. 性能测试
- 编码时间
- 内存占用
- CPU/GPU 使用率

## 回退方案

如果 Surface 模式仍有问题：

### 方案 A：使用 FFmpeg
```kotlin
// 使用 FFmpeg 进行格式转换和编码
// 优点：跨平台一致，格式处理可控
// 缺点：增加依赖和包体积
```

### 方案 B：MediaRecorder + Surface
```kotlin
// 使用 MediaRecorder 进行录制
// 在 Surface 上实时绘制 skeleton
// 优点：系统级录制，更稳定
// 缺点：失去对编码参数的细粒度控制
```

### 方案 C：接受设备特定限制
- 标注已知问题设备
- 在这些设备上降级或禁用功能
- 提供替代方案（如导出图片序列）

## 调试日志

新实现提供详细的日志输出：

```
🎬 Starting Surface-based video encoding
   Frames: 120, FPS: 30, Size: 1280x720

🔧 Configuring MediaCodec with Surface input
✅ Input Surface created
✅ MediaCodec started
📋 Encoder Info:
   Name: c2.mtk.avc.encoder
   Is Hardware Accelerated: true
✅ EGL context created and made current
✅ TextureRenderer initialized
✅ MediaMuxer created

🎥 Starting frame encoding loop
📥 Submitted frame 20/120
📤 Output frame #20: 15234b [KEY]
...

✅ Encoding complete
   Input frames: 120
   Output frames: 120
   File size: 1024 KB
```

## 预期结果

使用 Surface 模式后：
- ✅ 画面扭曲问题应该解决
- ✅ 颜色显示正常
- ✅ Skeleton overlay 正确绘制
- ✅ 视频可正常播放
- ✅ iOS 和 Android 行为一致

## 后续优化（可选）

1. **性能优化**
   - 复用 Bitmap 对象
   - 优化 GL 纹理上传
   - 使用 PBO 异步上传

2. **功能增强**
   - 支持水印和文字覆盖
   - 支持滤镜效果
   - 支持实时预览

3. **错误处理**
   - 更细粒度的错误捕获
   - 自动重试机制
   - 降级方案切换

## 总结

Surface 模式实现通过让系统/硬件处理格式转换，从根本上避免了 ByteBuffer 模式下的格式匹配、stride 处理等问题。这是解决 Android 视频编码画面扭曲的最可靠方案。

虽然增加了 OpenGL/EGL 的复杂度，但换来的是：
- 更稳定的编码结果
- 更好的设备兼容性
- 更清晰的代码结构
- 更容易维护和调试

放弃 API 26 以下的设备是可接受的权衡，因为这些设备占比很小（约 5-10%），且 Android 8.0 发布于 2017 年。

