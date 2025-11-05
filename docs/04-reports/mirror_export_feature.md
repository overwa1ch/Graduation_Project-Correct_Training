# 镜像导出功能说明

## 📦 功能概述

从 v1.1 开始，应用会自动将分析结果镜像导出到 Android 外部存储，方便开发者通过 `adb pull` 获取文件进行测试和调试。

## ✨ 特性

- ✅ **自动导出**：分析完成后自动镜像，无需手动操作
- ✅ **完整文件**：包括 `neutral_keypoints.json`、`result.json`、`angles.csv`、`logs/perf.json`
- ✅ **降级模式支持**：即使分析部分失败，也会导出可用数据
- ✅ **非阻塞**：导出失败不影响主流程

## 📁 导出位置

```
/storage/emulated/0/Android/data/com.example.aiwa_app/files/export/<session-id>/
├── neutral_keypoints.json
├── result.json
├── angles.csv
└── logs/
    └── perf.json
```

## 🔧 使用方法

### 1. 运行分析

正常使用 App 进行视频分析，分析完成后文件会自动导出。

### 2. 查看导出目录

```bash
# 查看所有导出的会话
adb shell ls -la /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/

# 查看特定会话的文件
adb shell ls -la /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/<session-id>/
```

### 3. 拉取文件到电脑

```bash
# 拉取整个会话目录（推荐）
adb pull /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/<session-id>/ ./

# 或只拉取 neutral_keypoints.json
adb pull /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/<session-id>/neutral_keypoints.json ./

# 拉取所有导出文件
adb pull /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/ ./export/
```

### 4. 查看日志

分析过程中会输出导出路径：

```
[VideoAnalysis] 📦 Mirrored 4 files to: /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/20241031_123456
[VideoAnalysis] 💡 To pull: adb pull /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/20241031_123456 ./
```

## 🛠️ 技术细节

### 实现位置

- **文件**：`aiwa_app/lib/services/video_analysis_service.dart`
- **方法**：`_mirrorToExternalStorage()`
- **调用点**：
  - 正常分析后（第 243 行）
  - 降级存储后（第 996 行）

### 工作流程

1. 分析完成，文件保存到内部存储
2. 调用 `getExternalStorageDirectory()` 获取外部路径
3. 在 `export/<session-id>/` 创建目录
4. 复制所有输出文件到导出目录
5. 输出日志显示导出路径

### 错误处理

- 外部存储不可用时：跳过导出，记录警告日志
- 文件复制失败时：记录错误，但不影响主流程
- 部分文件缺失时：仅导出存在的文件

## 📝 注意事项

1. **权限**：应用需要外部存储权限（已在 `AndroidManifest.xml` 中配置）
2. **空间**：确保外部存储有足够空间（每个会话约 1-5 MB）
3. **清理**：导出文件不会自动清理，建议定期手动删除旧文件
4. **兼容性**：仅适用于 Android（iOS 不支持 `getExternalStorageDirectory()`）

## 🔍 故障排查

### 问题：未找到导出文件

**解决方案：**
1. 检查日志是否有导出成功的消息
2. 确认包名是否正确（`com.example.aiwa_app`）
3. 检查外部存储权限

### 问题：adb pull 失败

**解决方案：**
```bash
# 检查设备连接
adb devices

# 检查路径是否存在
adb shell ls /storage/emulated/0/Android/data/com.example.aiwa_app/files/export/

# 尝试使用 run-as（如果外部存储不可用）
adb shell
run-as com.example.aiwa_app
ls files/aiwa/offline_out/
```

## 🎯 与 aiwa_runner 对比

| 特性 | aiwa_app（新） | aiwa_runner |
|------|----------------|-------------|
| 自动导出 | ✅ | ✅ |
| 导出位置 | `files/export/` | `files/export/` |
| 完整流程 | 视频 → 分析 → 导出 | 帧 → 分析 → 导出 |
| 降级模式 | 支持 | 不支持 |

---

**实现日期**：2024-10-31  
**版本**：v1.1  
**参考**：`aiwa_runner/lib/runner_orchestrator.dart` (第 342-359 行)

