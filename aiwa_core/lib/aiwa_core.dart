// aiwa_core/lib/aiwa_core.dart
//
// 统一导出 - 核心库公共 API
//
// 使用方式：
//   import 'package:aiwa_core/aiwa_core.dart';
//
// 这将导入核心库的 80% 常用功能，包括：
// - 核心工具（错误、角度、平滑、舍入）
// - 姿态检测抽象（接口、关键点命名、序列化）
// - 分析管线（离线分析、质量评估、计数）
// - 结果模型（Schema、读取、验证）
// - 规则解析（YAML 规则加载）
//
// 如果需要更细粒度的控制，可以继续使用分散导入：
//   import 'package:aiwa_core/core/errors.dart';
//   import 'package:aiwa_core/pipeline/quality.dart';

library aiwa_core;

// ============================================================================
// Core - 核心工具
// ============================================================================
export 'core/errors.dart';
export 'core/rounding.dart';
export 'core/one_euro.dart';
export 'core/angles.dart';
export 'core/perf_timer.dart';

// ============================================================================
// Pose - 姿态检测抽象
// ============================================================================
export 'pose/pose_engine.dart';
export 'pose/keypoint_names.dart';
export 'pose/frame_streamer.dart';
export 'pose/neutral_keypoint_series.dart';
export 'pose/keypoint_smoother.dart';

// ============================================================================
// Pipeline - 分析管线
// ============================================================================
export 'pipeline/offline_pipeline.dart';
export 'pipeline/pose_input_converter.dart';
export 'pipeline/pose_series.dart';
export 'pipeline/quality.dart';
export 'pipeline/counting.dart';
export 'pipeline/phases.dart';

// ============================================================================
// Result - 结果模型与读取
// ============================================================================
export 'result/result_schema.dart';
export 'result/result_reader.dart';
export 'result/csv_export.dart';

// ============================================================================
// Spec - 规则与配置
// ============================================================================
export 'spec/rule_models.dart';
export 'spec/rule_parser.dart';
export 'spec/rule_schema.dart';

