// result_adapter.dart
// Version: v2.0
// Purpose: 解析 CLI 输出的 result.json 并映射为 UI 轻量模型
//
// 契约依据：
// - docs/protocols/schemas/analysis_result_v2.schema.json (CLI 输出结构)
// - docs/protocols/ui_contracts.md (字段映射规则: form→posture, tempo→rhythm)
// - docs/protocols/artifacts_layout.md (产物目录结构)
//
// 职责：
// 1. 读取 ${sessionRoot}/result.json
// 2. 校验关键字段（scores.*, repCount, meta）
// 3. 映射为 AnalysisResultLite（UI 轻量模型）
// 4. 证据降级策略（优先 snapshotPath，次选 window）
//
// 非职责：
// - 不负责事件订阅
// - 不负责 UI 展示
// - 不负责 CLI 调用
//
// 使用示例：
// ```dart
// try {
//   final raw = await readResultJson(sessionRoot);
//   assertResultContract(raw);
//   final lite = mapToLite(raw);
//   print('总分: ${lite.total}, 次数: ${lite.reps}');
// } on SchemaMismatch catch (e) {
//   print('契约违反: $e');
// } on ResultReadException catch (e) {
//   print('读取失败: $e');
// }
// ```

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

// ============================================================================
// 异常类型（契约违反/读取错误）
// ============================================================================

/// Schema 契约违反异常（字段缺失/类型错误/越界）
class SchemaMismatch implements Exception {
  final String message;

  SchemaMismatch(this.message);

  @override
  String toString() => 'SchemaMismatch($message)';
}

/// result.json 读取异常（文件缺失/解析失败）
class ResultReadException implements Exception {
  final String message;
  final Object? cause;

  ResultReadException(this.message, {this.cause});

  @override
  String toString() => 'ResultReadException($message, cause=$cause)';
}

// ============================================================================
// UI 轻量模型
// ============================================================================

/// 分析结果轻量模型（映射自 CLI result.json）
///
/// 字段映射规则（参见 docs/protocols/ui_contracts.md）：
/// - posture ← scores.form (姿势得分)
/// - stability ← scores.stability (稳定性得分)
/// - rhythm ← scores.tempo (节奏得分)
/// - total ← scores.overall (综合得分)
/// - reps ← repCount (动作次数)
/// - evidencePath ← evidence[0].snapshotPath (证据快照路径，可能为 null)
///
/// 所有分数范围：0..100
class AnalysisResultLite {
  /// 姿势得分 (0..100) ← scores.form
  final int posture;

  /// 稳定性得分 (0..100) ← scores.stability
  final int stability;

  /// 节奏得分 (0..100) ← scores.tempo
  final int rhythm;

  /// 综合得分 (0..100) ← scores.overall
  final int total;

  /// 动作次数 (>=0) ← repCount
  final int reps;

  /// 证据快照路径（相对于 sessionRoot）← evidence[0].snapshotPath
  /// 可能为 null（证据缺失或降级）
  final String? evidencePath;

  // 可选：质量指标（用于 UI 提示）
  /// 低置信度标记 ← quality.lowConfidence
  final bool? lowConfidence;

  /// 覆盖率 (0..1) ← quality.coverage
  final double? coverage;

  // 可选：元信息（用于追踪环境）
  /// 动作模板名称 ← meta.template
  final String? templateName;

  /// 严格度 ← meta.strictness
  final String? strictness;

  /// 推理引擎 ← meta.engine
  final String? engine;

  /// 视频帧率 ← meta.fps
  final int? fps;

  const AnalysisResultLite({
    required this.posture,
    required this.stability,
    required this.rhythm,
    required this.total,
    required this.reps,
    required this.evidencePath,
    this.lowConfidence,
    this.coverage,
    this.templateName,
    this.strictness,
    this.engine,
    this.fps,
  });

  @override
  String toString() {
    return 'AnalysisResultLite('
        'posture=$posture, stability=$stability, rhythm=$rhythm, '
        'total=$total, reps=$reps, evidencePath=$evidencePath)';
  }
}

// ============================================================================
// 公开接口 1: 读取 result.json
// ============================================================================

/// 读取并解析 result.json（相对于 sessionRoot）
///
/// 参数:
/// - [sessionRoot]: 会话根目录（例如: "build/offline_out/20251028_101320_7f2c"）
///
/// 返回: 原始 Map（未映射）
///
/// 异常:
/// - [ResultReadException] 文件不存在或 JSON 解析失败
///
/// 契约:
/// - 文件路径: ${sessionRoot}/result.json
/// - 编码: UTF-8
/// - 格式: JSON 对象
Future<Map<String, dynamic>> readResultJson(String sessionRoot) async {
  final filePath = '$sessionRoot/result.json';
  final file = File(filePath);

  // 检查文件是否存在
  if (!await file.exists()) {
    throw ResultReadException('result.json not found at: $filePath');
  }

  try {
    // 读取并解析 JSON（UTF-8）
    final content = await file.readAsString(encoding: utf8);
    final json = jsonDecode(content);

    if (json is! Map<String, dynamic>) {
      throw ResultReadException('result.json is not a JSON object');
    }

    return json;
  } on ResultReadException {
    rethrow; // 不要包装我们自己的异常
  } on FormatException catch (e) {
    throw ResultReadException('json parse failed', cause: e);
  } catch (e) {
    throw ResultReadException('failed to read result.json', cause: e);
  }
}

// ============================================================================
// 公开接口 2: 契约校验
// ============================================================================

/// 校验 result.json 的关键字段（契约断言）
///
/// 必填字段（参见 docs/protocols/schemas/analysis_result_v2.schema.json）：
/// - scores.form (int, 0..100)
/// - scores.stability (int, 0..100)
/// - scores.tempo (int, 0..100)
/// - scores.overall (int, 0..100)
/// - repCount (int, >=0)
/// - meta (object, 必须存在)
///
/// 异常:
/// - [SchemaMismatch] 字段缺失、类型错误、越界
///
/// 注意:
/// - meta.* 子字段缺失视为警告（不抛错）
/// - evidence 数组可为空或缺失（不抛错）
/// - quality.* 子字段可缺失（不抛错）
void assertResultContract(Map<String, dynamic> raw) {
  // 1. 检查 scores 对象
  if (!raw.containsKey('scores') || raw['scores'] is! Map) {
    throw SchemaMismatch('scores object missing or invalid');
  }

  final scores = raw['scores'] as Map<String, dynamic>;

  // 2. 检查 scores 四个子字段
  final scoreFields = ['form', 'stability', 'tempo', 'overall'];
  for (final field in scoreFields) {
    if (!scores.containsKey(field)) {
      throw SchemaMismatch('scores.$field missing');
    }

    final value = scores[field];
    if (value is! num) {
      throw SchemaMismatch('scores.$field must be number, got: ${value.runtimeType}');
    }

    // 检查 NaN/Infinity
    if (value.isNaN || value.isInfinite) {
      throw SchemaMismatch('scores.$field is NaN or Infinity');
    }

    // 检查范围 0..100
    if (value < 0 || value > 100) {
      throw SchemaMismatch('scores.$field out of range [0,100]: $value');
    }
  }

  // 3. 检查 repCount
  if (!raw.containsKey('repCount')) {
    throw SchemaMismatch('repCount missing');
  }

  final repCount = raw['repCount'];
  if (repCount is! num) {
    throw SchemaMismatch('repCount must be number, got: ${repCount.runtimeType}');
  }

  if (repCount.isNaN || repCount.isInfinite) {
    throw SchemaMismatch('repCount is NaN or Infinity');
  }

  if (repCount < 0) {
    throw SchemaMismatch('repCount must be non-negative: $repCount');
  }

  // 4. 检查 meta 对象（必须存在，但子字段可缺失）
  if (!raw.containsKey('meta') || raw['meta'] is! Map) {
    throw SchemaMismatch('meta object missing or invalid');
  }

  // 注意：meta.* 子字段缺失不抛错（仅警告），这里不做额外检查
  // evidence、quality 可选，不检查
}

// ============================================================================
// 公开接口 3: 映射为轻量模型
// ============================================================================

/// 将原始 Map 映射为 UI 轻量模型
///
/// 字段映射（参见 docs/protocols/ui_contracts.md）：
/// - posture ← scores.form
/// - stability ← scores.stability
/// - rhythm ← scores.tempo
/// - total ← scores.overall
/// - reps ← repCount
/// - evidencePath ← evidence[0].snapshotPath
///
/// 参数:
/// - [raw]: 原始 result.json Map（已通过 assertResultContract）
///
/// 返回: AnalysisResultLite 实例
///
/// 注意:
/// - 分数若为浮点数，使用 round() 取整
/// - coverage 若存在，截断到 [0,1] 区间
/// - evidencePath 保持原始相对路径（不拼接 sessionRoot）
AnalysisResultLite mapToLite(Map<String, dynamic> raw) {
  final scores = raw['scores'] as Map<String, dynamic>;

  // 映射分数（round 取整）
  final posture = (scores['form'] as num).round();
  final stability = (scores['stability'] as num).round();
  final rhythm = (scores['tempo'] as num).round();
  final total = (scores['overall'] as num).round();

  // 映射次数（round 取整）
  final reps = (raw['repCount'] as num).round();

  // 解析证据路径（可能为 null）
  final evidencePath = _extractEvidencePath(raw);

  // 解析质量指标（可选）
  bool? lowConfidence;
  double? coverage;

  if (raw.containsKey('quality') && raw['quality'] is Map) {
    final quality = raw['quality'] as Map<String, dynamic>;

    if (quality.containsKey('lowConfidence') && quality['lowConfidence'] is bool) {
      lowConfidence = quality['lowConfidence'] as bool;
    }

    if (quality.containsKey('coverage') && quality['coverage'] is num) {
      final rawCoverage = (quality['coverage'] as num).toDouble();
      // 截断到 [0,1]
      coverage = math.max(0.0, math.min(1.0, rawCoverage));
    }
  }

  // 解析元信息（可选）
  String? templateName;
  String? strictness;
  String? engine;
  int? fps;

  if (raw.containsKey('meta') && raw['meta'] is Map) {
    final meta = raw['meta'] as Map<String, dynamic>;

    if (meta.containsKey('template') && meta['template'] is String) {
      templateName = meta['template'] as String;
    }

    if (meta.containsKey('strictness') && meta['strictness'] is String) {
      strictness = meta['strictness'] as String;
    }

    if (meta.containsKey('engine') && meta['engine'] is String) {
      engine = meta['engine'] as String;
    }

    if (meta.containsKey('fps') && meta['fps'] is num) {
      fps = (meta['fps'] as num).round();
    }
  }

  return AnalysisResultLite(
    posture: posture,
    stability: stability,
    rhythm: rhythm,
    total: total,
    reps: reps,
    evidencePath: evidencePath,
    lowConfidence: lowConfidence,
    coverage: coverage,
    templateName: templateName,
    strictness: strictness,
    engine: engine,
    fps: fps,
  );
}

// ============================================================================
// 私有辅助函数：提取证据路径
// ============================================================================

/// 从 evidence 数组中提取第一个快照路径
///
/// 规则（证据降级策略）：
/// - 若 evidence 缺失或为空 → null
/// - 若 evidence[0].snapshotPath 为空/全空白 → null
/// - 否则返回 snapshotPath（保持原始相对路径）
String? _extractEvidencePath(Map<String, dynamic> raw) {
  if (!raw.containsKey('evidence') || raw['evidence'] is! List) {
    return null;
  }

  final evidence = raw['evidence'] as List;
  if (evidence.isEmpty) {
    return null;
  }

  final first = evidence[0];
  if (first is! Map) {
    return null;
  }

  final snapshot = first['snapshotPath'];
  if (snapshot is! String || snapshot.trim().isEmpty) {
    return null;
  }

  return snapshot;
}

