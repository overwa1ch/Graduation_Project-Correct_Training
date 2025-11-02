import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'runner_orchestrator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 入口第一行就打日志（如果连这行都看不到，说明根本不是这份 main.dart 在跑）
  print('>>> MAIN ENTERED <<<');

  // 用一个最简单但稳定的 UI，确保 Activity 不会被奇怪 ROM 回收
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(color: Colors.black), // 黑屏占位，窗口常驻
    ),
  );

  SchedulerBinding.instance.addPostFrameCallback((_) async {
    print('''[BOOT] AIWA Runner (Milestone B / vB1.1)
  engine           = mlkit
  model            = blazepose-full
  inputResolution  = 720p
  samplingStride   = 2  (→ effectiveFps = 15)
  fpsIntended      = 30
''');

    final orchestrator = RunnerOrchestrator(
      videoAssetPath: 'assets/videos/squat_sample.mp4',
      ruleAssetPath: 'assets/rules/squat.v1.json',
      engineName: 'mlkit',
      engineModel: 'blazepose-full',
      inputResolutionLabel: '720p',
      fpsIntended: 30,
      samplingStride: 2,
      mirrorAppliedDefault: false,
    );

    try {
      final outDir = await orchestrator.run();
      print('[DONE] Saved to $outDir');
    } catch (e, st) {
      print('[FATAL] Runner failed: $e');
      print(st.toString());
    }
  });
}
