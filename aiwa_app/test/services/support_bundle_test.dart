import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:aiwa_app/services/utils/support_bundle.dart';

void main() {
  test('support bundle contains expected files if present', () async {
    // 1) 构造临时会话目录
    final tmp = await Directory.systemTemp.createTemp('aiwa_session_');
    final sessionRoot = tmp.path.replaceAll('\\', '/');

    // 2) 写入若干文件（存在即应被打包）
    await File('$sessionRoot/result.json').writeAsString('{"ok":true}');
    await Directory('$sessionRoot/logs').create(recursive: true);
    await File('$sessionRoot/logs/perf.json').writeAsString('{"frames_total":1,"ms_per_frame":{"p50":1}}');
    await File('$sessionRoot/logs/run.log').writeAsString('log line');
    await File('$sessionRoot/configs_snapshot.json').writeAsString('{"engine":"MoveNet"}');
    await File('$sessionRoot/diagnostics.log').writeAsString('{"event":"START"}\n{"event":"DONE"}\n');

    // 3) 调用导出
    final zipFile = await SupportBundleService.export(sessionRoot);
    expect(await zipFile.exists(), isTrue);

    // 4) 解压并校验清单
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();

    expect(names.contains('result.json'), isTrue);
    expect(names.contains('logs/perf.json'), isTrue);
    expect(names.contains('logs/run.log'), isTrue);
    expect(names.contains('configs_snapshot.json'), isTrue);
    expect(names.contains('diagnostics.log'), isTrue);

    // 5) 校验 diagnostics.log 内容片段
    final diagEntry = archive.files.firstWhere((f) => f.name == 'diagnostics.log');
    final diagContent = utf8.decode(diagEntry.content as List<int>);
    expect(diagContent.contains('"event":"START"'), isTrue);
    expect(diagContent.contains('"event":"DONE"'), isTrue);

    // 清理
    await tmp.delete(recursive: true);
  });
}


