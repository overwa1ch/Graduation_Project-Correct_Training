// test/integration/core_contract_test.dart
//
// 合约回归测试 - 验证 aiwa_core 输出格式的兼容性
//
// 目的：
// - 防止核心库输出结构变更导致应用层静默失败
// - 确保黄金样本始终可解析
// - 在核心库变更时第一时间发现问题
//
// 运行方式：
//   flutter test test/integration/core_contract_test.dart
//
// 更新黄金样本：
//   当核心库输出格式变更时，更新 test/fixtures/golden/ 中的文件

import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_core/result/result_schema.dart';
import 'package:aiwa_core/result/result_reader.dart';
import 'package:aiwa_core/pose/neutral_keypoint_series.dart';
import 'package:aiwa_core/spec/rule_models.dart';
import 'package:aiwa_core/spec/rule_parser.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('Core Library Contract Validation', () {
    test('result.json golden sample should be parseable', () async {
      // 从黄金样本读取
      final goldenFile = File('test/fixtures/golden/result.json');
      
      if (!await goldenFile.exists()) {
        // 如果黄金样本不存在，使用测试 fixtures 中的样本
        final testFile = File('test/fixtures/e2e_scenarios/artifacts/session_success/result.json');
        if (await testFile.exists()) {
          // 复制测试样本到黄金样本位置（首次运行）
          final testContent = await testFile.readAsString();
          await goldenFile.parent.create(recursive: true);
          await goldenFile.writeAsString(testContent);
        } else {
          fail('Golden sample not found. Please create test/fixtures/golden/result.json');
        }
      }
      
      final jsonStr = await goldenFile.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // 验证关键字段存在
      expect(json.containsKey('scores'), isTrue, reason: 'result.json must have scores');
      expect(json.containsKey('repCount'), isTrue, reason: 'result.json must have repCount');
      expect(json.containsKey('meta'), isTrue, reason: 'result.json must have meta');
      expect(json.containsKey('quality'), isTrue, reason: 'result.json must have quality');
      
      // 尝试解析为标准模型（应该不抛异常）
      AnalysisResult? result;
      try {
        result = AnalysisResult.fromJson(json);
      } catch (e) {
        fail('Failed to parse result.json: $e\n'
            'This indicates a contract break. Please update the golden sample or fix the schema.');
      }
      
      // 验证关键字段
      expect(result, isNotNull);
      expect(result!.scores.overall, greaterThanOrEqualTo(0));
      expect(result.scores.overall, lessThanOrEqualTo(100));
      expect(result.repCount, greaterThanOrEqualTo(0));
      expect(result.meta.template, isNotEmpty);
    });

    test('neutral_keypoints.json golden sample should be parseable', () async {
      // 检查黄金样本是否存在
      final goldenFile = File('test/fixtures/golden/neutral_keypoints.json');
      
      if (!await goldenFile.exists()) {
        // 如果不存在，跳过测试（首次运行）
        // 后续可以从实际分析结果中提取一个样本
        return;
      }
      
      final jsonStr = await goldenFile.readAsString();
      
      // 严格解析应该不抛异常
      NeutralKeypointSeries? series;
      try {
        series = parseNeutralKeypointSeries(jsonStr);
      } catch (e) {
        fail('Failed to parse neutral_keypoints.json: $e\n'
            'This indicates a contract break. Please update the golden sample or fix the parser.');
      }
      
      // 验证基本结构
      expect(series, isNotNull);
      expect(series!.version, equals('vB1.1'));
      expect(series.frames, isNotEmpty);
      expect(series.frames.first.keypoints, isNotEmpty);
    });

    test('RuleSet golden sample should be parseable', () async {
      // 检查规则文件是否存在（JSON 格式）
      final goldenFile = File('test/fixtures/golden/rule.json');
      
      if (!await goldenFile.exists()) {
        // 如果不存在，尝试从 assets 目录查找
        final assetsFile = File('assets/rules/squat.v1.json');
        if (await assetsFile.exists()) {
          // 复制到黄金样本位置
          final content = await assetsFile.readAsString();
          await goldenFile.parent.create(recursive: true);
          await goldenFile.writeAsString(content);
        } else {
          // 跳过测试（首次运行）
          return;
        }
      }
      
      final jsonStr = await goldenFile.readAsString();
      
      // 解析规则应该不抛异常
      RuleSet? ruleSet;
      try {
        ruleSet = parseRuleSet(jsonStr);
      } catch (e) {
        fail('Failed to parse rule.json: $e\n'
            'This indicates a contract break. Please update the golden sample or fix the parser.');
      }
      
      // 验证规则结构
      expect(ruleSet, isNotNull);
      expect(ruleSet!.template, isNotEmpty);
      expect(ruleSet.phases, isNotEmpty);
    });
  });
}

