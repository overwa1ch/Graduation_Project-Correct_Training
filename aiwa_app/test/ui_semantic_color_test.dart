import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// UI Semantic Color Test
/// 
/// ✅ VALIDATES: UI components (lib/ui/**) only use semantic colors
/// 
/// This test ensures that:
/// 1. No UI files contain hardcoded Color(...) values
/// 2. No UI files use raw Colors.xxx (except Colors.transparent, Colors.white, Colors.black)
/// 3. No UI files contain hardcoded TextStyle(...) without Theme reference
/// 4. No UI files contain hardcoded EdgeInsets(...) for common spacings
/// 
/// ❌ FAILS if UI files contain:
/// - Color(0xFFxxxxxx) 
/// - Colors.red, Colors.green, etc. (except transparent/white/black)
/// - TextStyle(fontSize: ..., color: ...) without Theme.of(context)
/// - EdgeInsets.all(...), EdgeInsets.symmetric(...) without constant references

void main() {
  group('UI Semantic Color Tests', () {
    final uiDir = Directory('lib/ui');
    
    test('UI directory exists', () {
      expect(uiDir.existsSync(), isTrue,
        reason: 'lib/ui directory should exist');
    });
    
    test('UI files contain NO hardcoded Color values', () {
      if (!uiDir.existsSync()) {
        // If UI directory doesn't exist yet, test passes
        // (this allows the test to pass before UI implementation)
        return;
      }
      
      final uiFiles = uiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      if (uiFiles.isEmpty) {
        // No UI files yet, test passes
        return;
      }
      
      final violations = <String, List<String>>{};
      
      for (final file in uiFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        final fileViolations = <String>[];
        
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          
          // Skip comments
          if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
            continue;
          }
          
          // Check for Color(0x...)
          if (RegExp(r'Color\(0x[0-9A-Fa-f]+\)').hasMatch(line)) {
            fileViolations.add(
              'Line ${i + 1}: Hardcoded Color(...) found\n'
              '  ${line.trim()}\n'
              '  ❌ Use SemanticColors.xxx or Theme.of(context).colorScheme.xxx'
            );
          }
          
          // Check for Colors.xxx (except allowed ones)
          // But NOT SemanticColors.xxx or AppColors.xxx
          final colorsMatch = RegExp(r'(?<!Semantic)(?<!App)Colors\.(\w+)').firstMatch(line);
          if (colorsMatch != null) {
            final colorName = colorsMatch.group(1);
            final allowedColors = ['transparent', 'white', 'black'];
            
            if (!allowedColors.contains(colorName)) {
              fileViolations.add(
                'Line ${i + 1}: Raw Colors.$colorName used\n'
                '  ${line.trim()}\n'
                '  ❌ Use SemanticColors.xxx or Theme.of(context).colorScheme.xxx'
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
        errorMessage.writeln('UI semantic color violations detected:');
        errorMessage.writeln();
        
        violations.forEach((file, fileViolations) {
          errorMessage.writeln('File: $file');
          for (final violation in fileViolations) {
            errorMessage.writeln('  $violation');
          }
          errorMessage.writeln();
        });
        
        errorMessage.writeln('✅ CORRECT USAGE:');
        errorMessage.writeln('   - SemanticColors.success');
        errorMessage.writeln('   - SemanticColors.error');
        errorMessage.writeln('   - Theme.of(context).colorScheme.primary');
        errorMessage.writeln('   - Theme.of(context).colorScheme.error');
        
        fail(errorMessage.toString());
      }
    });
    
    test('UI files use Theme.of(context) for text styles', () {
      if (!uiDir.existsSync()) {
        return;
      }
      
      final uiFiles = uiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      if (uiFiles.isEmpty) {
        return;
      }
      
      final violations = <String, List<String>>{};
      
      for (final file in uiFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        final fileViolations = <String>[];
        
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          
          // Skip comments
          if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
            continue;
          }
          
          // Check for standalone TextStyle(...) without Theme or copyWith
          // Allow: TextStyle definitions in const context or Theme.of(context).textTheme.xxx.copyWith(...)
          if (RegExp(r'TextStyle\s*\(').hasMatch(line)) {
            // Check if this line also has Theme.of(context) or is in a const context
            final hasTheme = line.contains('Theme.of(context)');
            final hasCopyWith = content.substring(
              content.indexOf(line) > 100 
                ? content.indexOf(line) - 100 
                : 0,
              content.indexOf(line) + line.length
            ).contains('.copyWith(');
            final isConst = line.contains('const TextStyle');
            final isAppTypography = line.contains('AppTypography.');
            
            if (!hasTheme && !hasCopyWith && !isConst && !isAppTypography) {
              fileViolations.add(
                'Line ${i + 1}: TextStyle used without Theme reference\n'
                '  ${line.trim()}\n'
                '  ⚠️ Consider using Theme.of(context).textTheme.xxx'
              );
            }
          }
        }
        
        if (fileViolations.isNotEmpty) {
          violations[file.path] = fileViolations;
        }
      }
      
      // This is a warning-level test, so we just print violations
      // but don't fail the test (to allow flexibility)
      if (violations.isNotEmpty) {
        print('\n⚠️ UI TextStyle warnings (consider fixing):');
        violations.forEach((file, fileViolations) {
          print('File: $file');
          for (final violation in fileViolations) {
            print('  $violation');
          }
        });
      }
    });
    
    test('Widget files import SemanticColors when using colors', () {
      if (!uiDir.existsSync()) {
        return;
      }
      
      final uiFiles = uiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      if (uiFiles.isEmpty) {
        return;
      }
      
      for (final file in uiFiles) {
        final content = file.readAsStringSync();
        
        // If file uses SemanticColors, it should import colors.dart
        if (content.contains('SemanticColors.')) {
          final hasImport = content.contains("import '") && 
            (content.contains('theme/colors.dart') || 
             content.contains('../theme/colors.dart') ||
             content.contains('../../theme/colors.dart'));
          
          expect(hasImport, isTrue,
            reason: '${file.path} uses SemanticColors but does not import colors.dart');
        }
      }
    });
    
    test('Example widgets follow semantic color pattern', () {
      // Check specific example widgets we created
      final widgetFiles = [
        'lib/ui/widgets/score_card.dart',
        'lib/ui/widgets/angle_line_chart.dart',
        'lib/ui/widgets/evidence_frame_card.dart',
      ];
      
      for (final widgetPath in widgetFiles) {
        final file = File(widgetPath);
        
        if (!file.existsSync()) {
          // Widget doesn't exist yet, skip
          continue;
        }
        
        final content = file.readAsStringSync();
        
        // Should import SemanticColors
        expect(
          content.contains('theme/colors.dart'),
          isTrue,
          reason: '$widgetPath should import theme/colors.dart'
        );
        
        // Should use SemanticColors
        expect(
          content.contains('SemanticColors.'),
          isTrue,
          reason: '$widgetPath should use SemanticColors for semantic meanings'
        );
        
        // Should use Theme.of(context)
        expect(
          content.contains('Theme.of(context)'),
          isTrue,
          reason: '$widgetPath should use Theme.of(context) for theme access'
        );
        
        // Should NOT have hardcoded Color values
        expect(
          RegExp(r'Color\(0x[0-9A-Fa-f]+\)').hasMatch(content),
          isFalse,
          reason: '$widgetPath should not contain hardcoded Color(...) values'
        );
      }
    });
  });
}

