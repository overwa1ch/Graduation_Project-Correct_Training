import '../spec/rule_models.dart';
import '../pose/kp_models.dart';
import '../result/csv_export.dart';

class OfflinePipeline {
  final RuleSet rules;
  final Strictness strictness;
  OfflinePipeline(this.rules, this.strictness);

  Future<({String anglesCsv, Map<String, dynamic> resultJson})> run(KeypointSeries kp) async {
    print("=== Debug: first 3 frames keypoint scores (L/R hip,knee,ankle) ===");

    // MoveNet17 索引（A阶段）
    const L_SHOULDER = 5, R_SHOULDER = 6;
    const L_HIP = 11, R_HIP = 12;
    const L_KNEE = 13, R_KNEE = 14;
    const L_ANKLE = 15, R_ANKLE = 16;

    for (int i = 0; i < 3 && i < kp.frames.length; i++) {
      final pts = kp.frames[i].pts; // [[x,y,score], ...] 长度应为17
      final vals = [
        pts[L_HIP][2], pts[R_HIP][2],
        pts[L_KNEE][2], pts[R_KNEE][2],
        pts[L_ANKLE][2], pts[R_ANKLE][2],
      ];
      print("Frame $i scores = $vals");
    }

    // === v1.1：用关键点可用性计算 coverage（与角度链路解耦） ===
    int ok = 0, total = kp.frames.length;
    bool valid(List<List<num>> pts, int idx) => pts[idx][2] > 0.0; // v1.1 冻结
    for (final fr in kp.frames) {
      final pts = fr.pts;
      final good =
          valid(pts, L_HIP) && valid(pts, R_HIP) &&
          valid(pts, L_KNEE) && valid(pts, R_KNEE) &&
          valid(pts, L_ANKLE) && valid(pts, R_ANKLE);
      if (good) ok++;
    }
    final cov = total == 0 ? 0.0 : ok / total;
    final coverage = ((cov * 1000).roundToDouble() / 1000.0); // 三位小数
    final lowConfidence = cov < 0.7; // v1.1 冻结质量阈值

    // 角度：先维持占位（留空）；下一步再补 knee/trunk 计算
    final rows = <List<num?>>[];
    for (final f in kp.frames) {
      rows.add([f.tMs, null, null, null]); // t_ms,knee_L,knee_R,trunk_deg
    }
    final anglesCsv = buildAnglesCsv(rows);

    final resultJson = <String, dynamic>{
      'meta': {
        'fps': kp.fps,
        'ruleVersion': rules.version,
        'strictness': strictness.value,
      },
      'quality': { 'coverage': coverage, 'lowConfidence': lowConfidence },
      'reps': 0, // fake 3 帧不满足 600ms/250ms，这是预期
      'scores': { 'overall': 0.0, 'form': 0.0, 'stability': 0.0, 'tempo': 0.0 },
      'issues': [],
      'evidence': [],
    };
    return (anglesCsv: anglesCsv, resultJson: resultJson);
  }
}
