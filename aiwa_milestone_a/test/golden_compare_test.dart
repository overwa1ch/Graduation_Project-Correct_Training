import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:aiwa_milestone_a/pipeline/offline_pipeline.dart';
import 'package:aiwa_milestone_a/spec/rule_parser.dart';
import 'package:aiwa_milestone_a/spec/rule_models.dart';
import 'package:aiwa_milestone_a/pose/kp_models.dart';

void main() {
  test('golden alignment', () async {
    final kp = parseKeypointSeries(await File('D:\\Graduation_Project-Correct_Training-main\\aiwa_milestone_a\\test\\fixtures\\fake_data.json').readAsString());
    final rs = parseRuleSet(await File('D:\\Graduation_Project-Correct_Training-main\\aiwa_milestone_a\\test\\fixtures\\squat.v1.json').readAsString());
    final pipe = OfflinePipeline(rs, Strictness.relaxed);
    final out = await pipe.run(kp);

    // 与 Python 产出的黄金文件对齐
    final goldenAngles = await File('D:\\Graduation_Project-Correct_Training-main\\milestoneA_outputs\\angles.csv').readAsString();
    final goldenResult = json.decode(await File('D:\\Graduation_Project-Correct_Training-main\\milestoneA_outputs\\result.json').readAsString());

    // 角度曲线：逐点 MAE ≤ 2°
    // （此处可解析 CSV 后计算 MAE；略）

    // reps 一致；scores ≤ 2 分差；issues/evidence 时间点容差 ±33ms
    // ……（略）
  });
}
