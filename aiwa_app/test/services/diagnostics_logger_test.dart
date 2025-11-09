import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/utils/diagnostics_logger.dart';

void main() {
  test('diagnostics.log is valid JSONL and redacts absolute paths', () async {
    final tmp = await Directory.systemTemp.createTemp('aiwa_session_');
    final sessionRoot = tmp.path.replaceAll('\\', '/');

    final logger = DiagnosticsLogger(sessionRoot);
    await logger.logStart(
      sessionId: 'sid_001',
      input: {'path': '/Users/john/video.mp4', 'durationMs': 1000},
      params: {'engine': 'MoveNet', 'configPath': 'configs/app_runtime.json'},
    );
    await logger.logPhase(sessionId: 'sid_001', phase: 'decode');
    await logger.logProgress(
      sessionId: 'sid_001',
      phase: 'infer',
      processed: 10,
      total: 100,
      p95MsPerFrame: 33.2,
      etaSec: 5,
    );
    await logger.logDone(sessionId: 'sid_001', artifactsRoot: '/Users/john/app/offline_out/xyz');

    final file = File('$sessionRoot/diagnostics.log');
    expect(await file.exists(), isTrue);

    final lines = const LineSplitter().convert(await file.readAsString());
    expect(lines.length >= 3, isTrue);

    for (final line in lines) {
      final obj = jsonDecode(line) as Map<String, dynamic>;
      expect(obj['event'], isA<String>());
      // 脱敏：不应包含具体用户名 john
      final text = line.toLowerCase();
      expect(text.contains('/users/john'), isFalse);
    }

    await tmp.delete(recursive: true);
  });
}


