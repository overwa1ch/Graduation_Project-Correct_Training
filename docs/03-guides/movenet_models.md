# MoveNet 模型文件

## 获取模型

### MoveNet Lightning (192x192) - 推荐用于移动设备

1. **下载链接**:
   - TensorFlow Hub: https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/int8/4
   - 或直接下载: https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/int8/4.tflite

2. **保存位置**:
   - 下载后重命名为 `movenet_lightning.tflite`
   - 放置在此目录：`aiwa_app/assets/models/movenet_lightning.tflite`

3. **模型信息**:
   - 输入尺寸：192x192x3 (RGB)
   - 输出：17个关键点，每点 [y, x, confidence]
   - 模型大小：约 3MB
   - 推理速度：快速（适合实时处理）

### MoveNet Thunder (256x256) - 可选（更高精度）

1. **下载链接**:
   - TensorFlow Hub: https://tfhub.dev/google/lite-model/movenet/singlepose/thunder/tflite/int8/4
   - 或直接下载: https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/int8/4.tflite

2. **保存位置**:
   - 下载后重命名为 `movenet_thunder.tflite`
   - 放置在此目录：`aiwa_app/assets/models/movenet_thunder.tflite`

3. **模型信息**:
   - 输入尺寸：256x256x3 (RGB)
   - 输出：17个关键点，每点 [y, x, confidence]
   - 模型大小：约 5MB
   - 推理速度：较慢（更高精度）

## 使用方法

模型文件下载并放置后，运行：

```bash
cd aiwa_app
flutter pub get
```

应用将自动打包模型文件到 Flutter assets。

## 模型详情

MoveNet 输出格式：
- Shape: [1, 17, 3]
- 每个关键点包含 3 个值：[y坐标, x坐标, 置信度]
- 坐标范围：[0, 1]，相对于输入图像尺寸归一化
- 置信度范围：[0, 1]

关键点索引（17点）：
0. nose (鼻子)
1. leftEye (左眼)
2. rightEye (右眼)
3. leftEar (左耳)
4. rightEar (右耳)
5. leftShoulder (左肩)
6. rightShoulder (右肩)
7. leftElbow (左肘)
8. rightElbow (右肘)
9. leftWrist (左腕)
10. rightWrist (右腕)
11. leftHip (左髋)
12. rightHip (右髋)
13. leftKnee (左膝)
14. rightKnee (右膝)
15. leftAnkle (左踝)
16. rightAnkle (右踝)

## 验证模型

在 Dart 代码中验证模型是否加载成功：

```dart
import 'package:flutter/services.dart';

Future<void> testModelExists() async {
  try {
    final ByteData data = await rootBundle.load('assets/models/movenet_lightning.tflite');
    print('✅ 模型文件存在，大小: ${data.lengthInBytes} bytes');
  } catch (e) {
    print('❌ 模型文件不存在: $e');
  }
}
```

