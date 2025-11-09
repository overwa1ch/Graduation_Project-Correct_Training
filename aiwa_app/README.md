# AIWA App

AIWA（AI Workout Assistant）移动端应用，基于 Flutter 构建的健身姿态纠正应用。

## 功能特性

- 🎥 **视频录制与分析**：支持录制或选择视频进行姿态分析
- 🤖 **多引擎支持**：支持 ML Kit、MoveNet Lightning/Thunder 等多种姿态识别引擎
- 📊 **实时反馈**：提供姿态评分、稳定性、节奏等分析结果
- 📱 **离线分析**：支持本地离线姿态分析，无需网络连接
- ☁️ **云端扩展**：可选云端增强分析（需后端服务支持）
- 🎨 **主题系统**：基于 Figma Variables 的设计系统

## 技术栈

- **框架**：Flutter 3.4+
- **姿态识别**：
  - Google ML Kit Pose Detection（33 关键点）
  - MoveNet Lightning/Thunder（17 关键点，TensorFlow Lite）
- **核心库**：`aiwa_core`（本地 Dart 包，提供离线分析管道）
- **设计系统**：基于 Figma Variables 的 Token 系统

## 快速开始

### 前置要求

- Flutter SDK ≥ 3.4
- Dart SDK ≥ 3.4.0
- Android Studio / Xcode（用于移动端构建）

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 开发模式
flutter run

# 指定设备
flutter run -d <device_id>
```

### 构建

```bash
# Android APK
flutter build apk

# iOS（需 macOS 环境）
flutter build ios

# Web（可选）
flutter build web
```

## 项目结构

```
aiwa_app/
├── lib/
│   ├── main.dart              # 应用入口与路由守卫
│   ├── ui/                    # UI 层
│   │   ├── pages/            # 页面（登录、主页、相机、设置等）
│   │   └── widgets/           # 复用组件
│   ├── services/             # 服务层
│   │   ├── video_analysis_service.dart    # 视频分析服务
│   │   ├── auth_state.dart                 # 认证状态管理
│   │   └── ...
│   ├── pose/                 # 姿态识别引擎
│   │   ├── pose_engine.dart               # 引擎接口
│   │   ├── mlkit_pose_engine.dart         # ML Kit 实现
│   │   └── movenet_pose_engine.dart      # MoveNet 实现
│   ├── adapters/             # 适配器（结果解析、证据解析等）
│   ├── config/               # 配置管理
│   └── theme/                # 主题系统（基于 Figma Tokens）
├── assets/
│   ├── models/               # 模型文件（MoveNet .tflite）
│   ├── rules/                # 规则文件（squat.v1.json）
│   ├── config/               # 配置文件
│   └── tokens/               # 设计 Tokens（从 Figma 同步）
├── test/                      # 测试文件
└── tool/                      # 工具脚本
```

## 配置

### 推理引擎选择

应用支持通过设置页面或配置文件选择推理引擎：

- **MLKit**：Google ML Kit（33 关键点，高精度）
- **MoveNet**：MoveNet Lightning（17 关键点，快速）
- **MoveNet-Thunder**：MoveNet Thunder（17 关键点，高精度）

配置文件位置：
- **Windows**: `%LOCALAPPDATA%\aiwa\configs\app_runtime.json`
- **macOS**: `~/Library/Application Support/aiwa/configs/app_runtime.json`
- **Linux**: `~/.local/share/aiwa/configs/app_runtime.json`

### MoveNet 模型下载

如需使用 MoveNet 引擎，需要下载模型文件：

```bash
# MoveNet Lightning（推荐）
curl -L -o assets/models/movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/int8/4.tflite

# MoveNet Thunder（可选，更高精度）
curl -L -o assets/models/movenet_thunder.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/int8/4.tflite
```

详细说明请参考：[MoveNet 快速开始指南](../docs/03-guides/movenet_quick_start.md)

## 测试

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 检查覆盖率阈值
dart tool/check_coverage.dart
```

## 开发工具

```bash
# 同步 Figma Tokens
dart tool/sync_tokens.dart

# 生成性能报告
dart tool/generate_perf_report.dart
```

## 相关文档

- [项目文档中心](../docs/README.md)
- [快速开始指南](../docs/03-guides/QUICK_START.md)
- [MoveNet 实现文档](../docs/04-reports/movenet_implementation.md)
- [主题系统设计](../docs/01-design/theme_system.md)

## 许可证

本项目为毕业设计项目，仅供学习研究使用。
