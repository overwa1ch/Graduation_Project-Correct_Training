# Services 目录结构说明

本文档说明 `aiwa_app/lib/services/` 目录的分类组织方式，便于后续维护和扩展。

## 📁 目录结构

```
services/
├── auth/                    # 🔐 认证与 API
├── analysis/                # 🎬 视频分析核心
├── native/                  # 📱 原生平台集成
├── visualization/           # 🎨 可视化与渲染
├── config/                  # ⚙️ 配置管理
├── storage/                 # 💾 存储与会话
└── utils/                   # 🛠️ 工具类
```

---

## 📂 各子目录说明

### 1. `auth/` - 认证与 API

**职责**: 处理用户认证、API 通信和全局认证状态管理

**文件列表**:
- `auth_state.dart` - 全局认证状态管理（ChangeNotifier 单例）
- `auth_service.dart` - 登录/注册/刷新 Token 业务逻辑
- `api_client.dart` - HTTP 客户端封装（请求/响应处理）

**使用场景**:
- 用户登录/注册流程
- Token 刷新与过期处理
- 全局认证状态监听

**导入示例**:
```dart
import 'package:aiwa_app/services/auth/auth_state.dart';
import 'package:aiwa_app/services/auth/auth_service.dart';
```

---

### 2. `analysis/` - 视频分析核心

**职责**: 视频分析流程的核心服务，包括帧提取、姿态检测、分析管道和会话管理

**文件列表**:
- `video_analysis_service.dart` - 主分析服务（帧提取→姿态检测→管道分析）
- `analysis_session_manager.dart` - 分析会话状态管理（防止并发分析）
- `analysis_history.dart` - 分析历史记录 CRUD
- `event_bus.dart` - 分析事件流（JSONL/CLI/Isolate 三种事件源）

**使用场景**:
- 视频分析任务启动与监控
- 分析进度与状态广播
- 历史记录查询与管理
- 事件流处理（START/PROGRESS/DONE/ERROR）

**导入示例**:
```dart
import 'package:aiwa_app/services/analysis/video_analysis_service.dart';
import 'package:aiwa_app/services/analysis/analysis_session_manager.dart';
import 'package:aiwa_app/services/analysis/analysis_history.dart';
import 'package:aiwa_app/services/analysis/event_bus.dart';
```

---

### 3. `native/` - 原生平台集成

**职责**: 通过 Platform Channels 调用 Android/iOS 原生能力

**文件列表**:
- `native_frame_extractor.dart` - 原生帧提取器（MediaMetadataRetriever/AVFoundation）
- `native_video_encoder.dart` - 原生视频编码器（用于覆盖层视频生成）

**使用场景**:
- 视频帧提取（性能优化）
- 视频编码（覆盖层生成）

**导入示例**:
```dart
import 'package:aiwa_app/services/native/native_frame_extractor.dart';
import 'package:aiwa_app/services/native/native_video_encoder.dart';
```

---

### 4. `visualization/` - 可视化与渲染

**职责**: 关键点可视化、骨架绘制和覆盖层视频生成

**文件列表**:
- `keypoint_overlay_generator.dart` - 关键点覆盖视频生成器
- `keypoint_skeleton.dart` - 关键点骨架绘制工具

**使用场景**:
- 生成带关键点标注的视频
- 实时骨架绘制（相机预览）
- 分析结果可视化

**导入示例**:
```dart
import 'package:aiwa_app/services/visualization/keypoint_overlay_generator.dart';
import 'package:aiwa_app/services/visualization/keypoint_skeleton.dart';
```

---

### 5. `config/` - 配置管理

**职责**: 规则配置同步（云端↔本地）

**文件列表**:
- `config_sync.dart` - 配置同步服务（下载/缓存/验证）

**使用场景**:
- 从云端下载最新规则配置
- 本地配置缓存管理
- 配置版本验证

**导入示例**:
```dart
import 'package:aiwa_app/services/config/config_sync.dart';
```

---

### 6. `storage/` - 存储与会话

**职责**: 会话目录管理和文件系统操作

**文件列表**:
- `session_manager.dart` - 会话目录管理（创建/清理/列表）

**使用场景**:
- 创建唯一会话目录
- 清理过期会话
- 列出所有会话

**导入示例**:
```dart
import 'package:aiwa_app/services/storage/session_manager.dart';
```

---

### 7. `utils/` - 工具类

**职责**: 通用工具类和辅助服务

**文件列表**:
- `cancellation_token.dart` - 取消令牌（异步任务取消）
- `diagnostics_logger.dart` - 诊断日志（JSON Lines 格式）
- `support_bundle.dart` - 支持包生成（调试用）

**使用场景**:
- 异步任务取消控制
- 诊断日志记录
- 调试信息收集

**导入示例**:
```dart
import 'package:aiwa_app/services/utils/cancellation_token.dart';
import 'package:aiwa_app/services/utils/diagnostics_logger.dart';
import 'package:aiwa_app/services/utils/support_bundle.dart';
```

---

## 🔄 分类原则

### 1. **按功能领域划分**
- 每个子目录代表一个独立的功能领域
- 相关服务聚合在同一目录，便于维护

### 2. **避免循环依赖**
- `auth/` 独立于其他模块
- `utils/` 被其他模块依赖，但不依赖其他服务
- `analysis/` 可能依赖 `native/`、`visualization/`、`config/`

### 3. **清晰的职责边界**
- **auth**: 认证与 API 通信
- **analysis**: 分析流程核心
- **native**: 平台特定能力
- **visualization**: 可视化渲染
- **config**: 配置管理
- **storage**: 文件系统操作
- **utils**: 通用工具

---

## 📝 添加新服务的指南

### 判断新服务应归属的目录

1. **认证相关** → `auth/`
   - 用户认证、Token 管理、API 客户端

2. **分析流程** → `analysis/`
   - 视频处理、姿态检测、分析管道、事件流

3. **平台集成** → `native/`
   - Platform Channels、原生能力调用

4. **可视化** → `visualization/`
   - 渲染、绘制、视频生成

5. **配置** → `config/`
   - 规则配置、参数管理

6. **存储** → `storage/`
   - 文件操作、目录管理

7. **工具类** → `utils/`
   - 通用工具、辅助函数

### 示例：添加新服务

假设要添加一个 `video_metadata_service.dart`（视频元数据提取）：

**判断**: 视频元数据提取属于**分析流程**的一部分，应放在 `analysis/`

**操作**:
1. 创建文件: `analysis/video_metadata_service.dart`
2. 更新导入: `import 'package:aiwa_app/services/analysis/video_metadata_service.dart';`
3. 更新本文档（如需要）

---

## 🔍 依赖关系图

```
auth/
  └── (独立，不依赖其他服务)

analysis/
  ├── → native/ (使用原生帧提取)
  ├── → visualization/ (生成覆盖层)
  ├── → config/ (读取规则配置)
  └── → utils/ (使用取消令牌)

native/
  └── → utils/ (使用取消令牌)

visualization/
  ├── → native/ (使用视频编码器)
  └── (独立)

config/
  └── (独立)

storage/
  └── (独立)

utils/
  └── (独立，被其他模块依赖)
```

---

## 📅 迁移历史

- **2025-11-09**: 完成首次分类迁移
  - 从扁平结构迁移到功能分类结构
  - 更新所有导入路径（14+ 个文件）
  - 创建本文档

---

## ✅ 验证

迁移完成后，运行以下命令验证：

```bash
flutter analyze
```

确保所有导入路径正确，无编译错误。

