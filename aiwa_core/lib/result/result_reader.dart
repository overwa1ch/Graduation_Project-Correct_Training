// lib/result/result_reader.dart
//
// 分析结果读取与验证工具
//
// 职责：
// - 从文件读取 result.json
// - 验证关键字段（schema 校验）
// - 解析为标准模型（AnalysisResult）
// - 统一异常处理

import 'dart:convert';
import 'dart:io';

import '../core/errors.dart';
import 'result_schema.dart';

/// 从会话目录读取 result.json
/// 
/// 参数：
/// - [sessionRoot]: 会话根目录（例如：build/offline_out/20251028_101320_7f2c）
/// 
/// 返回：
/// - [AnalysisResult]: 标准结果模型
/// 
/// 异常：
/// - [DataFormatError]: 文件不存在或 JSON 格式错误
/// - [SchemaValidationError]: 字段缺失或类型错误
Future<AnalysisResult> readResultJson(String sessionRoot) async {
  final filePath = '$sessionRoot/result.json';
  final file = File(filePath);

  // 检查文件是否存在
  if (!await file.exists()) {
    throw DataFormatError('result.json not found at: $filePath');
  }

  try {
    // 读取并解析 JSON
    final content = await file.readAsString(encoding: utf8);
    final json = jsonDecode(content);

    if (json is! Map<String, dynamic>) {
      throw DataFormatError('result.json is not a JSON object at: $filePath');
    }

    // 验证关键字段
    validateResultSchema(json);

    // 解析为标准模型
    return AnalysisResult.fromJson(json);
  } on DataFormatError {
    rethrow;
  } on SchemaValidationError {
    rethrow;
  } on FormatException catch (e) {
    throw DataFormatError('JSON parse failed at $filePath: $e');
  } catch (e) {
    throw DataFormatError('Failed to read result.json at $filePath: $e');
  }
}

/// 验证 result.json 的关键字段（schema 校验）
/// 
/// 必填字段：
/// - scores (object): 包含 form, stability, tempo, overall
/// - repCount (number, >=0)
/// - meta (object): 包含 template, fps, ruleVersion, strictness
/// - quality (object): 包含 coverage, lowConfidence
/// 
/// 部分结果时：
/// - scores 可为 null
/// - 必须有 partialReason
/// 
/// 异常：
/// - [SchemaValidationError]: 字段缺失、类型错误、越界
void validateResultSchema(Map<String, dynamic> json) {
  final isPartial = json['partial'] == true;

  // 1. 检查 scores 对象
  if (!json.containsKey('scores') || json['scores'] is! Map) {
    throw SchemaValidationError('scores object missing or invalid');
  }

  final scores = json['scores'] as Map<String, dynamic>;

  // 2. 检查 scores 四个子字段
  const scoreFields = ['form', 'stability', 'tempo', 'overall'];
  
  for (final field in scoreFields) {
    if (!scores.containsKey(field)) {
      throw SchemaValidationError('scores.$field missing');
    }

    final value = scores[field];

    // 部分结果允许 null
    if (isPartial && value == null) {
      continue;
    }

    if (value is! num) {
      throw SchemaValidationError(
        'scores.$field must be number${isPartial ? ' or null' : ''}, got: ${value.runtimeType}',
      );
    }

    // 检查 NaN/Infinity
    if (value.isNaN || value.isInfinite) {
      throw SchemaValidationError('scores.$field is NaN or Infinity');
    }

    // 检查范围 0..100
    if (value < 0 || value > 100) {
      throw SchemaValidationError('scores.$field out of range [0,100]: $value');
    }
  }

  // 3. 检查 repCount
  if (!json.containsKey('repCount')) {
    throw SchemaValidationError('repCount missing');
  }

  final repCount = json['repCount'];
  if (repCount is! num) {
    throw SchemaValidationError('repCount must be number, got: ${repCount.runtimeType}');
  }

  if (repCount.isNaN || repCount.isInfinite) {
    throw SchemaValidationError('repCount is NaN or Infinity');
  }

  if (repCount < 0) {
    throw SchemaValidationError('repCount must be non-negative: $repCount');
  }

  // 4. 检查 attemptsCount（可选）
  if (json.containsKey('attemptsCount')) {
    final attemptsCount = json['attemptsCount'];
    if (attemptsCount is! num) {
      throw SchemaValidationError('attemptsCount must be number, got: ${attemptsCount.runtimeType}');
    }
    if (attemptsCount.isNaN || attemptsCount.isInfinite) {
      throw SchemaValidationError('attemptsCount is NaN or Infinity');
    }
    if (attemptsCount < 0) {
      throw SchemaValidationError('attemptsCount must be non-negative: $attemptsCount');
    }
  }

  // 5. 检查 meta 对象（必须存在，但子字段可缺失）
  if (!json.containsKey('meta') || json['meta'] is! Map) {
    throw SchemaValidationError('meta object missing or invalid');
  }

  // 6. 检查 quality 对象（必须存在）
  if (!json.containsKey('quality') || json['quality'] is! Map) {
    throw SchemaValidationError('quality object missing or invalid');
  }

  // 7. 检查部分结果特定字段
  if (isPartial) {
    if (!json.containsKey('partialReason')) {
      throw SchemaValidationError('partial result must have partialReason');
    }
  }
}

/// 证据降级策略：解析快照路径
/// 
/// 规则：
/// - 若 evidence 缺失/空 → null
/// - 若 evidence[0].snapshotPath 为空/全空白 → null
/// - 否则返回 snapshotPath（保持原始相对路径）
/// 
/// 参数：
/// - [result]: 标准结果模型
/// 
/// 返回：
/// - 快照路径（相对于 sessionRoot）或 null
String? resolveSnapshotPath(AnalysisResult result) {
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

/// 证据降级策略：解析时间窗
/// 
/// 规则：
/// - 若 evidence 缺失/空 → null
/// - 若 evidence[0].window 缺失 → null
/// - 若 endMs <= startMs → null（非法窗口）
/// - 若 startMs < 0 → null（非法时间）
/// - 否则返回 (startMs, endMs)
/// 
/// 参数：
/// - [result]: 标准结果模型
/// 
/// 返回：
/// - 时间窗记录 (startMs, endMs) 或 null
({int startMs, int endMs})? resolveEvidenceWindow(AnalysisResult result) {
  if (result.evidence.isEmpty) {
    return null;
  }

  final first = result.evidence.first;
  final window = first.window;

  if (window == null) {
    return null;
  }

  // 校验合法性
  if (window.startMs < 0) {
    return null; // 时间不能为负
  }

  if (window.endMs <= window.startMs) {
    return null; // 结束时间必须大于开始时间
  }

  return window;
}

