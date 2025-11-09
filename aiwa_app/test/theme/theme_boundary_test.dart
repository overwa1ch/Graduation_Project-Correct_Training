import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Theme Boundary Test
/// 
/// ✅ VALIDATES: Theme layer (lib/theme/**) contains NO business logic
/// 
/// This test ensures that:
/// 1. No theme files contain business decision keywords (if, switch on business data)
/// 2. No theme files read config files
/// 3. Theme files only contain style definitions
/// 
/// ❌ FAILS if theme files contain:
/// - if (strict), if (relaxed), if (config.xxx)
/// - switch (profile), switch (engine)
/// - ConfigSyncService, loadConfig, etc.

void main() {
  group('Theme Boundary Tests', () {
    final themeDir = Directory('lib/theme');
    
    test('Theme directory exists', () {
      expect(themeDir.existsSync(), isTrue, 
        reason: 'lib/theme directory should exist');
    });
    
    test('Theme files contain NO business logic keywords', () {
      if (!themeDir.existsSync()) {
        fail('lib/theme directory does not exist');
      }
      
      final themeFiles = themeDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      expect(themeFiles.isNotEmpty, isTrue, 
        reason: 'Should have at least one Dart file in lib/theme');
      
      final forbiddenPatterns = [
        // Business logic conditionals
        RegExp(r'if\s*\(\s*(strict|relaxed|custom|profile|config|threshold)'),
        RegExp(r'switch\s*\(\s*(profile|engine|config|threshold)'),
        
        // Config service usage
        RegExp(r'ConfigSyncService'),
        RegExp(r'loadConfig'),
        RegExp(r'saveConfig'),
        RegExp(r'config\.json'),
        
        // Business data reading
        RegExp(r'threshold_profile'),
        RegExp(r'cloud_enabled'),
      ];
      
      final violations = <String, List<String>>{};
      
      for (final file in themeFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        final fileViolations = <String>[];
        
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          
          // Skip comments
          if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
            continue;
          }
          
          for (final pattern in forbiddenPatterns) {
            if (pattern.hasMatch(line)) {
              fileViolations.add(
                'Line ${i + 1}: ${line.trim()}\n'
                '  Matched forbidden pattern: ${pattern.pattern}'
              );
            }
          }
        }
        
        if (fileViolations.isNotEmpty) {
          violations[file.path] = fileViolations;
        }
      }
      
      if (violations.isNotEmpty) {
        final errorMessage = StringBuffer();
        errorMessage.writeln('Theme boundary violations detected:');
        errorMessage.writeln();
        
        violations.forEach((file, fileViolations) {
          errorMessage.writeln('File: $file');
          for (final violation in fileViolations) {
            errorMessage.writeln('  $violation');
          }
          errorMessage.writeln();
        });
        
        errorMessage.writeln('❌ Theme files MUST NOT contain business logic.');
        errorMessage.writeln('   Use lib/ui/** or lib/services/** for business decisions.');
        
        fail(errorMessage.toString());
      }
    });
    
    test('colors.dart exports SemanticColors', () {
      final colorsFile = File('lib/theme/colors.dart');
      
      if (!colorsFile.existsSync()) {
        fail('lib/theme/colors.dart does not exist');
      }
      
      final content = colorsFile.readAsStringSync();
      
      expect(content.contains('class SemanticColors'), isTrue,
        reason: 'colors.dart should define SemanticColors class');
      
      expect(content.contains('static const Color success'), isTrue,
        reason: 'SemanticColors should define success color');
      
      expect(content.contains('static const Color warning'), isTrue,
        reason: 'SemanticColors should define warning color');
      
      expect(content.contains('static const Color error'), isTrue,
        reason: 'SemanticColors should define error color');
    });
    
    test('typography.dart contains only style definitions', () {
      final typographyFile = File('lib/theme/typography.dart');
      
      if (!typographyFile.existsSync()) {
        fail('lib/theme/typography.dart does not exist');
      }
      
      final content = typographyFile.readAsStringSync();
      
      // Should contain TextStyle definitions
      expect(content.contains('TextStyle'), isTrue,
        reason: 'typography.dart should define TextStyle');
      
      // Should NOT contain business logic
      expect(content.contains('if ('), isFalse,
        reason: 'typography.dart should not contain conditional logic');
      
      expect(content.contains('switch ('), isFalse,
        reason: 'typography.dart should not contain switch statements');
    });
    
    test('theme.dart contains only ThemeData definitions', () {
      final themeFile = File('lib/theme/theme.dart');
      
      if (!themeFile.existsSync()) {
        fail('lib/theme/theme.dart does not exist');
      }
      
      final content = themeFile.readAsStringSync();
      final lines = content.split('\n');
      
      // Should contain ThemeData
      expect(content.contains('ThemeData'), isTrue,
        reason: 'theme.dart should define ThemeData');
      
      // Should NOT contain business config reads
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Skip comments
        if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
          continue;
        }
        
        expect(line.contains('ConfigSyncService'), isFalse,
          reason: 'Line ${i + 1}: theme.dart should not use ConfigSyncService');
        
        expect(line.contains('loadConfig'), isFalse,
          reason: 'Line ${i + 1}: theme.dart should not load config');
      }
    });
    
    test('No hardcoded business thresholds in theme files', () {
      if (!themeDir.existsSync()) {
        fail('lib/theme directory does not exist');
      }
      
      final themeFiles = themeDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      final businessNumbers = [
        90.0, // Common score threshold
        70.0, // Common score threshold
        60.0, // Common score threshold
      ];
      
      final violations = <String>[];
      
      for (final file in themeFiles) {
        final content = file.readAsStringSync();
        
        // Check for hardcoded threshold-like values in conditions
        for (final threshold in businessNumbers) {
          final pattern = RegExp(r'if\s*\([^)]*' + threshold.toString());
          if (pattern.hasMatch(content)) {
            violations.add(
              '${file.path}: Contains threshold check for $threshold'
            );
          }
        }
      }
      
      if (violations.isNotEmpty) {
        fail(
          'Theme files contain hardcoded business thresholds:\n'
          '${violations.join('\n')}\n'
          '❌ Move business logic to lib/ui/** or lib/services/**'
        );
      }
    });
  });
}

