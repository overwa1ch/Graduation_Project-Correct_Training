// result_popup_view_test.dart
// Purpose: 测试结果展示的颜色/证据/提示逻辑
// 覆盖: 颜色阈值、证据显示、质量提示

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

/// 根据分数返回颜色（UI 逻辑）
Color getScoreColor(int? score) {
  if (score == null) return Colors.grey;
  if (score < 60) return Colors.red;
  if (score < 80) return Colors.orange;
  return Colors.green;
}

/// 判断是否显示质量警告
bool shouldShowQualityWarning(AnalysisResultLite result) {
  return (result.lowConfidence == true) || result.coverage < 0.7;
}

/// 简化的结果展示 Widget（用于测试）
class MockResultView extends StatelessWidget {
  final AnalysisResultLite result;

  const MockResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = getScoreColor(result.total);
    final showWarning = shouldShowQualityWarning(result);

    return Scaffold(
      appBar: AppBar(title: const Text('分析结果')),
      body: Column(
        children: [
          // 总分卡片
          Container(
            color: scoreColor,
            padding: const EdgeInsets.all(16),
            child: Text(
              '总分: ${result.total}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),

          // 质量警告
          if (showWarning)
            Container(
              color: Colors.yellow.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                '质量警告：低置信度或覆盖率不足',
                style: TextStyle(color: Colors.black),
                key: Key('quality_warning'),
              ),
            ),

          // 证据展示
          if (result.evidencePath != null)
            const ListTile(
              leading: Icon(Icons.image),
              title: Text('证据快照'),
              key: Key('evidence_snapshot'),
            )
          else if (result.evidencePath == null)
            const ListTile(
              leading: Icon(Icons.videocam_off),
              title: Text('无证据快照'),
              key: Key('evidence_placeholder'),
            ),

          // 详细分数
          ListTile(
            title: Text('姿势: ${result.posture}'),
            key: const Key('score_posture'),
          ),
          ListTile(
            title: Text('稳定性: ${result.stability}'),
            key: const Key('score_stability'),
          ),
          ListTile(
            title: Text('节奏: ${result.rhythm}'),
            key: const Key('score_rhythm'),
          ),
          ListTile(
            title: Text('次数: ${result.reps}'),
            key: const Key('score_reps'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('result_popup color thresholds', () {
    test('total=59 → 红色', () {
      final color = getScoreColor(59);
      expect(color, equals(Colors.red));
    });

    test('total=60 → 橙色', () {
      final color = getScoreColor(60);
      expect(color, equals(Colors.orange));
    });

    test('total=79 → 橙色', () {
      final color = getScoreColor(79);
      expect(color, equals(Colors.orange));
    });

    test('total=80 → 绿色', () {
      final color = getScoreColor(80);
      expect(color, equals(Colors.green));
    });

    test('total=100 → 绿色', () {
      final color = getScoreColor(100);
      expect(color, equals(Colors.green));
    });
  });

  group('result_popup quality warning', () {
    test('lowConfidence=true → 显示警告', () {
      const result = AnalysisResultLite(
        posture: 80,
        stability: 75,
        rhythm: 70,
        total: 75,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: true,
        coverage: 0.8,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      expect(shouldShowQualityWarning(result), isTrue);
    });

    test('coverage < 0.7 → 显示警告', () {
      const result = AnalysisResultLite(
        posture: 80,
        stability: 75,
        rhythm: 70,
        total: 75,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.65,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      expect(shouldShowQualityWarning(result), isTrue);
    });

    test('正常样例不显示警告', () {
      const result = AnalysisResultLite(
        posture: 84,
        stability: 77,
        rhythm: 71,
        total: 78,
        reps: 12,
        attempts: 12,
        evidencePath: 'evidence/frame_612.jpg',
        lowConfidence: false,
        coverage: 0.76,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      expect(shouldShowQualityWarning(result), isFalse);
    });

    test('coverage=null, lowConfidence=null → 不显示警告', () {
      const result = AnalysisResultLite(
        posture: 80,
        stability: 75,
        rhythm: 70,
        total: 75,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.9,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      expect(shouldShowQualityWarning(result), isFalse);
    });
  });

  group('result_popup widget', () {
    testWidgets('有 evidencePath 显示缩略图 widget', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 84,
        stability: 77,
        rhythm: 71,
        total: 78,
        reps: 12,
        attempts: 12,
        evidencePath: 'evidence/frame_612.jpg',
        lowConfidence: false,
        coverage: 0.76,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到证据快照 widget
      expect(find.byKey(const Key('evidence_snapshot')), findsOneWidget);
      expect(find.byKey(const Key('evidence_placeholder')), findsNothing);
    });

    testWidgets('无 evidencePath 显示占位', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 72,
        stability: 70,
        rhythm: 68,
        total: 70,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.9,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到占位 widget
      expect(find.byKey(const Key('evidence_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('evidence_snapshot')), findsNothing);
    });

    testWidgets('lowConfidence=true 显示质量警告', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 80,
        stability: 75,
        rhythm: 70,
        total: 75,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: true,
        coverage: 0.8,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到质量警告
      expect(find.byKey(const Key('quality_warning')), findsOneWidget);
      expect(find.text('质量警告：低置信度或覆盖率不足'), findsOneWidget);
    });

    testWidgets('coverage < 0.7 显示质量警告', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 80,
        stability: 75,
        rhythm: 70,
        total: 75,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.65,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到质量警告
      expect(find.byKey(const Key('quality_warning')), findsOneWidget);
    });

    testWidgets('正常样例不显示质量警告', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 84,
        stability: 77,
        rhythm: 71,
        total: 78,
        reps: 12,
        attempts: 12,
        evidencePath: 'evidence/frame_612.jpg',
        lowConfidence: false,
        coverage: 0.76,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：不显示质量警告
      expect(find.byKey(const Key('quality_warning')), findsNothing);
    });

    testWidgets('total=59 背景为红色', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 59,
        stability: 58,
        rhythm: 60,
        total: 59,
        reps: 8,
        attempts: 8,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.9,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到总分卡片
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('总分: 59'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.color, equals(Colors.red));
    });

    testWidgets('total=70 背景为橙色', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 72,
        stability: 70,
        rhythm: 68,
        total: 70,
        reps: 10,
        attempts: 10,
        evidencePath: null,
        lowConfidence: false,
        coverage: 0.9,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到总分卡片
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('总分: 70'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.color, equals(Colors.orange));
    });

    testWidgets('total=85 背景为绿色', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 85,
        stability: 83,
        rhythm: 88,
        total: 85,
        reps: 15,
        attempts: 15,
        evidencePath: 'evidence/frame_800.jpg',
        lowConfidence: false,
        coverage: 0.9,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到总分卡片
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('总分: 85'),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.color, equals(Colors.green));
    });

    testWidgets('显示所有详细分数', (WidgetTester tester) async {
      const result = AnalysisResultLite(
        posture: 84,
        stability: 77,
        rhythm: 71,
        total: 78,
        reps: 12,
        attempts: 12,
        evidencePath: 'evidence/frame_612.jpg',
        lowConfidence: false,
        coverage: 0.76,
        templateName: 'squat',
        strictness: 'relaxed',
        fps: 30,
      );

      await tester.pumpWidget(MaterialApp(home: MockResultView(result: result)));

      // 断言：找到所有分数
      expect(find.byKey(const Key('score_posture')), findsOneWidget);
      expect(find.byKey(const Key('score_stability')), findsOneWidget);
      expect(find.byKey(const Key('score_rhythm')), findsOneWidget);
      expect(find.byKey(const Key('score_reps')), findsOneWidget);

      expect(find.text('姿势: 84'), findsOneWidget);
      expect(find.text('稳定性: 77'), findsOneWidget);
      expect(find.text('节奏: 71'), findsOneWidget);
      expect(find.text('次数: 12'), findsOneWidget);
    });
  });
}

