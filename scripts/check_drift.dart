// scripts/check_drift.dart
//
// 代码漂移快速扫描工具
//
// 目的：
// - 检测 aiwa_app 中是否重新实现了 aiwa_core 已有的功能
// - 发现可疑的关键词（角度计算、平滑算法、计数等）但未导入核心库
// - 提醒开发者使用核心库而不是重复实现
//
// 运行方式：
//   dart scripts/check_drift.dart
//
// 输出：
// - 如果发现可疑代码，会列出文件路径和关键词
// - 如果未发现问题，返回成功退出码

import 'dart:io';

void main(List<String> args) async {
  print('🔍 Scanning for code drift...\n');
  
  // 关键词：这些如果出现在 aiwa_app 中，可能是重复实现
  final suspiciousPatterns = [
    // 核心算法关键词
    _Pattern('angle.*calculate|calculate.*angle', '角度计算'),
    _Pattern('one.*euro.*filter|euro.*filter', 'OneEuro 平滑算法'),
    _Pattern('smooth.*keypoint|keypoint.*smooth', '关键点平滑'),
    _Pattern('compute.*quality|quality.*compute', '质量评估'),
    _Pattern('validate.*result|result.*validate|validate.*schema', 'Schema 验证'),
    _Pattern('keypoint.*name|name.*keypoint', '关键点名称'),
    _Pattern('parse.*neutral.*keypoint|neutral.*keypoint.*parse', '关键点序列解析'),
    _Pattern('count.*rep|rep.*count|countRep', '动作计数'),
    _Pattern('segment.*phase|phase.*segment', '阶段分割'),
  ];
  
  final appFiles = _findDartFiles('aiwa_app/lib');
  final violations = <_Violation>[];
  
  for (final file in appFiles) {
    // 跳过测试文件和平台特定代码
    if (file.contains('\\test\\') || file.contains('/test/') ||
        file.contains('\\native\\') || file.contains('/native/') ||
        file.contains('\\platform\\') || file.contains('/platform/') ||
        file.contains('\\ui\\') || file.contains('/ui/')) {
      continue;
    }
    
    final content = await File(file).readAsString();
    
    // 移除注释，减少误报（只检查实际代码）
    final codeOnly = _removeComments(content);
    
    // 检查是否导入了核心库
    final hasCoreImport = content.contains('package:aiwa_core/');
    final hasUnifiedImport = content.contains('package:aiwa_core/aiwa_core.dart');
    
    for (final pattern in suspiciousPatterns) {
      // 只在代码中搜索，不在注释中搜索
      if (RegExp(pattern.regex, caseSensitive: false).hasMatch(codeOnly)) {
        // 如果导入了核心库，可能是正常使用，跳过
        if (hasCoreImport) {
          continue;
        }
        
        // 检查是否是参数名或注释（误报）
        if (_isFalsePositive(content, pattern.regex)) {
          continue;
        }
        
        // 找到可疑代码
        violations.add(_Violation(
          file: file,
          pattern: pattern.description,
          suggestion: hasUnifiedImport 
              ? '已使用统一导出，但可能重复实现了功能'
              : '未导入核心库，可能重复实现了功能',
        ));
      }
    }
  }
  
  if (violations.isEmpty) {
    print('✅ No obvious code drift detected.');
    print('\n💡 Tips:');
    print('   - Use unified import: import \'package:aiwa_core/aiwa_core.dart\';');
    print('   - Check aiwa_core/lib/*/README.md before implementing new features');
    exit(0);
  } else {
    print('⚠️  Potential code drift detected:\n');
    
    // 按文件分组
    final byFile = <String, List<_Violation>>{};
    for (final v in violations) {
      byFile.putIfAbsent(v.file, () => []).add(v);
    }
    
    for (final entry in byFile.entries) {
      print('📄 ${entry.key}');
      for (final v in entry.value) {
        print('   ⚠️  ${v.pattern}');
        print('      💡 ${v.suggestion}');
      }
      print('');
    }
    
    print('💡 Recommendations:');
    print('   1. Check if aiwa_core already provides this functionality');
    print('   2. Use: import \'package:aiwa_core/aiwa_core.dart\';');
    print('   3. Refer to: docs/00-project/ARCHITECTURE_BOUNDARIES.md');
    print('   4. Use AI code review: docs/00-project/AI_CODE_REVIEW_PROMPT.md');
    print('');
    print('❌ Please verify these implementations are not duplicating aiwa_core functionality.');
    exit(1);
  }
}

List<String> _findDartFiles(String dir) {
  final result = <String>[];
  final directory = Directory(dir);
  
  if (!directory.existsSync()) {
    return result;
  }
  
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      result.add(entity.path);
    }
  }
  
  return result;
}

class _Pattern {
  final String regex;
  final String description;
  
  _Pattern(this.regex, this.description);
}

class _Violation {
  final String file;
  final String pattern;
  final String suggestion;
  
  _Violation({
    required this.file,
    required this.pattern,
    required this.suggestion,
  });
}

/// 移除注释，只保留实际代码
String _removeComments(String content) {
  // 简单实现：移除单行注释和多行注释
  // 注意：这不是完整的注释移除，但对于减少误报已经足够
  final lines = content.split('\n');
  final codeLines = <String>[];
  
  for (final line in lines) {
    // 移除单行注释
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || 
        trimmed.startsWith('///') ||
        trimmed.startsWith('*') ||
        trimmed.isEmpty) {
      continue;
    }
    
    // 移除行内注释
    final codeLine = line.split('//').first.trim();
    if (codeLine.isNotEmpty) {
      codeLines.add(codeLine);
    }
  }
  
  return codeLines.join('\n');
}

/// 检查是否是误报（参数名、注释等）
bool _isFalsePositive(String content, String pattern) {
  // 如果匹配的是注释中的内容，可能是误报
  final lines = content.split('\n');
  for (final line in lines) {
    if (RegExp(pattern, caseSensitive: false).hasMatch(line)) {
      final trimmed = line.trim();
      // 如果是注释行，跳过
      if (trimmed.startsWith('//') || 
          trimmed.startsWith('///') ||
          trimmed.startsWith('*')) {
        continue;
      }
      
      // 如果是在参数名或变量名中（如 keypointsPerFrame），可能是误报
      // 检查是否是函数参数或变量声明
      if (RegExp(r'^\s*(final|const|var|List|Map|String|int|double|bool)\s+.*' + pattern, caseSensitive: false).hasMatch(line) ||
          RegExp(r'^\s*.*\s+' + pattern + r'PerFrame|' + pattern + r'Properties', caseSensitive: false).hasMatch(line)) {
        return true; // 可能是参数名，误报
      }
    }
  }
  
  return false;
}

