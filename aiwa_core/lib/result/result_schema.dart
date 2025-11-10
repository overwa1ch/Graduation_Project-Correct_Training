// lib/result/result_schema.dart
//
// 标准分析结果模型 - 单一事实来源
//
// 契约定义：
// - 对应 OfflinePipeline.run() 输出的 resultJson 结构
// - 所有应用层和工具层统一使用此模型
// - 修改此模型等同于修改分析结果合约

import '../core/rounding.dart';

/// 分析结果完整模型
/// 
/// 对应 OfflinePipeline 输出的 result.json 结构
class AnalysisResult {
  /// 元信息
  final ResultMetadata meta;
  
  /// 质量指标
  final QualityMetrics quality;
  
  /// 合格次数（qualified reps）
  final int repCount;
  
  /// 总尝试次数（all attempts）
  final int attemptsCount;
  
  /// 动作次数明细
  final List<RepSummary> reps;
  
  /// 分数
  final Scores scores;
  
  /// 问题列表
  final List<Issue> issues;
  
  /// 证据列表（阶段、动作、问题）
  final List<Evidence> evidence;
  
  /// 反馈建议（可选）
  final Feedback? feedback;
  
  /// 部分结果标记（降级模式）
  final bool partial;
  
  /// 部分结果原因（仅当 partial=true 时存在）
  final PartialReason? partialReason;

  const AnalysisResult({
    required this.meta,
    required this.quality,
    required this.repCount,
    required this.attemptsCount,
    required this.reps,
    required this.scores,
    required this.issues,
    required this.evidence,
    this.feedback,
    this.partial = false,
    this.partialReason,
  });

  /// 从 JSON Map 解析
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      meta: ResultMetadata.fromJson(json['meta'] as Map<String, dynamic>),
      quality: QualityMetrics.fromJson(json['quality'] as Map<String, dynamic>),
      repCount: (json['repCount'] as num).toInt(),
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? (json['repCount'] as num).toInt(),
      reps: (json['reps'] as List?)
          ?.map((e) => RepSummary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      scores: Scores.fromJson(json['scores'] as Map<String, dynamic>),
      issues: (json['issues'] as List?)
          ?.map((e) => Issue.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      evidence: (json['evidence'] as List?)
          ?.map((e) => Evidence.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      feedback: json.containsKey('feedback')
          ? Feedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
      partial: json['partial'] == true,
      partialReason: json.containsKey('partialReason')
          ? PartialReason.fromJson(json['partialReason'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'quality': quality.toJson(),
      'repCount': repCount,
      'attemptsCount': attemptsCount,
      'reps': reps.map((e) => e.toJson()).toList(),
      'scores': scores.toJson(),
      'issues': issues.map((e) => e.toJson()).toList(),
      'evidence': evidence.map((e) => e.toJson()).toList(),
      if (feedback != null) 'feedback': feedback!.toJson(),
      if (partial) 'partial': true,
      if (partialReason != null) 'partialReason': partialReason!.toJson(),
    };
  }
}

/// 元信息
class ResultMetadata {
  final String template;
  final double fps;
  final String ruleVersion;
  final String strictness;
  final String? engine;
  final String? engineVersion;
  final String? inputResolution;
  final int? samplingStride;

  const ResultMetadata({
    required this.template,
    required this.fps,
    required this.ruleVersion,
    required this.strictness,
    this.engine,
    this.engineVersion,
    this.inputResolution,
    this.samplingStride,
  });

  factory ResultMetadata.fromJson(Map<String, dynamic> json) {
    return ResultMetadata(
      template: json['template'] as String,
      fps: (json['fps'] as num).toDouble(),
      ruleVersion: json['ruleVersion'] as String,
      strictness: json['strictness'] as String,
      engine: json['engine'] as String?,
      engineVersion: json['engineVersion'] as String?,
      inputResolution: json['inputResolution'] as String?,
      samplingStride: (json['samplingStride'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template': template,
      'fps': fps,
      'ruleVersion': ruleVersion,
      'strictness': strictness,
      if (engine != null) 'engine': engine,
      if (engineVersion != null) 'engineVersion': engineVersion,
      if (inputResolution != null) 'inputResolution': inputResolution,
      if (samplingStride != null) 'samplingStride': samplingStride,
    };
  }
}

/// 质量指标
class QualityMetrics {
  final double coverage;
  final bool lowConfidence;

  const QualityMetrics({
    required this.coverage,
    required this.lowConfidence,
  });

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      coverage: (json['coverage'] as num).toDouble(),
      lowConfidence: json['lowConfidence'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coverage': coverage,
      'lowConfidence': lowConfidence,
    };
  }
}

/// 分数
class Scores {
  final double? form;
  final double? stability;
  final double? tempo;
  final double? overall;

  const Scores({
    required this.form,
    required this.stability,
    required this.tempo,
    required this.overall,
  });

  factory Scores.fromJson(Map<String, dynamic> json) {
    return Scores(
      form: (json['form'] as num?)?.toDouble(),
      stability: (json['stability'] as num?)?.toDouble(),
      tempo: (json['tempo'] as num?)?.toDouble(),
      overall: (json['overall'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'form': form,
      'stability': stability,
      'tempo': tempo,
      'overall': overall,
    };
  }

  /// 转换为整数分数（UI 显示用）
  ({int? form, int? stability, int? tempo, int? overall}) toIntScores() {
    return (
      form: form != null ? round1(form!).round() : null,
      stability: stability != null ? round1(stability!).round() : null,
      tempo: tempo != null ? round1(tempo!).round() : null,
      overall: overall != null ? round1(overall!).round() : null,
    );
  }
}

/// 动作次数明细
class RepSummary {
  final int index;
  final int startMs;
  final int valleyMs;
  final int endMs;
  final bool qualified;
  final double valleyAngle;
  final double? kneeValleyAngle;
  final double? minKneeOutAngle;
  final double? maxForwardLean;
  final TempoMetrics? tempo;

  const RepSummary({
    required this.index,
    required this.startMs,
    required this.valleyMs,
    required this.endMs,
    required this.qualified,
    required this.valleyAngle,
    this.kneeValleyAngle,
    this.minKneeOutAngle,
    this.maxForwardLean,
    this.tempo,
  });

  factory RepSummary.fromJson(Map<String, dynamic> json) {
    return RepSummary(
      index: (json['index'] as num).toInt(),
      startMs: (json['startMs'] as num).toInt(),
      valleyMs: (json['valleyMs'] as num).toInt(),
      endMs: (json['endMs'] as num).toInt(),
      qualified: json['qualified'] as bool,
      valleyAngle: (json['valleyAngle'] as num).toDouble(),
      kneeValleyAngle: (json['kneeValleyAngle'] as num?)?.toDouble(),
      minKneeOutAngle: (json['minKneeOutAngle'] as num?)?.toDouble(),
      maxForwardLean: (json['maxForwardLean'] as num?)?.toDouble(),
      tempo: json.containsKey('tempo')
          ? TempoMetrics.fromJson(json['tempo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startMs': startMs,
      'valleyMs': valleyMs,
      'endMs': endMs,
      'qualified': qualified,
      'valleyAngle': valleyAngle,
      if (kneeValleyAngle != null) 'kneeValleyAngle': kneeValleyAngle,
      if (minKneeOutAngle != null) 'minKneeOutAngle': minKneeOutAngle,
      if (maxForwardLean != null) 'maxForwardLean': maxForwardLean,
      if (tempo != null) 'tempo': tempo!.toJson(),
    };
  }
}

/// 节奏指标
class TempoMetrics {
  final int eccentricMs;
  final int concentricMs;
  final double ratio;

  const TempoMetrics({
    required this.eccentricMs,
    required this.concentricMs,
    required this.ratio,
  });

  factory TempoMetrics.fromJson(Map<String, dynamic> json) {
    return TempoMetrics(
      eccentricMs: (json['eccentricMs'] as num).toInt(),
      concentricMs: (json['concentricMs'] as num).toInt(),
      ratio: (json['ratio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eccentricMs': eccentricMs,
      'concentricMs': concentricMs,
      'ratio': ratio,
    };
  }
}

/// 问题
class Issue {
  final String code;
  final String severity;
  final int count;
  final double? worstValue;

  const Issue({
    required this.code,
    required this.severity,
    required this.count,
    this.worstValue,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      code: json['code'] as String,
      severity: json['severity'] as String,
      count: (json['count'] as num).toInt(),
      worstValue: (json['worstValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'severity': severity,
      'count': count,
      if (worstValue != null) 'worstValue': worstValue,
    };
  }
}

/// 证据（阶段、动作、问题）
class Evidence {
  final String type;
  final Map<String, dynamic> data;

  const Evidence({
    required this.type,
    required this.data,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json);
    data.remove('type');
    return Evidence(type: type, data: data);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...data,
    };
  }

  /// 获取时间窗（如果存在）
  ({int startMs, int endMs})? get window {
    if (data.containsKey('startMs') && data.containsKey('endMs')) {
      return (
        startMs: (data['startMs'] as num).toInt(),
        endMs: (data['endMs'] as num).toInt(),
      );
    }
    return null;
  }

  /// 获取快照路径（如果存在）
  String? get snapshotPath {
    return data['snapshotPath'] as String?;
  }
}

/// 反馈建议
class Feedback {
  final String mode;
  final AttemptsSummary attempts;
  final double? avgAngle;
  final double? targetAngle;
  final double? detectionThreshold;
  final List<String> suggestions;

  const Feedback({
    required this.mode,
    required this.attempts,
    this.avgAngle,
    this.targetAngle,
    this.detectionThreshold,
    required this.suggestions,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      mode: json['mode'] as String,
      attempts: AttemptsSummary.fromJson(json['attempts'] as Map<String, dynamic>),
      avgAngle: (json['avgAngle'] as num?)?.toDouble(),
      targetAngle: (json['targetAngle'] as num?)?.toDouble(),
      detectionThreshold: (json['detectionThreshold'] as num?)?.toDouble(),
      suggestions: (json['suggestions'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'attempts': attempts.toJson(),
      if (avgAngle != null) 'avgAngle': avgAngle,
      if (targetAngle != null) 'targetAngle': targetAngle,
      if (detectionThreshold != null) 'detectionThreshold': detectionThreshold,
      'suggestions': suggestions,
    };
  }
}

/// 尝试次数摘要
class AttemptsSummary {
  final int total;
  final int qualified;
  final int unqualified;

  const AttemptsSummary({
    required this.total,
    required this.qualified,
    required this.unqualified,
  });

  factory AttemptsSummary.fromJson(Map<String, dynamic> json) {
    return AttemptsSummary(
      total: (json['total'] as num).toInt(),
      qualified: (json['qualified'] as num).toInt(),
      unqualified: (json['unqualified'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'qualified': qualified,
      'unqualified': unqualified,
    };
  }
}

/// 部分结果原因
class PartialReason {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const PartialReason({
    required this.code,
    required this.message,
    required this.details,
  });

  factory PartialReason.fromJson(Map<String, dynamic> json) {
    return PartialReason(
      code: json['code'] as String,
      message: json['message'] as String,
      details: (json['details'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }
}

