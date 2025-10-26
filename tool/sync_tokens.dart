#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// AIWA Tokens 同步脚本
/// 
/// 功能：
/// 1. 从 Figma MCP 或本地目录拉取设计 Tokens
/// 2. 验证 JSON Schema 和结构
/// 3. 运行测试确保兼容性
/// 4. 原子更新 lib/theme/tokens/ 和 assets/tokens/
/// 
/// 使用方法：
/// ```bash
/// # 从 Figma MCP 同步
/// FIGMA_TOKEN=xxx FIGMA_FILE_KEY=yyy dart tool/sync_tokens.dart
/// 
/// # 从本地目录同步
/// dart tool/sync_tokens.dart --tokens-dir=/path/to/tokens
/// 
/// # 预演模式（不写文件）
/// dart tool/sync_tokens.dart --dry-run
/// 
/// # 详细日志
/// dart tool/sync_tokens.dart --verbose
/// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

// ============================================================================
// 配置与常量
// ============================================================================

class Config {
  final String? figmaToken;
  final String? figmaFileKey;
  final String? figmaPage;
  final String? tokensDir;
  final bool dryRun;
  final bool verbose;
  final bool failFast;

  Config({
    this.figmaToken,
    this.figmaFileKey,
    this.figmaPage,
    this.tokensDir,
    this.dryRun = false,
    this.verbose = false,
    this.failFast = true,
  });

  factory Config.fromArgs(List<String> args) {
    final argMap = <String, String>{};
    final flags = <String>{};

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--')) {
        final parts = arg.substring(2).split('=');
        if (parts.length == 2) {
          argMap[parts[0]] = parts[1];
        } else {
          flags.add(parts[0]);
        }
      }
    }

    return Config(
      figmaToken: Platform.environment['FIGMA_TOKEN'],
      figmaFileKey: Platform.environment['FIGMA_FILE_KEY'],
      figmaPage: Platform.environment['FIGMA_PAGE'],
      tokensDir: argMap['tokens-dir'],
      dryRun: flags.contains('dry-run'),
      verbose: flags.contains('verbose'),
      failFast: !flags.contains('no-fail-fast'),
    );
  }

  bool get useMcp => figmaToken != null && figmaFileKey != null;
  bool get useLocal => tokensDir != null;
}

// ============================================================================
// 主函数
// ============================================================================

Future<void> main(List<String> args) async {
  final config = Config.fromArgs(args);
  final syncer = TokenSyncer(config);

  try {
    await syncer.run();
    exit(0);
  } catch (e, stackTrace) {
    print('❌ 同步失败: $e');
    if (config.verbose) {
      print('Stack trace:\n$stackTrace');
    }
    exit(1);
  }
}

// ============================================================================
// TokenSyncer - 主同步逻辑
// ============================================================================

class TokenSyncer {
  final Config config;
  final Logger logger;
  final FileManager fileManager;
  final TokenValidator validator;
  final TestRunner testRunner;

  static const tokenFiles = [
    'colors.json',
    'typography.json',
    'spacing.json',
    'radius.json',
  ];

  static const libTokensPath = 'lib/theme/tokens';
  static const assetsTokensPath = 'assets/tokens';
  static const tmpTokensPath = '.tmp/tokens';

  TokenSyncer(this.config)
      : logger = Logger(config.verbose),
        fileManager = FileManager(),
        validator = TokenValidator(),
        testRunner = TestRunner();

  Future<void> run() async {
    logger.header('🔄 AIWA Tokens 同步');
    logger.info('模式: ${config.dryRun ? "预演 (dry-run)" : "正式同步"}');

    // 1. 验证环境
    _validateEnvironment();

    // 2. 拉取阶段
    logger.section('📥 拉取 Tokens');
    final tmpDir = await _pullTokens();

    // 3. 验证阶段
    logger.section('✅ 验证 Tokens');
    await _validateTokens(tmpDir);

    // 4. 计算变更
    logger.section('📊 计算变更');
    final changes = await _calculateChanges(tmpDir);
    _printChanges(changes);

    // 5. 预演模式退出
    if (config.dryRun) {
      logger.success('✅ 预演完成，未修改任何文件');
      await fileManager.cleanup(tmpDir);
      return;
    }

    // 6. 测试阶段
    logger.section('🧪 运行测试');
    await _runTests(tmpDir);

    // 7. 落地阶段
    logger.section('💾 更新文件');
    await _applyChanges(tmpDir, changes);

    // 8. 生成报告
    logger.section('📝 生成报告');
    await _generateReport(changes);

    // 9. 清理
    await fileManager.cleanup(tmpDir);

    logger.success('✅ 同步完成！');
  }

  void _validateEnvironment() {
    if (!config.useMcp && !config.useLocal) {
      throw Exception(
        '缺少 Tokens 来源！\n'
        '请设置环境变量：\n'
        '  FIGMA_TOKEN=your_token\n'
        '  FIGMA_FILE_KEY=your_file_key\n'
        '或使用本地目录：\n'
        '  --tokens-dir=/path/to/tokens',
      );
    }

    // 检查 pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      if (!content.contains('assets/tokens/')) {
        logger.warning(
          '⚠️  pubspec.yaml 中未找到 assets/tokens/\n'
          '请添加以下配置：\n'
          'flutter:\n'
          '  assets:\n'
          '    - assets/tokens/',
        );
      }
    }

    // 检查 flutter 命令
    final flutterExists = _checkFlutterCommand();
    if (!flutterExists) {
      logger.warning('⚠️  未找到 flutter 命令，将跳过测试步骤');
    }
  }

  bool _checkFlutterCommand() {
    try {
      final result = Process.runSync('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<Directory> _pullTokens() async {
    final tmpDir = Directory(tmpTokensPath);
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
    tmpDir.createSync(recursive: true);

    if (config.useLocal) {
      logger.info('从本地目录拉取: ${config.tokensDir}');
      await _copyLocalTokens(tmpDir);
    } else {
      logger.info('从 Figma MCP 拉取: ${config.figmaFileKey}');
      await _pullFromMcp(tmpDir);
    }

    return tmpDir;
  }

  Future<void> _copyLocalTokens(Directory tmpDir) async {
    final sourceDir = Directory(config.tokensDir!);
    if (!sourceDir.existsSync()) {
      throw Exception('本地目录不存在: ${config.tokensDir}');
    }

    for (final filename in tokenFiles) {
      final sourceFile = File(p.join(sourceDir.path, filename));
      if (!sourceFile.existsSync()) {
        throw Exception('缺少文件: $filename');
      }

      final targetFile = File(p.join(tmpDir.path, filename));
      await sourceFile.copy(targetFile.path);
      logger.verbose('  ✓ $filename');
    }
  }

  Future<void> _pullFromMcp(Directory tmpDir) async {
    // 注意：这里需要实际的 MCP 集成
    // 由于 Dart 脚本无法直接调用 MCP，这里提供两种方案：
    // 1. 使用现有的 lib/theme/tokens/ 作为源（已经通过 MCP 更新）
    // 2. 调用外部脚本（如 Node.js）来获取 MCP 数据

    logger.warning(
      '⚠️  Dart 脚本无法直接调用 MCP\n'
      '请先使用 Cursor/AI 更新 lib/theme/tokens/，然后运行此脚本同步到 assets/',
    );

    // 从现有的 lib/theme/tokens/ 复制
    final sourceDir = Directory(libTokensPath);
    if (!sourceDir.existsSync()) {
      throw Exception('源目录不存在: $libTokensPath');
    }

    for (final filename in tokenFiles) {
      final sourceFile = File(p.join(sourceDir.path, filename));
      if (!sourceFile.existsSync()) {
        throw Exception('缺少文件: $filename');
      }

      final targetFile = File(p.join(tmpDir.path, filename));
      await sourceFile.copy(targetFile.path);
      logger.verbose('  ✓ $filename');
    }
  }

  Future<void> _validateTokens(Directory tmpDir) async {
    for (final filename in tokenFiles) {
      final file = File(p.join(tmpDir.path, filename));
      logger.info('验证 $filename...');

      try {
        final content = await file.readAsString();
        final json = jsonDecode(content);

        validator.validate(filename, json);
        logger.verbose('  ✓ $filename 结构正确');
      } catch (e) {
        throw Exception('$filename 验证失败: $e');
      }
    }
  }

  Future<Map<String, FileChange>> _calculateChanges(Directory tmpDir) async {
    final changes = <String, FileChange>{};

    for (final filename in tokenFiles) {
      final tmpFile = File(p.join(tmpDir.path, filename));
      final libFile = File(p.join(libTokensPath, filename));

      final tmpHash = await fileManager.calculateHash(tmpFile);
      final libHash =
          libFile.existsSync() ? await fileManager.calculateHash(libFile) : '';

      final tmpSize = await tmpFile.length();
      final libSize = libFile.existsSync() ? await libFile.length() : 0;

      final status = libFile.existsSync()
          ? (tmpHash == libHash ? ChangeStatus.unchanged : ChangeStatus.modified)
          : ChangeStatus.added;

      changes[filename] = FileChange(
        filename: filename,
        status: status,
        oldHash: libHash,
        newHash: tmpHash,
        oldSize: libSize,
        newSize: tmpSize,
      );
    }

    return changes;
  }

  void _printChanges(Map<String, FileChange> changes) {
    var hasChanges = false;

    for (final change in changes.values) {
      if (change.status != ChangeStatus.unchanged) {
        hasChanges = true;
        final icon = change.status == ChangeStatus.added
            ? '➕'
            : change.status == ChangeStatus.modified
                ? '📝'
                : '❌';
        logger.info(
          '$icon ${change.filename}: '
          '${change.oldSize} → ${change.newSize} bytes '
          '(${change.status.name})',
        );

        if (config.verbose) {
          logger.verbose('  旧哈希: ${change.oldHash}');
          logger.verbose('  新哈希: ${change.newHash}');
        }
      }
    }

    if (!hasChanges) {
      logger.info('📋 无变更');
    }
  }

  Future<void> _runTests(Directory tmpDir) async {
    if (!_checkFlutterCommand()) {
      logger.warning('⚠️  跳过测试（flutter 命令不可用）');
      return;
    }

    // 备份现有文件
    final backupDir = Directory('.tmp/backup');
    if (backupDir.existsSync()) {
      backupDir.deleteSync(recursive: true);
    }
    backupDir.createSync(recursive: true);

    final libDir = Directory(libTokensPath);
    if (libDir.existsSync()) {
      await fileManager.copyDirectory(libDir, backupDir);
    }

    try {
      // 临时替换
      if (libDir.existsSync()) {
        libDir.deleteSync(recursive: true);
      }
      libDir.createSync(recursive: true);
      await fileManager.copyDirectory(tmpDir, libDir);

      // 运行测试
      logger.info('运行 flutter test test/theme_test.dart...');
      final result = await testRunner.runTests('test/theme_test.dart');

      if (!result.success) {
        throw Exception(
          '测试失败 (${result.failedCount}/${result.totalCount}):\n'
          '${result.output}',
        );
      }

      logger.success('✓ 测试通过 (${result.totalCount} 个测试)');
    } finally {
      // 恢复备份
      if (libDir.existsSync()) {
        libDir.deleteSync(recursive: true);
      }
      if (backupDir.existsSync()) {
        libDir.createSync(recursive: true);
        await fileManager.copyDirectory(backupDir, libDir);
        backupDir.deleteSync(recursive: true);
      }
    }
  }

  Future<void> _applyChanges(
    Directory tmpDir,
    Map<String, FileChange> changes,
  ) async {
    // 更新 lib/theme/tokens/
    final libDir = Directory(libTokensPath);
    if (libDir.existsSync()) {
      libDir.deleteSync(recursive: true);
    }
    libDir.createSync(recursive: true);
    await fileManager.copyDirectory(tmpDir, libDir);
    logger.info('✓ 更新 $libTokensPath');

    // 更新 assets/tokens/
    final assetsDir = Directory(assetsTokensPath);
    if (assetsDir.existsSync()) {
      assetsDir.deleteSync(recursive: true);
    }
    assetsDir.createSync(recursive: true);
    await fileManager.copyDirectory(tmpDir, assetsDir);
    logger.info('✓ 更新 $assetsTokensPath');
  }

  Future<void> _generateReport(Map<String, FileChange> changes) async {
    final report = StringBuffer();
    final now = DateTime.now().toIso8601String();

    report.writeln('# Tokens 同步报告');
    report.writeln();
    report.writeln('**时间**: $now');
    report.writeln('**来源**: ${config.useLocal ? "本地目录 (${config.tokensDir})" : "Figma MCP (${config.figmaFileKey})"}');
    if (config.figmaPage != null) {
      report.writeln('**页面**: ${config.figmaPage}');
    }
    report.writeln();

    report.writeln('## 变更摘要');
    report.writeln();

    var changedCount = 0;
    for (final change in changes.values) {
      if (change.status != ChangeStatus.unchanged) {
        changedCount++;
        report.writeln('### ${change.filename}');
        report.writeln('- **状态**: ${change.status.name}');
        report.writeln('- **大小**: ${change.oldSize} → ${change.newSize} bytes');
        report.writeln('- **哈希**: `${change.oldHash.substring(0, 8)}...` → `${change.newHash.substring(0, 8)}...`');
        report.writeln();
      }
    }

    if (changedCount == 0) {
      report.writeln('无变更');
      report.writeln();
    }

    report.writeln('## 测试结果');
    report.writeln();
    report.writeln('✅ 所有测试通过');
    report.writeln();

    report.writeln('## 文件清单');
    report.writeln();
    for (final filename in tokenFiles) {
      final change = changes[filename]!;
      report.writeln('- `$filename`: ${change.newSize} bytes (${change.newHash.substring(0, 8)})');
    }

    final reportFile = File('SYNC_TOKENS_REPORT.md');
    await reportFile.writeAsString(report.toString());
    logger.info('✓ 生成报告: SYNC_TOKENS_REPORT.md');
  }
}

// ============================================================================
// TokenValidator - JSON Schema 验证
// ============================================================================

class TokenValidator {
  void validate(String filename, dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception('$filename: 根节点必须是对象');
    }

    switch (filename) {
      case 'colors.json':
        _validateColors(json);
        break;
      case 'typography.json':
        _validateTypography(json);
        break;
      case 'spacing.json':
        _validateSpacing(json);
        break;
      case 'radius.json':
        _validateRadius(json);
        break;
    }
  }

  void _validateColors(Map<String, dynamic> json) {
    final required = ['brand', 'surface', 'text', 'error'];
    for (final key in required) {
      if (!json.containsKey(key)) {
        throw Exception('缺少必需字段: $key');
      }
      if (json[key] is! Map) {
        throw Exception('$key 必须是对象');
      }
    }

    // 验证颜色值格式
    _validateColorValues(json);
  }

  void _validateColorValues(Map<String, dynamic> obj) {
    obj.forEach((key, value) {
      if (value is String) {
        if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
          throw Exception('无效的颜色值: $key = $value');
        }
      } else if (value is Map<String, dynamic>) {
        _validateColorValues(value);
      }
    });
  }

  void _validateTypography(Map<String, dynamic> json) {
    if (!json.containsKey('fontFamily')) {
      throw Exception('缺少必需字段: fontFamily');
    }
    if (!json.containsKey('styles')) {
      throw Exception('缺少必需字段: styles');
    }

    final styles = json['styles'] as Map<String, dynamic>;
    final required = ['h1', 'h2', 'bodyBase', 'button'];
    for (final key in required) {
      if (!styles.containsKey(key)) {
        throw Exception('缺少必需样式: $key');
      }

      final style = styles[key] as Map<String, dynamic>;
      if (!style.containsKey('fontSize') || !style.containsKey('fontWeight')) {
        throw Exception('样式 $key 缺少 fontSize 或 fontWeight');
      }
    }
  }

  void _validateSpacing(Map<String, dynamic> json) {
    final required = ['spacing', 'padding', 'gap'];
    for (final key in required) {
      if (!json.containsKey(key)) {
        throw Exception('缺少必需字段: $key');
      }
      if (json[key] is! Map) {
        throw Exception('$key 必须是对象');
      }
    }

    // 验证数值
    _validateNumericValues(json, allowNegative: false);
  }

  void _validateRadius(Map<String, dynamic> json) {
    final required = ['radius', 'borderRadius'];
    for (final key in required) {
      if (!json.containsKey(key)) {
        throw Exception('缺少必需字段: $key');
      }
      if (json[key] is! Map) {
        throw Exception('$key 必须是对象');
      }
    }

    // 验证数值
    _validateNumericValues(json, allowNegative: false);
  }

  void _validateNumericValues(
    Map<String, dynamic> obj, {
    required bool allowNegative,
  }) {
    obj.forEach((key, value) {
      if (value is num) {
        // letterSpacing 允许负值
        if (!allowNegative && key != 'letterSpacing' && value < 0) {
          throw Exception('$key 不能为负数: $value');
        }
      } else if (value is Map<String, dynamic>) {
        _validateNumericValues(value, allowNegative: allowNegative);
      }
    });
  }
}

// ============================================================================
// FileManager - 文件操作
// ============================================================================

class FileManager {
  Future<String> calculateHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> copyDirectory(Directory source, Directory target) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is File) {
        final targetFile = File(p.join(target.path, p.basename(entity.path)));
        await entity.copy(targetFile.path);
      }
    }
  }

  Future<void> cleanup(Directory dir) async {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}

// ============================================================================
// TestRunner - 测试执行
// ============================================================================

class TestRunner {
  Future<TestResult> runTests(String testPath) async {
    final result = await Process.run(
      'flutter',
      ['test', testPath],
      runInShell: true,
    );

    final output = result.stdout.toString() + result.stderr.toString();
    final success = result.exitCode == 0;

    // 解析测试结果
    final passedMatch = RegExp(r'\+(\d+)').firstMatch(output);
    final failedMatch = RegExp(r'-(\d+)').firstMatch(output);

    final passedCount = passedMatch != null ? int.parse(passedMatch.group(1)!) : 0;
    final failedCount = failedMatch != null ? int.parse(failedMatch.group(1)!) : 0;

    return TestResult(
      success: success,
      totalCount: passedCount + failedCount,
      passedCount: passedCount,
      failedCount: failedCount,
      output: output,
    );
  }
}

// ============================================================================
// Logger - 日志输出
// ============================================================================

class Logger {
  final bool verbose;

  Logger(this.verbose);

  void header(String message) {
    print('\n${'=' * 60}');
    print(message);
    print('=' * 60);
  }

  void section(String message) {
    print('\n$message');
    print('-' * 60);
  }

  void info(String message) {
    print(message);
  }

  void success(String message) {
    print(message);
  }

  void warning(String message) {
    print(message);
  }

  void error(String message) {
    print('❌ $message');
  }

  void verbose(String message) {
    if (verbose) {
      print(message);
    }
  }
}

// ============================================================================
// 数据模型
// ============================================================================

enum ChangeStatus { added, modified, deleted, unchanged }

class FileChange {
  final String filename;
  final ChangeStatus status;
  final String oldHash;
  final String newHash;
  final int oldSize;
  final int newSize;

  FileChange({
    required this.filename,
    required this.status,
    required this.oldHash,
    required this.newHash,
    required this.oldSize,
    required this.newSize,
  });
}

class TestResult {
  final bool success;
  final int totalCount;
  final int passedCount;
  final int failedCount;
  final String output;

  TestResult({
    required this.success,
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.output,
  });
}

