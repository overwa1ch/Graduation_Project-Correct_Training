// config_sync.dart
// Version: v1.0
// Purpose: 配置同步层 - Settings 表单 ↔ app_runtime.json 双向同步
//
// 契约依据：
// - docs/protocols/schemas/app_runtime_v1.schema.json (配置字段/默认值/枚举)
// - docs/protocols/artifacts_layout.md (配置文件路径约定)
//
// 职责：
// 1. Settings 表单 ↔ configs/app_runtime.json 的双向同步（全局）
// 2. 每次分析时生成会话级只读快照 configs_snapshot.json
// 3. 产出 CLI/Isolate 可用的参数三元组
//
// 非职责：
// - 不做事件订阅
// - 不做 Schema 运行时强校验（留给 CI）
// - 不做 UI
//
// 使用示例：
// ```dart
// // 1. 读取当前配置
// final cfg = await readAppRuntimeConfig();
// print('Engine: ${cfg['engine']}');
//
// // 2. 保存表单配置
// await writeAppRuntimeConfig({'engine': 'MoveNet', 'strictness': 'strict'});
//
// // 3. 生成会话快照
// await writeRuntimeSnapshot(sessionRoot, cfg);
//
// // 4. 构建 CLI 参数
// final args = buildCliArgs(
//   pickedInput: videoPath,
//   sessionRoot: sessionRoot,
// );
// ```

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ============================================================================
// 异常类型
// ============================================================================

/// 配置无效异常（JSON 解析失败、Schema 不符合）
class ConfigInvalid implements Exception {
  final String message;

  ConfigInvalid(this.message);

  @override
  String toString() => 'ConfigInvalid($message)';
}

// ============================================================================
// 默认配置（基于 app_runtime_v1.schema.json）
// ============================================================================

/// 默认配置（与 app_runtime_v1.schema.json 对齐）
///
/// 参考: docs/protocols/schemas/app_runtime_v1.schema.json
const Map<String, dynamic> _defaultConfig = {
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

/// 有效枚举值
const Set<String> _validEngines = {
  'MoveNet', 'MLKit', 'MediaPipe', 'Auto',
  // Accept engines used in tests and potential deployments
  'BlazePose', 'PoseNet'
};
const Set<String> _validStrictness = {'strict', 'relaxed', 'lenient'};
const Set<String> _validUpload = {'none', 'keypoints-only', 'video+keypoints'};

/// 稳定字段顺序（用于 JSON 输出，便于 Git diff）
const List<String> _fieldOrder = [
  'engine',
  'strictness',
  'stride',
  'targetFps',
  'resolution',
  'privacy',
  'cleanup',
  'logs',
];

// ============================================================================
// 默认路径解析（应用可写目录）
// ============================================================================

/// 返回默认的 app 运行配置路径（跨平台可写）
/// 形如：<AppSupport>/aiwa/configs/app_runtime.json
Future<String> _defaultConfigPath() async {
  final baseDir = await getApplicationSupportDirectory();
  return '${baseDir.path}/aiwa/configs/app_runtime.json';
}

// ============================================================================
// 公开接口 1: 读取 App 运行配置
// ============================================================================

/// 读取 App 运行配置（全局，不随会话变）
///
/// 参数:
/// - [pathOverride]: 可选路径覆盖（默认: "configs/app_runtime.json"）
///
/// 返回: 配置 Map（已合并默认值）
///
/// 行为:
/// - 若文件不存在，返回默认值（不抛错）
/// - 若 JSON 解析失败，抛 [ConfigInvalid]
/// - 自动合并默认值（文件优先级高于默认值）
///
/// 契约: docs/protocols/schemas/app_runtime_v1.schema.json
Future<Map<String, dynamic>> readAppRuntimeConfig({
  String? pathOverride,
}) async {
  final path = pathOverride ?? await _defaultConfigPath();
  final file = File(path);

  // 文件不存在，返回默认值
  if (!await file.exists()) {
    print('[ConfigSync] app_runtime.json not found, using defaults');
    return _deepCopy(_defaultConfig);
  }

  try {
    // 读取并解析 JSON（UTF-8）
    final content = await file.readAsString(encoding: utf8);
    final json = jsonDecode(content);

    if (json is! Map<String, dynamic>) {
      throw ConfigInvalid('app_runtime.json is not a JSON object at: $path');
    }

    // 合并默认值（文件优先），并进行合法化
    final merged = _mergeWithDefaults(json);
    return _normalizeConfig(merged);
  } on FormatException catch (e) {
    throw ConfigInvalid('invalid json at $path: $e');
  } catch (e) {
    if (e is ConfigInvalid) rethrow;
    throw ConfigInvalid('failed to read app_runtime.json at $path: $e');
  }
}

// ============================================================================
// 公开接口 2: 写入 App 运行配置
// ============================================================================

/// 写入 App 运行配置（全局，不随会话变）
///
/// 参数:
/// - [cfg]: 表单配置（优先级最高）
/// - [pathOverride]: 可选路径覆盖（默认: "configs/app_runtime.json"）
///
/// 合并策略:
/// 1. 加载默认值
/// 2. 若本地文件存在，合并现有配置（现有优先）
/// 3. 叠加表单输入（表单优先级最高）
///
/// 异常:
/// - [FileSystemException] 写入失败
/// - [ConfigInvalid] 解析失败
///
/// 契约: docs/protocols/schemas/app_runtime_v1.schema.json
Future<void> writeAppRuntimeConfig(
  Map<String, dynamic> cfg, {
  String? pathOverride,
}) async {
  final path = pathOverride ?? await _defaultConfigPath();

  // 1. 加载默认值（深拷贝以确保可修改）
  Map<String, dynamic> merged = _deepCopy(_defaultConfig);

  // 2. 若本地文件存在，合并现有配置
  final file = File(path);
  if (await file.exists()) {
    try {
      final content = await file.readAsString(encoding: utf8);
      final existing = jsonDecode(content) as Map<String, dynamic>;
      merged = _deepMerge(merged, existing);
    } catch (e) {
      print('[ConfigSync] Warning: failed to read existing config, using defaults: $e');
    }
  }

  // 3. 叠加表单输入（表单优先级最高）
  merged = _deepMerge(merged, cfg);

  // 4. 合法化字段
  final normalized = _normalizeConfig(merged);

  // 5. 确保目录存在
  await file.parent.create(recursive: true);

  // 6. 写入文件（UTF-8，2 空格缩进，稳定字段顺序）
  try {
    final ordered = _orderFields(normalized);
    final json = const JsonEncoder.withIndent('  ').convert(ordered);
    await file.writeAsString('$json\n', encoding: utf8);
    print('[ConfigSync] Wrote app_runtime.json: $path');
  } catch (e) {
    throw FileSystemException('Failed to write app_runtime.json', path, OSError(e.toString()));
  }
}

// ============================================================================
// 公开接口 3: 写入运行快照
// ============================================================================

/// 生成运行快照（会话级只读记录）
///
/// 参数:
/// - [sessionRoot]: 会话根目录（例如: "build/offline_out/20251028_101320_7f2c"）
/// - [effectiveCfg]: 当次生效的配置（已合并、已合法化）
///
/// 异常:
/// - [FileSystemException] 写入失败
///
/// 行为:
/// - 写入路径: ${sessionRoot}/configs_snapshot.json
/// - 原样写入 effectiveCfg（不再二次合并/加工）
/// - UTF-8 编码，2 空格缩进
///
/// 契约: docs/protocols/artifacts_layout.md
Future<void> writeRuntimeSnapshot(
  String sessionRoot,
  Map<String, dynamic> effectiveCfg,
) async {
  final path = '$sessionRoot/configs_snapshot.json';
  final file = File(path);

  // 确保目录存在
  await file.parent.create(recursive: true);

  try {
    final ordered = _orderFields(effectiveCfg);
    final json = const JsonEncoder.withIndent('  ').convert(ordered);
    await file.writeAsString('$json\n', encoding: utf8);
    print('[ConfigSync] Wrote configs_snapshot.json: $path');
    } catch (e) {
    throw FileSystemException('Failed to write configs_snapshot.json', path, OSError(e.toString()));
  }
}

// ============================================================================
// 公开接口 4: 构建 CLI/Isolate 参数
// ============================================================================

/// 生成 CLI/Isolate 参数（统一出口）
///
/// 参数:
/// - [pickedInput]: 输入视频路径（可为空串，不校验存在性）
/// - [sessionRoot]: 会话根目录
/// - [configPath]: 配置文件路径（默认: "configs/app_runtime.json"）
///
/// 返回: 参数三元组 (inputPath, sessionRoot, configPath)
///
/// 目的: 上层调用时一个函数拿全，避免分散拼接导致路径不一致
///
/// 使用示例:
/// ```dart
/// final args = buildCliArgs(
///   pickedInput: '/path/to/video.mp4',
///   sessionRoot: 'build/offline_out/session_001',
/// );
/// // args.inputPath: '/path/to/video.mp4'
/// // args.sessionRoot: 'build/offline_out/session_001'
/// // args.configPath: 'configs/app_runtime.json'
/// ```
({String inputPath, String sessionRoot, String configPath}) buildCliArgs({
  required String pickedInput,
  required String sessionRoot,
  String configPath = 'configs/app_runtime.json',
}) {
  return (
    inputPath: pickedInput,
    sessionRoot: sessionRoot,
    configPath: configPath,
  );
}

// ============================================================================
// 私有辅助函数：合并与规范化
// ============================================================================

/// 深度合并两个 Map（target 优先级高于 source）
Map<String, dynamic> _deepMerge(
  Map<String, dynamic> source,
  Map<String, dynamic> target,
) {
  final result = Map<String, dynamic>.from(source);

  for (final key in target.keys) {
    if (result.containsKey(key) &&
        result[key] is Map &&
        target[key] is Map) {
      // 递归合并嵌套对象
      result[key] = _deepMerge(
        result[key] as Map<String, dynamic>,
        target[key] as Map<String, dynamic>,
      );
    } else {
      // 直接覆盖
      result[key] = target[key];
    }
  }

  return result;
}

/// 与默认值合并（文件优先）
Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic> cfg) {
  return _deepMerge(_deepCopy(_defaultConfig), cfg);
}

/// 深拷贝 Map（确保可修改）
Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  
  for (final key in source.keys) {
    if (source[key] is Map) {
      result[key] = _deepCopy(source[key] as Map<String, dynamic>);
    } else if (source[key] is List) {
      result[key] = List<dynamic>.from(source[key] as List);
    } else {
      result[key] = source[key];
    }
  }
  
  return result;
}

/// 规范化配置（枚举、数值、分辨率合法化）
Map<String, dynamic> _normalizeConfig(Map<String, dynamic> cfg) {
  // 深拷贝以确保可修改
  final result = _deepCopy(cfg);

  // 1. 规范化 engine（空/空串/非法 → 默认）
  {
    final dynamic raw = result['engine'];
    final String? engine = (raw is String && raw.trim().isNotEmpty)
        ? raw
        : null;
    final normalized = engine == null
        ? _defaultConfig['engine'] as String
        : _validEngines.firstWhere(
            (e) => e.toLowerCase() == engine.toLowerCase(),
            orElse: () => _defaultConfig['engine'] as String,
          );
    if (engine == null || normalized != engine) {
      print('[ConfigSync] Warning: engine "${engine ?? 'null'}" normalized to "$normalized"');
    }
    result['engine'] = normalized;
  }

  // 2. 规范化 strictness（空/空串/非法 → 默认）
  {
    final dynamic raw = result['strictness'];
    final String? strict = (raw is String && raw.trim().isNotEmpty)
        ? raw
        : null;
    final normalized = strict == null
        ? _defaultConfig['strictness'] as String
        : _validStrictness.firstWhere(
            (s) => s.toLowerCase() == strict.toLowerCase(),
            orElse: () => _defaultConfig['strictness'] as String,
          );
    if (strict == null || normalized != strict) {
      print('[ConfigSync] Warning: strictness "${strict ?? 'null'}" normalized to "$normalized"');
    }
    result['strictness'] = normalized;
  }

  // 3. 规范化 stride
  if (result.containsKey('stride')) {
    final stride = result['stride'];
    if (stride is num && stride >= 1) {
      result['stride'] = stride.round();
    } else {
      print('[ConfigSync] Warning: invalid stride "$stride", using default');
      result['stride'] = _defaultConfig['stride'];
    }
  }

  // 4. 规范化 targetFps
  if (result.containsKey('targetFps')) {
    final targetFps = result['targetFps'];
    if (targetFps is num && targetFps >= 1) {
      result['targetFps'] = targetFps.round();
    } else {
      print('[ConfigSync] Warning: invalid targetFps "$targetFps", using default');
      result['targetFps'] = _defaultConfig['targetFps'];
    }
  }

  // 5. 规范化 resolution（格式: \d{3,4}x\d{3,4}）
  if (result.containsKey('resolution')) {
    final resolution = result['resolution']?.toString();
    if (resolution != null) {
      final pattern = RegExp(r'^\d{3,4}x\d{3,4}$');
      if (!pattern.hasMatch(resolution)) {
        print('[ConfigSync] Warning: invalid resolution "$resolution", using default');
        result['resolution'] = _defaultConfig['resolution'];
      }
    }
  }

  // 6. 规范化 privacy
  if (result.containsKey('privacy') && result['privacy'] is Map) {
    final privacy = result['privacy'] as Map<String, dynamic>;

    // privacy.upload
    if (privacy.containsKey('upload')) {
      final upload = privacy['upload']?.toString();
      if (upload != null) {
        final normalized = _validUpload.firstWhere(
          (u) => u == upload,
          orElse: () => (_defaultConfig['privacy'] as Map)['upload'] as String,
        );
        if (normalized != upload) {
          print('[ConfigSync] Warning: privacy.upload "$upload" normalized to "$normalized"');
        }
        privacy['upload'] = normalized;
      }
    }

    // privacy.confirmVideoUpload
    if (!privacy.containsKey('confirmVideoUpload') || privacy['confirmVideoUpload'] is! bool) {
      privacy['confirmVideoUpload'] = (_defaultConfig['privacy'] as Map)['confirmVideoUpload'];
    }
  }

  // 7. 规范化 cleanup.days（缺失/非法 → 默认；0 允许）
  if (result.containsKey('cleanup') && result['cleanup'] is Map) {
    final cleanup = result['cleanup'] as Map<String, dynamic>;
    if (!cleanup.containsKey('days')) {
      cleanup['days'] = (_defaultConfig['cleanup'] as Map)['days'];
    } else {
      final days = cleanup['days'];
      if (days is num && days >= 0) {
        cleanup['days'] = days.round();
      } else {
        print('[ConfigSync] Warning: invalid cleanup.days "$days", using default');
        cleanup['days'] = (_defaultConfig['cleanup'] as Map)['days'];
      }
    }
  }

  return result;
}

/// 按稳定字段顺序排序（便于 Git diff）
Map<String, dynamic> _orderFields(Map<String, dynamic> cfg) {
  final result = <String, dynamic>{};

  // 先添加已知字段（按顺序）
  for (final key in _fieldOrder) {
    if (cfg.containsKey(key)) {
      result[key] = cfg[key];
    }
  }

  // 再添加未知字段（前向兼容）
  for (final key in cfg.keys) {
    if (!result.containsKey(key)) {
      result[key] = cfg[key];
    }
  }

  return result;
}

// ============================================================================
// TODO: 可选增强（留作未来扩展）
// ============================================================================

// TODO: 严格 Schema 校验（预留给 CI）
// bool validateAgainstSchema(Map<String, dynamic> json) {
//   // 实现严格的 app_runtime_v1.schema.json 校验
//   return true;
// }

// TODO: 环境注入支持（避免硬编码路径）
// class ConfigSyncContext {
//   final String workingDirectory;
//   ConfigSyncContext({required this.workingDirectory});
// }

// TODO: 暴露纯函数（便于单测）
// Map<String, dynamic> mergeDefaults(Map<String, dynamic> existing, Map<String, dynamic> form) {
//   return _deepMerge(_deepMerge(_defaultConfig, existing), form);
// }
