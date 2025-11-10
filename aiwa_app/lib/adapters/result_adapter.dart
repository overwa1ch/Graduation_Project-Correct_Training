// result_adapter.dart
// Version: v3.0
// Purpose: 将标准结果模型映射为 UI 轻量模型
//
// ✅ 重构说明：
// - Schema 验证移至 aiwa_core/result/result_reader.dart
// - JSON 读取移至 aiwa_core/result/result_reader.dart
// - 本文件只负责 UI 特定的轻量映射
// - 消除约 300 行重复代码
//
// 迁移指南：
// ```dart
// // 旧方式（已废弃）
// final raw = await readResultJson(sessionRoot);  // 本地实现
// assertResultContract(raw);                      // 本地验证
// final lite = mapToLite(raw);                    // 本地映射
//
// // 新方式（推荐）
// import 'package:aiwa_core/result/result_reader.dart';
// final result = await readResultJson(sessionRoot);  // 核心层读取+验证
// final lite = toLite(result);                       // UI 轻量映射
// ```

import 'package:aiwa_core/aiwa_core.dart';

// ============================================================================
// UI 轻量模型（仅用于前端展示）
// ============================================================================

/// 分析结果轻量模型（映射自标准模型 AnalysisResult）
///
/// 字段映射规则（参见 docs/protocols/ui_contracts.md）：
/// - posture ← scores.form (姿势得分)
/// - stability ← scores.stability (稳定性得分)
/// - rhythm ← scores.tempo (节奏得分)
/// - total ← scores.overall (综合得分)
/// - reps ← repCount (动作次数)
/// - attempts ← attemptsCount (总尝试次数)
/// - evidencePath ← evidence[0].snapshotPath (证据快照路径，可能为 null)
///
/// 所有分数范围：0..100（部分结果时可为 null）
class AnalysisResultLite {
  /// 姿势得分 (0..100) ← scores.form（部分结果时可为 null）
  final int? posture;

  /// 稳定性得分 (0..100) ← scores.stability（部分结果时可为 null）
  final int? stability;

  /// 节奏得分 (0..100) ← scores.tempo（部分结果时可为 null）
  final int? rhythm;

  /// 综合得分 (0..100) ← scores.overall（部分结果时可为 null）
  final int? total;

  /// 动作次数 (>=0) ← repCount
  final int reps;

  /// 检测到的总尝试次数 (>=0) ← attemptsCount
  final int attempts;

  /// 证据快照路径（相对于 sessionRoot）← evidence[0].snapshotPath
  /// 可能为 null（证据缺失或降级）
  final String? evidencePath;

  // 可选：质量指标（用于 UI 提示）
  /// 低置信度标记 ← quality.lowConfidence
  final bool lowConfidence;

  /// 覆盖率 (0..1) ← quality.coverage
  final double coverage;

  // 可选：元信息（用于追踪环境）
  /// 动作模板名称 ← meta.template
  final String templateName;

  /// 严格度 ← meta.strictness
  final String strictness;

  /// 推理引擎 ← meta.engine
  final String? engine;

  /// 视频帧率 ← meta.fps
  final int fps;

  // 新增：降级标记
  /// 是否为部分结果（降级模式）
  final bool isPartial;

  /// 部分结果失败信息
  final PartialFailureInfo? partialFailure;

  /// 动作反馈（尝试明细与改进建议）
  final AttemptFeedbackLite? attemptFeedback;

  const AnalysisResultLite({
    required this.posture,
    required this.stability,
    required this.rhythm,
    required this.total,
    required this.reps,
    required this.attempts,
    required this.evidencePath,
    required this.lowConfidence,
    required this.coverage,
    required this.templateName,
    required this.strictness,
    this.engine,
    required this.fps,
    this.isPartial = false,
    this.partialFailure,
    this.attemptFeedback,
  });

  @override
  String toString() {
    return 'AnalysisResultLite('
        'posture=$posture, stability=$stability, rhythm=$rhythm, '
        'total=$total, reps=$reps, attempts=$attempts, partial=$isPartial, evidencePath=$evidencePath)';
  }
}

/// 尝试反馈摘要（用于 UI 展示 Coaching 建议）
class AttemptFeedbackLite {
  final String mode;
  final int total;
  final int qualified;
  final int unqualified;
  final double? avgAngle;
  final double? targetAngle;
  final double? detectionThreshold;
  final List<String> suggestions;

  const AttemptFeedbackLite({
    required this.mode,
    required this.total,
    required this.qualified,
    required this.unqualified,
    this.avgAngle,
    this.targetAngle,
    this.detectionThreshold,
    this.suggestions = const <String>[],
  });
}

/// 部分结果失败信息
class PartialFailureInfo {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const PartialFailureInfo({
    required this.code,
    required this.message,
    required this.details,
  });

  @override
  String toString() => 'PartialFailureInfo(code=$code, message=$message)';
}

// ============================================================================
// 映射函数：AnalysisResult → AnalysisResultLite
// ============================================================================

/// 将标准结果模型映射为 UI 轻量模型
///
/// 参数：
/// - [result]: 标准结果模型（从 aiwa_core 读取并验证）
///
/// 返回：
/// - [AnalysisResultLite]: UI 轻量模型
///
/// 注意：
/// - 分数自动从浮点数转换为整数（使用 round1）
/// - coverage 已在标准模型中截断到 [0,1]
/// - evidencePath 保持原始相对路径（不拼接 sessionRoot）
AnalysisResultLite toLite(AnalysisResult result) {
  // 映射分数（已在 Scores 类中处理精度控制）
  final intScores = result.scores.toIntScores();

  // 解析证据路径（可能为 null）
  final evidencePath = _resolveSnapshotPath(result);

  // 解析部分结果失败信息
  PartialFailureInfo? partialFailure;
  if (result.partial && result.partialReason != null) {
    final reason = result.partialReason!;
    partialFailure = PartialFailureInfo(
      code: reason.code,
      message: reason.message,
      details: reason.details,
    );
  }

  // 解析反馈
  AttemptFeedbackLite? attemptFeedback;
  if (result.feedback != null) {
    final feedback = result.feedback!;
    attemptFeedback = AttemptFeedbackLite(
      mode: feedback.mode,
      total: feedback.attempts.total,
      qualified: feedback.attempts.qualified,
      unqualified: feedback.attempts.unqualified,
      avgAngle: feedback.avgAngle,
      targetAngle: feedback.targetAngle,
      detectionThreshold: feedback.detectionThreshold,
      suggestions: feedback.suggestions,
    );
  }

  return AnalysisResultLite(
    posture: intScores.form,
    stability: intScores.stability,
    rhythm: intScores.tempo,
    total: intScores.overall,
    reps: result.repCount,
    attempts: result.attemptsCount,
    evidencePath: evidencePath,
    lowConfidence: result.quality.lowConfidence,
    coverage: result.quality.coverage,
    templateName: result.meta.template,
    strictness: result.meta.strictness,
    engine: result.meta.engine,
    fps: result.meta.fps.round(),
    isPartial: result.partial,
    partialFailure: partialFailure,
    attemptFeedback: attemptFeedback,
  );
}

// ============================================================================
// 内部辅助函数
// ============================================================================

/// 解析证据快照路径（内部辅助）
String? _resolveSnapshotPath(AnalysisResult result) {
  if (result.evidence.isEmpty) {
    return null;
  }

  final first = result.evidence.first;
  final snapshot = first.snapshotPath;

  if (snapshot == null || snapshot.trim().isEmpty) {
    return null;
  }

  return snapshot.trim();
}
