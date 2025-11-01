import 'dart:io';

void main() async {
  final lcovFile = File('coverage/lcov.info');
  
  if (!await lcovFile.exists()) {
    print('❌ coverage/lcov.info not found');
    exit(1);
  }

  final lines = await lcovFile.readAsLines();
  
  final stats = <String, _ModuleStats>{};
  String? currentFile;
  int linesFound = 0;
  int linesHit = 0;
  
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).replaceAll('\\', '/');
      
      // Extract module from path
      String module = 'other';
      if (currentFile.startsWith('lib/ui/')) {
        module = 'ui';
      } else if (currentFile.startsWith('lib/services/')) {
        module = 'services';
      } else if (currentFile.startsWith('lib/theme/')) {
        module = 'theme';
      } else if (currentFile.startsWith('lib/adapters/')) {
        module = 'adapters';
      } else if (currentFile.startsWith('lib/pose/')) {
        module = 'pose';
      }
      
      stats.putIfAbsent(module, () => _ModuleStats());
    } else if (line.startsWith('DA:')) {
      // DA:lineNumber,hitCount
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final hitCount = int.tryParse(parts[1]) ?? 0;
        linesFound++;
        if (hitCount > 0) linesHit++;
        
        if (currentFile != null) {
          String module = 'other';
          if (currentFile.startsWith('lib/ui/')) {
            module = 'ui';
          } else if (currentFile.startsWith('lib/services/')) {
            module = 'services';
          } else if (currentFile.startsWith('lib/theme/')) {
            module = 'theme';
          } else if (currentFile.startsWith('lib/adapters/')) {
            module = 'adapters';
          } else if (currentFile.startsWith('lib/pose/')) {
            module = 'pose';
          }
          
          stats[module]!.linesFound++;
          if (hitCount > 0) stats[module]!.linesHit++;
        }
      }
    }
  }
  
  // Print summary
  print('\n📊 Test Coverage Summary\n');
  print('=' * 60);
  
  final sortedModules = stats.keys.toList()..sort();
  
  for (final module in sortedModules) {
    final stat = stats[module]!;
    final coverage = stat.linesFound > 0 
        ? (stat.linesHit / stat.linesFound * 100).toStringAsFixed(1)
        : '0.0';
    
    print('${module.padRight(15)} ${stat.linesHit.toString().padLeft(5)} / '
          '${stat.linesFound.toString().padLeft(5)} lines  '
          '${coverage.padLeft(6)}%');
  }
  
  print('=' * 60);
  final totalCoverage = linesFound > 0
      ? (linesHit / linesFound * 100).toStringAsFixed(1)
      : '0.0';
  
  print('${'TOTAL'.padRight(15)} ${linesHit.toString().padLeft(5)} / '
        '${linesFound.toString().padLeft(5)} lines  '
        '${totalCoverage.padLeft(6)}%');
  print('=' * 60);
  print('');
}

class _ModuleStats {
  int linesFound = 0;
  int linesHit = 0;
}

