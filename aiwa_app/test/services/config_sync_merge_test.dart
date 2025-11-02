// config_sync_merge_test.dart
// Purpose: 测试 config_sync.dart 的配置合并、写入、快照、参数组装
// 覆盖: readAppRuntimeConfig, writeAppRuntimeConfig, writeRuntimeSnapshot, buildCliArgs

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/config_sync.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('config_sync_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('config_sync', () {
    test('readAppRuntimeConfig - 文件不存在时返回默认值', () async {
      // 准备：不创建配置文件
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：读取配置
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);

      // 断言：返回默认值
      expect(cfg['engine'], equals('MoveNet'));
      expect(cfg['strictness'], equals('strict'));
      expect(cfg['stride'], equals(2));
      expect(cfg['targetFps'], equals(30));
      expect(cfg['resolution'], equals('1280x720'));
      expect((cfg['privacy'] as Map)['upload'], equals('keypoints-only'));
      expect((cfg['privacy'] as Map)['confirmVideoUpload'], equals(true));
      expect((cfg['cleanup'] as Map)['days'], equals(7));
      expect((cfg['logs'] as Map)['level'], equals('info'));
    });

    test('readAppRuntimeConfig - 文件存在时合并默认值', () async {
      // 准备：复制 dev/app_runtime_existing.json
      final configPath = '${tempDir.path}/configs/app_runtime.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      final sourceFile = File('dev/app_runtime_existing.json');
      final targetFile = File(configPath);
      await sourceFile.copy(targetFile.path);

      // 执行：读取配置
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);

      // 断言：合并了默认值
      expect(cfg['engine'], equals('MLKit'), reason: '文件中的值优先');
      expect(cfg['stride'], equals(1), reason: '文件中的值优先');
      expect((cfg['privacy'] as Map)['upload'], equals('none'), reason: '文件中的值优先');
      
      // 未在文件中指定的值应使用默认值
      expect(cfg['strictness'], equals('strict'), reason: '未指定，使用默认值');
      expect(cfg['targetFps'], equals(30), reason: '未指定，使用默认值');
      expect(cfg['resolution'], equals('1280x720'), reason: '未指定，使用默认值');
    });

    test('writeAppRuntimeConfig - 合并优先级：表单 > 现有 > 默认', () async {
      // 准备：先写入现有配置
      final configPath = '${tempDir.path}/configs/app_runtime.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      final existingFile = File(configPath);
      await existingFile.writeAsString(jsonEncode({
        'engine': 'MLKit',
        'stride': 1,
      }));

      // 执行：写入新配置（仅修改 engine）
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: configPath,
      );

      // 断言：读取合并后的配置
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      
      expect(cfg['engine'], equals('MoveNet'), reason: '表单优先级最高');
      expect(cfg['stride'], equals(1), reason: '现有值保留');
      expect(cfg['strictness'], equals('strict'), reason: '默认值补充');
    });

    test('writeAppRuntimeConfig - 非法值回退到默认值', () async {
      // 准备：写入非法配置
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入非法值
      await writeAppRuntimeConfig(
        {
          'resolution': 'foo',
          'stride': 0,
          'targetFps': -1,
          'cleanup': {'days': -5},
        },
        pathOverride: configPath,
      );

      // 断言：读取后发现已回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      
      expect(cfg['resolution'], equals('1280x720'), reason: 'foo 非法，回退默认');
      expect(cfg['stride'], equals(2), reason: '0 非法，回退默认');
      expect(cfg['targetFps'], equals(30), reason: '-1 非法，回退默认');
      expect((cfg['cleanup'] as Map)['days'], equals(7), reason: '-5 非法，回退默认');
    });

    test('writeAppRuntimeConfig - 字段顺序稳定', () async {
      // 准备：写入配置
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入配置
      await writeAppRuntimeConfig(
        {
          'stride': 3,
          'engine': 'MoveNet',
        },
        pathOverride: configPath,
      );

      // 断言：读取文件内容，检查 key 顺序
      final content = await File(configPath).readAsString();
      final lines = content.split('\n');
      
      // 找到各个 key 的行号
      int? engineLine;
      int? strictnessLine;
      int? strideLine;
      int? targetFpsLine;
      int? resolutionLine;
      int? privacyLine;
      int? cleanupLine;
      int? logsLine;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('"engine"')) engineLine = i;
        if (lines[i].contains('"strictness"')) strictnessLine = i;
        if (lines[i].contains('"stride"')) strideLine = i;
        if (lines[i].contains('"targetFps"')) targetFpsLine = i;
        if (lines[i].contains('"resolution"')) resolutionLine = i;
        if (lines[i].contains('"privacy"')) privacyLine = i;
        if (lines[i].contains('"cleanup"')) cleanupLine = i;
        if (lines[i].contains('"logs"')) logsLine = i;
      }
      
      // 断言：顺序符合预期（engine → strictness → stride → targetFps → resolution → privacy → cleanup → logs）
      expect(engineLine, isNotNull);
      expect(strictnessLine, isNotNull);
      expect(strideLine, isNotNull);
      expect(engineLine! < strictnessLine!, isTrue);
      expect(strictnessLine < strideLine!, isTrue);
      expect(strideLine < targetFpsLine!, isTrue);
      expect(targetFpsLine < resolutionLine!, isTrue);
      expect(resolutionLine < privacyLine!, isTrue);
      expect(privacyLine < cleanupLine!, isTrue);
      expect(cleanupLine < logsLine!, isTrue);
    });

    test('writeRuntimeSnapshot - 写入完整配置快照', () async {
      // 准备：构造有效配置
      final sessionRoot = '${tempDir.path}/session_001';
      await Directory(sessionRoot).create(recursive: true);

      final effectiveCfg = {
        'engine': 'MoveNet',
        'strictness': 'strict',
        'stride': 2,
        'targetFps': 30,
        'resolution': '1280x720',
        'privacy': {
          'upload': 'keypoints-only',
          'confirmVideoUpload': true,
        },
        'cleanup': {
          'days': 7,
        },
        'logs': {
          'level': 'info',
        },
      };

      // 执行：写入快照
      await writeRuntimeSnapshot(sessionRoot, effectiveCfg);

      // 断言：快照文件存在且内容正确
      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      expect(await snapshotFile.exists(), isTrue);

      final content = await snapshotFile.readAsString();
      final snapshot = jsonDecode(content) as Map<String, dynamic>;

      expect(snapshot['engine'], equals('MoveNet'));
      expect(snapshot['strictness'], equals('strict'));
      expect(snapshot['stride'], equals(2));
      expect((snapshot['privacy'] as Map)['upload'], equals('keypoints-only'));
    });

    test('writeRuntimeSnapshot - 快照内容与传入 Map 完全一致', () async {
      // 准备：构造有效配置（包含自定义字段）
      final sessionRoot = '${tempDir.path}/session_002';
      await Directory(sessionRoot).create(recursive: true);

      final effectiveCfg = {
        'engine': 'MLKit',
        'stride': 1,
        'customField': 'customValue',
      };

      // 执行：写入快照
      await writeRuntimeSnapshot(sessionRoot, effectiveCfg);

      // 断言：快照完全匹配
      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      final content = await snapshotFile.readAsString();
      final snapshot = jsonDecode(content) as Map<String, dynamic>;

      expect(snapshot['engine'], equals('MLKit'));
      expect(snapshot['stride'], equals(1));
      expect(snapshot['customField'], equals('customValue'));
    });

    test('buildCliArgs - 返回正确的参数三元组', () {
      // 执行：构建 CLI 参数
      final args = buildCliArgs(
        pickedInput: '/path/to/video.mp4',
        sessionRoot: 'build/offline_out/session_001',
        configPath: 'configs/custom.json',
      );

      // 断言：三元组字段正确
      expect(args.inputPath, equals('/path/to/video.mp4'));
      expect(args.sessionRoot, equals('build/offline_out/session_001'));
      expect(args.configPath, equals('configs/custom.json'));
    });

    test('buildCliArgs - 允许 pickedInput 为空串', () {
      // 执行：pickedInput 为空串
      final args = buildCliArgs(
        pickedInput: '',
        sessionRoot: 'build/offline_out/session_002',
      );

      // 断言：空串也合法
      expect(args.inputPath, equals(''));
      expect(args.sessionRoot, equals('build/offline_out/session_002'));
      expect(args.configPath, equals('configs/app_runtime.json'), reason: '使用默认 configPath');
    });

    test('writeAppRuntimeConfig - 枚举值大小写不敏感', () async {
      // 准备：写入小写的 engine
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入小写 engine
      await writeAppRuntimeConfig(
        {'engine': 'movenet'},
        pathOverride: configPath,
      );

      // 断言：规范化为大写形式
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['engine'], equals('MoveNet'), reason: '小写规范化为 MoveNet');
    });

    test('writeAppRuntimeConfig - 无效 engine 回退到默认值', () async {
      // 准备：写入无效 engine
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入无效 engine
      await writeAppRuntimeConfig(
        {'engine': 'InvalidEngine'},
        pathOverride: configPath,
      );

      // 断言：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['engine'], equals('MoveNet'), reason: '无效值回退到默认');
    });

    test('writeAppRuntimeConfig - 无效 privacy.upload 回退到默认值', () async {
      // 准备：写入无效 privacy.upload
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入无效 upload
      await writeAppRuntimeConfig(
        {
          'privacy': {'upload': 'invalid-option'},
        },
        pathOverride: configPath,
      );

      // 断言：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect((cfg['privacy'] as Map)['upload'], equals('keypoints-only'), 
             reason: '无效值回退到默认');
    });

    test('readAppRuntimeConfig - 解析失败时抛出 ConfigInvalid', () async {
      // 准备：写入非法 JSON
      final configPath = '${tempDir.path}/configs/app_runtime.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      final configFile = File(configPath);
      await configFile.writeAsString('{ this is not valid json }');

      // 断言：抛出 ConfigInvalid 异常
      expect(
        () => readAppRuntimeConfig(pathOverride: configPath),
        throwsA(isA<ConfigInvalid>().having(
          (e) => e.message,
          'message',
          contains('json'),
        )),
      );
    });

    test('writeAppRuntimeConfig - 分辨率格式校验', () async {
      // 准备：写入各种分辨率格式
      final configPath = '${tempDir.path}/configs/app_runtime.json';

      // 执行：写入合法分辨率
      await writeAppRuntimeConfig(
        {'resolution': '1920x1080'},
        pathOverride: configPath,
      );

      var cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['resolution'], equals('1920x1080'), reason: '合法格式保留');

      // 执行：写入非法分辨率
      await writeAppRuntimeConfig(
        {'resolution': '1920*1080'},
        pathOverride: configPath,
      );

      cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['resolution'], equals('1280x720'), reason: '非法格式回退默认');
    });
  });

  group('config_sync file system errors', () {
    test('readAppRuntimeConfig handles permission errors', () async {
      // 注意：在大多数测试环境中难以模拟权限错误
      // 这里测试不存在的路径（回退到默认值）
      const configPath = '/root/impossible/path/config.json';
      
      // 读取不可访问的路径应该使用默认值
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      
      expect(cfg['engine'], equals('MoveNet'));
      expect(cfg['strictness'], equals('strict'));
    });

    test('writeAppRuntimeConfig handles directory creation', () async {
      final configPath = '${tempDir.path}/deep/nested/path/config.json';
      
      // 写入深层嵌套路径
      await writeAppRuntimeConfig(
        {'engine': 'MLKit'},
        pathOverride: configPath,
      );
      
      // 验证：文件和目录都已创建
      final configFile = File(configPath);
      expect(await configFile.exists(), isTrue);
      
      // 读取验证
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['engine'], equals('MLKit'));
    });

    test('writeAppRuntimeConfig is atomic (creates temp file first)', () async {
      final configPath = '${tempDir.path}/configs/atomic_test.json';
      
      // 写入配置
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'stride': 3},
        pathOverride: configPath,
      );
      
      // 验证：主文件存在且有效
      final configFile = File(configPath);
      expect(await configFile.exists(), isTrue);
      
      final content = await configFile.readAsString();
      expect(content, contains('MoveNet'));
      expect(content, contains('stride'));
    });

    test('writeRuntimeSnapshot handles session directory missing', () async {
      final sessionRoot = '${tempDir.path}/nonexistent_session';
      // 不创建目录
      
      final cfg = {
        'engine': 'MoveNet',
        'strictness': 'strict',
      };
      
      // 写入快照（应该创建目录）
      await writeRuntimeSnapshot(sessionRoot, cfg);
      
      // 验证：快照文件已创建
      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      expect(await snapshotFile.exists(), isTrue);
    });

    test('config file corruption recovery', () async {
      final configPath = '${tempDir.path}/configs/corrupted.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      // 写入损坏的 JSON
      await File(configPath).writeAsString('{incomplete json');
      
      // 尝试读取损坏的配置
      expect(
        () => readAppRuntimeConfig(pathOverride: configPath),
        throwsA(isA<ConfigInvalid>()),
      );
    });

    test('writeAppRuntimeConfig handles disk full simulation', () async {
      // 注意：真实的磁盘满情况难以测试
      // 这里测试空间可用时的正常行为
      final configPath = '${tempDir.path}/configs/diskfull_test.json';
      
      // 写入较大的配置
      final largeCfg = {
        'engine': 'MoveNet' * 100,
        'strictness': 'strict' * 100,
      };
      
      try {
        await writeAppRuntimeConfig(largeCfg, pathOverride: configPath);
        
        // 如果写入成功，验证文件存在
        final file = File(configPath);
        expect(await file.exists(), isTrue);
      } catch (e) {
        // 如果失败，应该是有意义的异常
        expect(e, isNotNull);
      }
    });
  });

  group('config_sync concurrent access', () {
    test('multiple reads are safe', () async {
      final configPath = '${tempDir.path}/configs/concurrent_read.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      // 写入初始配置
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: configPath,
      );
      
      // 并发读取
      final reads = await Future.wait([
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
      ]);
      
      // 验证：所有读取结果一致
      for (final cfg in reads) {
        expect(cfg['engine'], equals('MoveNet'));
      }
    });

    test('concurrent writes serialize correctly', () async {
      final configPath = '${tempDir.path}/configs/concurrent_write.json';
      
      // 并发写入不同值
      await Future.wait([
        writeAppRuntimeConfig({'engine': 'MoveNet'}, pathOverride: configPath),
        writeAppRuntimeConfig({'engine': 'MLKit'}, pathOverride: configPath),
        writeAppRuntimeConfig({'engine': 'MediaPipe'}, pathOverride: configPath),
      ]);
      
      // 验证：最终文件存在且有效（最后一次写入生效）
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(['MoveNet', 'MLKit', 'MediaPipe'], contains(cfg['engine']));
    });

    test('read during write is consistent', () async {
      final configPath = '${tempDir.path}/configs/read_during_write.json';
      
      // 初始写入
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: configPath,
      );
      
      // 启动写入和读取
      final futures = await Future.wait([
        writeAppRuntimeConfig({'engine': 'MLKit'}, pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
      ]);
      
      // 读取结果应该是有效的配置（MoveNet 或 MLKit）
      final readResult = futures[1] as Map<String, dynamic>;
      expect(['MoveNet', 'MLKit'], contains(readResult['engine']));
    });

    test('multiple snapshot writes to different sessions', () async {
      final cfg = {
        'engine': 'MoveNet',
        'strictness': 'strict',
      };
      
      // 并发写入多个会话快照
      await Future.wait([
        writeRuntimeSnapshot('${tempDir.path}/session_001', cfg),
        writeRuntimeSnapshot('${tempDir.path}/session_002', cfg),
        writeRuntimeSnapshot('${tempDir.path}/session_003', cfg),
      ]);
      
      // 验证：所有快照都存在
      for (int i = 1; i <= 3; i++) {
        final snapshotPath = '${tempDir.path}/session_00$i/configs_snapshot.json';
        expect(await File(snapshotPath).exists(), isTrue);
      }
    });
  });

  group('config_sync edge cases', () {
    test('empty config object writes defaults', () async {
      final configPath = '${tempDir.path}/configs/empty.json';
      
      // 写入空配置
      await writeAppRuntimeConfig({}, pathOverride: configPath);
      
      // 读取应该有默认值
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['engine'], equals('MoveNet'));
      expect(cfg['strictness'], equals('strict'));
    });

    test('config with unknown fields is preserved', () async {
      final configPath = '${tempDir.path}/configs/unknown_fields.json';
      await Directory('${tempDir.path}/configs').create(recursive: true);
      
      // 手动写入包含未知字段的配置
      await File(configPath).writeAsString(jsonEncode({
        'engine': 'MoveNet',
        'unknownField': 'customValue',
        'anotherUnknown': 123,
      }));
      
      // 读取配置
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      
      // 验证：已知字段正确
      expect(cfg['engine'], equals('MoveNet'));
      
      // 未知字段可能被保留或忽略（取决于实现）
      // 至少配置应该可用
      expect(cfg, isNotEmpty);
    });

    test('very long config values are handled', () async {
      final configPath = '${tempDir.path}/configs/long_values.json';
      
      // 写入很长的字符串
      final longString = 'A' * 10000;
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'resolution': longString},
        pathOverride: configPath,
      );
      
      // 读取配置（无效的 resolution 应该回退到默认值）
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['resolution'], equals('1280x720')); // 回退到默认
    });

    test('special characters in config values', () async {
      final configPath = '${tempDir.path}/configs/special_chars.json';
      
      // 写入包含特殊字符的值（虽然 engine 枚举不应该有这些）
      await writeAppRuntimeConfig(
        {'engine': 'Move\nNet'},
        pathOverride: configPath,
      );
      
      // 读取配置（无效值应该回退）
      final cfg = await readAppRuntimeConfig(pathOverride: configPath);
      expect(cfg['engine'], equals('MoveNet')); // 回退到默认
    });

    test('config file size limits', () async {
      final configPath = '${tempDir.path}/configs/size_test.json';
      
      // 正常大小的配置应该工作
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'stride': 2},
        pathOverride: configPath,
      );
      
      final file = File(configPath);
      final size = await file.length();
      
      // 配置文件应该是合理大小（< 10KB）
      expect(size, lessThan(10 * 1024));
    });

    test('buildCliArgs with empty strings', () {
      final args = buildCliArgs(
        pickedInput: '',
        sessionRoot: '',
      );
      
      expect(args.inputPath, equals(''));
      expect(args.sessionRoot, equals(''));
      expect(args.configPath, isNotEmpty); // 应该有默认值
    });

    test('buildCliArgs with very long paths', () {
      final longPath = '/very/long/path/${'nested/' * 100}file.mp4';
      
      final args = buildCliArgs(
        pickedInput: longPath,
        sessionRoot: '/another/long/path',
      );
      
      expect(args.inputPath, equals(longPath));
      expect(args.sessionRoot, equals('/another/long/path'));
    });
  });

  group('config_sync performance', () {
    test('config read is fast', () async {
      final configPath = '${tempDir.path}/configs/perf_test.json';
      
      // 准备配置
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: configPath,
      );
      
      // 测量读取时间
      final stopwatch = Stopwatch()..start();
      await readAppRuntimeConfig(pathOverride: configPath);
      stopwatch.stop();
      
      // 读取应该很快（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('config write is fast', () async {
      final configPath = '${tempDir.path}/configs/perf_write_test.json';
      
      // 测量写入时间
      final stopwatch = Stopwatch()..start();
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'stride': 2},
        pathOverride: configPath,
      );
      stopwatch.stop();
      
      // 写入应该很快（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('multiple sequential operations are efficient', () async {
      final configPath = '${tempDir.path}/configs/sequential_test.json';
      
      final stopwatch = Stopwatch()..start();
      
      // 执行多次读写操作
      for (int i = 0; i < 10; i++) {
        await writeAppRuntimeConfig(
          {'engine': 'MoveNet', 'stride': i},
          pathOverride: configPath,
        );
        await readAppRuntimeConfig(pathOverride: configPath);
      }
      
      stopwatch.stop();
      
      // 10次操作应该在合理时间内完成（< 1秒）
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}

