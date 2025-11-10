// result_adapter_test.dart
// 单元测试：result_adapter.dart（UI 轻量映射）
//
// ✅ 重构说明：
// - Schema 验证已移至 aiwa_core/result/result_reader.dart
// - 本测试只验证 UI 轻量映射逻辑（toLite 函数）
// - 完整的 schema 验证测试应在 aiwa_core 中进行
//
// 验收条件（DoD）：
// 1. happy path: 完整结果正确映射到 UI 模型
// 2. 部分结果: scores 为 null 时正确处理
// 3. 证据解析: snapshotPath 正确提取
// 4. 分数转换: 浮点数正确转为整数（使用 round1）

import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_core/result/result_schema.dart';

void main() {
  group('Result Adapter - UI Mapping Tests', () {
    // 测试 1: Happy Path - 完整结果映射
    test('Should map complete result correctly', () {
      final result = AnalysisResult(
        meta: const ResultMetadata(
          template: 'squat',
          fps: 30.0,
          ruleVersion: '1.0',
          strictness: 'strict',
          engine: 'MoveNet',
        ),
        quality: const QualityMetrics(
          coverage: 0.76,
          lowConfidence: false,
        ),
        repCount: 12,
        attemptsCount: 15,
        reps: const [],
        scores: const Scores(
          form: 84.0,
          stability: 77.0,
          tempo: 71.0,
          overall: 78.0,
        ),
        issues: const [],
        evidence: [
          Evidence(
            type: 'rep',
            data: {
              'snapshotPath': 'evidence/frame_612.jpg',
              'startMs': 20000,
              'endMs': 21000,
            },
          ),
        ],
      );

      // 映射为轻量模型
      final lite = toLite(result);

      // 验证：分数映射正确（form→posture, tempo→rhythm）
      expect(lite.posture, equals(84), reason: 'posture should map from scores.form');
      expect(lite.stability, equals(77));
      expect(lite.rhythm, equals(71), reason: 'rhythm should map from scores.tempo');
      expect(lite.total, equals(78), reason: 'total should map from scores.overall');

      // 验证：次数
      expect(lite.reps, equals(12));
      expect(lite.attempts, equals(15));

      // 验证：证据路径
      expect(lite.evidencePath, equals('evidence/frame_612.jpg'));

      // 验证：质量指标
      expect(lite.lowConfidence, equals(false));
      expect(lite.coverage, equals(0.76));

      // 验证：元信息
      expect(lite.templateName, equals('squat'));
      expect(lite.strictness, equals('strict'));
      expect(lite.engine, equals('MoveNet'));
      expect(lite.fps, equals(30));

      // 验证：非部分结果
      expect(lite.isPartial, equals(false));
      expect(lite.partialFailure, isNull);
    });

    // 测试 2: 部分结果 - scores 为 null
    test('Should handle partial result with null scores', () {
      final result = AnalysisResult(
        meta: const ResultMetadata(
          template: 'squat',
          fps: 30.0,
          ruleVersion: '1.0',
          strictness: 'relaxed',
        ),
        quality: const QualityMetrics(
          coverage: 0.65,
          lowConfidence: true,
        ),
        repCount: 0,
        attemptsCount: 0,
        reps: const [],
        scores: const Scores(
          form: null,
          stability: null,
          tempo: null,
          overall: null,
        ),
        issues: const [],
        evidence: const [],
        partial: true,
        partialReason: const PartialReason(
          code: 'ANGLE_COMPUTE_FAILED',
          message: 'Insufficient keypoints',
          details: {'stage': 'angle_computation'},
        ),
      );

      final lite = toLite(result);

      // 验证：分数为 null
      expect(lite.posture, isNull);
      expect(lite.stability, isNull);
      expect(lite.rhythm, isNull);
      expect(lite.total, isNull);

      // 验证：部分结果标记
      expect(lite.isPartial, equals(true));
      expect(lite.partialFailure, isNotNull);
      expect(lite.partialFailure!.code, equals('ANGLE_COMPUTE_FAILED'));
      expect(lite.partialFailure!.message, equals('Insufficient keypoints'));
    });

    // 测试 3: 证据解析 - snapshotPath 缺失
    test('Should return null evidencePath when snapshot missing', () {
      final result = AnalysisResult(
        meta: const ResultMetadata(
          template: 'squat',
          fps: 30.0,
          ruleVersion: '1.0',
          strictness: 'strict',
        ),
        quality: const QualityMetrics(
          coverage: 0.8,
          lowConfidence: false,
        ),
        repCount: 10,
        attemptsCount: 10,
        reps: const [],
        scores: const Scores(
          form: 80.0,
          stability: 75.0,
          tempo: 70.0,
          overall: 75.0,
        ),
        issues: const [],
        evidence: [
          Evidence(
            type: 'rep',
            data: {
              'startMs': 1000,
              'endMs': 2000,
              // snapshotPath 缺失
            },
          ),
        ],
      );

      final lite = toLite(result);

      // 验证：evidencePath 为 null
      expect(lite.evidencePath, isNull);
    });

    // 测试 4: 分数转换 - 浮点数转整数
    test('Should round float scores to integers', () {
      final result = AnalysisResult(
        meta: const ResultMetadata(
          template: 'squat',
          fps: 30.0,
          ruleVersion: '1.0',
          strictness: 'strict',
        ),
        quality: const QualityMetrics(
          coverage: 0.9,
          lowConfidence: false,
        ),
        repCount: 5,
        attemptsCount: 5,
        reps: const [],
        scores: const Scores(
          form: 84.6,
          stability: 77.4,
          tempo: 71.2,
          overall: 78.5,
        ),
        issues: const [],
        evidence: const [],
      );

      final lite = toLite(result);

      // 验证：分数四舍五入（round1 + round）
      expect(lite.posture, equals(85));  // 84.6 → 85
      expect(lite.stability, equals(77)); // 77.4 → 77
      expect(lite.rhythm, equals(71));    // 71.2 → 71
      expect(lite.total, equals(79));     // 78.5 → 79
    });

    // 测试 5: 反馈建议映射
    test('Should map feedback to AttemptFeedbackLite', () {
      final result = AnalysisResult(
        meta: const ResultMetadata(
          template: 'squat',
          fps: 30.0,
          ruleVersion: '1.0',
          strictness: 'strict',
        ),
        quality: const QualityMetrics(
          coverage: 0.9,
          lowConfidence: false,
        ),
        repCount: 8,
        attemptsCount: 10,
        reps: const [],
        scores: const Scores(
          form: 85.0,
          stability: 80.0,
          tempo: 75.0,
          overall: 80.0,
        ),
        issues: const [],
        evidence: const [],
        feedback: const Feedback(
          mode: 'strict',
          attempts: AttemptsSummary(
            total: 10,
            qualified: 8,
            unqualified: 2,
          ),
          avgAngle: 92.5,
          targetAngle: 90.0,
          detectionThreshold: 100.0,
          suggestions: [
            'Focus on depth',
            'Keep chest up',
          ],
        ),
      );

      final lite = toLite(result);

      // 验证：反馈映射
      expect(lite.attemptFeedback, isNotNull);
      expect(lite.attemptFeedback!.mode, equals('strict'));
      expect(lite.attemptFeedback!.total, equals(10));
      expect(lite.attemptFeedback!.qualified, equals(8));
      expect(lite.attemptFeedback!.unqualified, equals(2));
      expect(lite.attemptFeedback!.avgAngle, equals(92.5));
      expect(lite.attemptFeedback!.targetAngle, equals(90.0));
      expect(lite.attemptFeedback!.detectionThreshold, equals(100.0));
      expect(lite.attemptFeedback!.suggestions, hasLength(2));
      expect(lite.attemptFeedback!.suggestions[0], equals('Focus on depth'));
    });
  });
}
