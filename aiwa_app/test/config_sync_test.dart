// config_sync_test.dart
// 单元测试：config_sync.dart
//
// 验收条件（DoD）：
// 1. 读取缺省：无文件 → 返回默认值
// 2. 合并优先级：现有文件 + 表单 → 表单优先
// 3. 非法值回退：不合法枚举/数值 → 回退默认
// 4. 快照内容：writeRuntimeSnapshot → 原样写入
// 5. 参数组装：buildCliArgs → 返回正确三元组
// 6. IO 异常：写入失败/解析失败 → 抛异常

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/config_sync.dart';

void main() {
  group('Config Sync - Basic Tests', () {
    const testDir = 'test_output/config_sync';

    setUp(() async {
      // 创建测试目录
      await Directory(testDir).create(recursive: true);
    });

    tearDown(() async {
      // 清理测试目录
      if (await Directory(testDir).exists()) {
        await Directory(testDir).delete(recursive: true);
      }
    });

    // 测试 1: 读取缺省（无文件 → 返回默认值）
    test('Should return defaults when file not found', () async {
      final cfg = await readAppRuntimeConfig(
        pathOverride: '$testDir/non_existent.json',
      );

      // 验证：返回默认值
      expect(cfg['engine'], equals('MoveNet'));
      expect(cfg['strictness'], equals('strict'));
      expect(cfg['stride'], equals(2));
      expect(cfg['targetFps'], equals(30));
      expect(cfg['resolution'], equals('1280x720'));
      expect(cfg['privacy']['upload'], equals('keypoints-only'));
      expect(cfg['privacy']['confirmVideoUpload'], equals(true));
      expect(cfg['cleanup']['days'], equals(7));
      expect(cfg['logs']['level'], equals('info'));
    });

    // 测试 2: 写入后文件存在且字段顺序稳定
    test('Should write config with stable field order', () async {
      final path = '$testDir/app_runtime.json';

      await writeAppRuntimeConfig(
        {'engine': 'MLKit', 'strictness': 'relaxed'},
        pathOverride: path,
      );

      // 验证：文件存在
      final file = File(path);
      expect(await file.exists(), isTrue);

      // 验证：内容正确
      final content = await file.readAsString();
      expect(content, contains('"engine": "MLKit"'));
      expect(content, contains('"strictness": "relaxed"'));

      // 验证：字段顺序稳定（engine 在 strictness 前面）
      final engineIndex = content.indexOf('"engine"');
      final strictnessIndex = content.indexOf('"strictness"');
      expect(engineIndex, lessThan(strictnessIndex));
    });

    // 测试 3: 合并优先级（现有文件 + 表单 → 表单优先）
    test('Should merge with correct priority (form > existing > defaults)', () async {
      final path = '$testDir/merge_test.json';

      // 1. 写入初始配置
      await writeAppRuntimeConfig(
        {'engine': 'MLKit', 'stride': 1},
        pathOverride: path,
      );

      // 2. 读取并验证
      final cfg1 = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg1['engine'], equals('MLKit'));
      expect(cfg1['stride'], equals(1));
      expect(cfg1['strictness'], equals('strict')); // 默认值保留

      // 3. 再次写入（仅改 engine）
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: path,
      );

      // 4. 验证：表单优先，现有 stride 保留
      final cfg2 = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg2['engine'], equals('MoveNet')); // 表单覆盖
      expect(cfg2['stride'], equals(1)); // 现有保留
      expect(cfg2['strictness'], equals('strict')); // 默认值保留
    });

    // 测试 4: 非法 engine 枚举（大小写不敏感 + 回退）
    test('Should normalize invalid engine enum', () async {
      final path = '$testDir/invalid_engine.json';

      // 写入小写 engine
      await writeAppRuntimeConfig(
        {'engine': 'movenet'}, // 小写
        pathOverride: path,
      );

      // 验证：自动规范化为标准枚举值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['engine'], equals('MoveNet'));
    });

    test('Should fallback to default for unknown engine', () async {
      final path = '$testDir/unknown_engine.json';

      // 写入无效 engine
      await writeAppRuntimeConfig(
        {'engine': 'InvalidEngine'},
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['engine'], equals('MoveNet'));
    });

    // 测试 5: 非法 resolution（回退默认）
    test('Should fallback to default for invalid resolution', () async {
      final path = '$testDir/invalid_resolution.json';

      // 写入无效 resolution
      await writeAppRuntimeConfig(
        {'resolution': 'foo'}, // 不符合格式
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['resolution'], equals('1280x720'));
    });

    test('Should accept valid resolution formats', () async {
      final path = '$testDir/valid_resolution.json';

      // 写入有效 resolution
      await writeAppRuntimeConfig(
        {'resolution': '1920x1080'},
        pathOverride: path,
      );

      // 验证：保留有效值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['resolution'], equals('1920x1080'));
    });

    // 测试 6: 非法数值（stride/targetFps/cleanup.days）
    test('Should fallback to default for invalid stride', () async {
      final path = '$testDir/invalid_stride.json';

      // 写入无效 stride
      await writeAppRuntimeConfig(
        {'stride': 0}, // < 1
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['stride'], equals(2));
    });

    test('Should fallback to default for invalid targetFps', () async {
      final path = '$testDir/invalid_fps.json';

      // 写入无效 targetFps
      await writeAppRuntimeConfig(
        {'targetFps': -10},
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['targetFps'], equals(30));
    });

    test('Should round floating point numbers', () async {
      final path = '$testDir/float_numbers.json';

      // 写入浮点数
      await writeAppRuntimeConfig(
        {'stride': 3.7, 'targetFps': 25.3},
        pathOverride: path,
      );

      // 验证：自动取整
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['stride'], equals(4)); // 3.7 rounds to 4
      expect(cfg['targetFps'], equals(25)); // 25.3 rounds to 25
    });

    // 测试 7: privacy 嵌套对象
    test('Should normalize privacy.upload enum', () async {
      final path = '$testDir/privacy_test.json';

      // 写入有效 privacy 配置
      await writeAppRuntimeConfig(
        {
          'privacy': {
            'upload': 'video+keypoints',
            'confirmVideoUpload': false,
          }
        },
        pathOverride: path,
      );

      // 验证：保留有效值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['privacy']['upload'], equals('video+keypoints'));
      expect(cfg['privacy']['confirmVideoUpload'], equals(false));
    });

    test('Should fallback invalid privacy.upload', () async {
      final path = '$testDir/invalid_privacy.json';

      // 写入无效 privacy.upload
      await writeAppRuntimeConfig(
        {
          'privacy': {'upload': 'invalid-value'}
        },
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['privacy']['upload'], equals('keypoints-only'));
    });

    // 测试 8: 快照内容（writeRuntimeSnapshot → 原样写入）
    test('Should write runtime snapshot as-is', () async {
      final sessionRoot = '$testDir/session_001';

      final effectiveCfg = {
        'engine': 'MoveNet',
        'strictness': 'strict',
        'stride': 2,
        'customField': 'custom-value', // 自定义字段
      };

      await writeRuntimeSnapshot(sessionRoot, effectiveCfg);

      // 验证：文件存在
      final file = File('$sessionRoot/configs_snapshot.json');
      expect(await file.exists(), isTrue);

      // 验证：内容与传入 Map 完全一致（原样写入）
      final content = await file.readAsString();
      expect(content, contains('"engine": "MoveNet"'));
      expect(content, contains('"strictness": "strict"'));
      expect(content, contains('"stride": 2'));
      expect(content, contains('"customField": "custom-value"'));
    });

    // 测试 9: 参数组装（buildCliArgs → 返回正确三元组）
    test('Should build CLI args correctly', () {
      final args = buildCliArgs(
        pickedInput: '/path/to/video.mp4',
        sessionRoot: 'build/offline_out/session_001',
      );

      // 验证：三元组正确
      expect(args.inputPath, equals('/path/to/video.mp4'));
      expect(args.sessionRoot, equals('build/offline_out/session_001'));
      expect(args.configPath, equals('configs/app_runtime.json'));
    });

    test('Should allow empty pickedInput', () {
      final args = buildCliArgs(
        pickedInput: '',
        sessionRoot: 'build/offline_out/session_002',
      );

      // 验证：允许空字符串
      expect(args.inputPath, equals(''));
      expect(args.sessionRoot, equals('build/offline_out/session_002'));
    });

    test('Should allow custom configPath', () {
      final args = buildCliArgs(
        pickedInput: '/video.mp4',
        sessionRoot: 'session_root',
        configPath: 'custom/config.json',
      );

      // 验证：自定义 configPath
      expect(args.configPath, equals('custom/config.json'));
    });

    // 测试 10: JSON 解析失败（抛 ConfigInvalid）
    test('Should throw ConfigInvalid on JSON parse error', () async {
      final path = '$testDir/invalid_json.json';

      // 创建无效 JSON 文件
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString('{ invalid json }');

      // 验证：抛出 ConfigInvalid
      expect(
        () => readAppRuntimeConfig(pathOverride: path),
        throwsA(isA<ConfigInvalid>().having(
          (e) => e.message,
          'message',
          contains('invalid json'),
        )),
      );
    });

    test('Should throw ConfigInvalid when JSON is not object', () async {
      final path = '$testDir/array_json.json';

      // 创建数组 JSON
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString('[1, 2, 3]');

      // 验证：抛出 ConfigInvalid
      expect(
        () => readAppRuntimeConfig(pathOverride: path),
        throwsA(isA<ConfigInvalid>().having(
          (e) => e.message,
          'message',
          contains('not a JSON object'),
        )),
      );
    });

    // 测试 11: 未知字段保留（前向兼容）
    test('Should preserve unknown fields', () async {
      final path = '$testDir/unknown_fields.json';

      // 写入包含未知字段的配置
      await writeAppRuntimeConfig(
        {
          'engine': 'MoveNet',
          'customField': 'custom-value',
          'futureFeature': {'nested': 'data'},
        },
        pathOverride: path,
      );

      // 验证：未知字段被保留
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['engine'], equals('MoveNet'));
      expect(cfg['customField'], equals('custom-value'));
      expect(cfg['futureFeature'], isA<Map<dynamic, dynamic>>());
    });

    // 测试 12: cleanup.days 边界值
    test('Should validate cleanup.days boundary', () async {
      final path = '$testDir/cleanup_boundary.json';

      // 写入 cleanup.days = 0（合法）
      await writeAppRuntimeConfig(
        {
          'cleanup': {'days': 0}
        },
        pathOverride: path,
      );

      // 验证：允许 0
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['cleanup']['days'], equals(0));
    });

    test('Should fallback negative cleanup.days', () async {
      final path = '$testDir/cleanup_negative.json';

      // 写入 cleanup.days = -1（非法）
      await writeAppRuntimeConfig(
        {
          'cleanup': {'days': -1}
        },
        pathOverride: path,
      );

      // 验证：回退到默认值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['cleanup']['days'], equals(7));
    });

    // 测试 13: 深度嵌套合并
    test('Should deep merge nested objects', () async {
      final path = '$testDir/deep_merge.json';

      // 1. 写入初始配置（完整 privacy）
      await writeAppRuntimeConfig(
        {
          'privacy': {
            'upload': 'none',
            'confirmVideoUpload': false,
          }
        },
        pathOverride: path,
      );

      // 2. 再次写入（仅改 upload）
      await writeAppRuntimeConfig(
        {
          'privacy': {'upload': 'keypoints-only'}
        },
        pathOverride: path,
      );

      // 3. 验证：深度合并（confirmVideoUpload 保留）
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['privacy']['upload'], equals('keypoints-only'));
      expect(cfg['privacy']['confirmVideoUpload'], equals(false)); // 保留
    });

    // 测试 14: strictness 规范化
    test('Should normalize strictness (case insensitive)', () async {
      final path = '$testDir/strictness_case.json';

      // 写入大写 strictness
      await writeAppRuntimeConfig(
        {'strictness': 'STRICT'},
        pathOverride: path,
      );

      // 验证：规范化为标准枚举值
      final cfg = await readAppRuntimeConfig(pathOverride: path);
      expect(cfg['strictness'], equals('strict'));
    });
  });

  group('Exception Classes', () {
    test('ConfigInvalid should format correctly', () {
      final exception = ConfigInvalid('test message');

      expect(exception.toString(), contains('ConfigInvalid'));
      expect(exception.toString(), contains('test message'));
      expect(exception.message, equals('test message'));
    });
  });
}

