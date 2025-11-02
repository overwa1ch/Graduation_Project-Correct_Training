#!/usr/bin/env dart
// check_coverage.dart
// Purpose: Parse lcov.info and enforce coverage thresholds
// Usage: dart tool/check_coverage.dart [--threshold=85] [coverage/lcov.info]

import 'dart:io';
import 'dart:math';

void main(List<String> args) {
  // Parse command line arguments
  String lcovPath = 'coverage/lcov.info';
  double threshold = 85.0;
  
  for (String arg in args) {
    if (arg.startsWith('--threshold=')) {
      threshold = double.parse(arg.split('=')[1]);
    } else if (!arg.startsWith('--')) {
      lcovPath = arg;
    }
  }

  // Check if lcov file exists
  final lcovFile = File(lcovPath);
  if (!lcovFile.existsSync()) {
    print('❌ Coverage file not found: $lcovPath');
    print('Run: flutter test --coverage');
    exit(1);
  }

  // Parse coverage data
  final coverageData = parseLcovFile(lcovFile);
  
  // Calculate per-directory coverage
  final directoryCoverage = calculateDirectoryCoverage(coverageData);
  
  // Print report
  printCoverageReport(directoryCoverage, threshold);
  
  // Check thresholds
  final failedDirectories = directoryCoverage.entries
      .where((entry) => entry.value.coverage < threshold)
      .map((entry) => entry.key)
      .toList();
  
  if (failedDirectories.isNotEmpty) {
    print('\n❌ Coverage below $threshold% threshold:');
    for (String dir in failedDirectories) {
      final data = directoryCoverage[dir]!;
      print('   $dir: ${data.coverage.toStringAsFixed(1)}% (${data.coveredLines}/${data.totalLines} lines)');
    }
    exit(1);
  } else {
    print('\n✅ All directories meet $threshold% coverage threshold');
    exit(0);
  }
}

class CoverageData {
  final String file;
  final int coveredLines;
  final int totalLines;
  
  CoverageData(this.file, this.coveredLines, this.totalLines);
  
  double get coverage => totalLines > 0 ? (coveredLines / totalLines) * 100 : 0.0;
}

class DirectoryCoverage {
  final int coveredLines;
  final int totalLines;
  
  DirectoryCoverage(this.coveredLines, this.totalLines);
  
  double get coverage => totalLines > 0 ? (coveredLines / totalLines) * 100 : 0.0;
}

Map<String, CoverageData> parseLcovFile(File lcovFile) {
  final coverageData = <String, CoverageData>{};
  final lines = lcovFile.readAsLinesSync();
  
  String? currentFile;
  int coveredLines = 0;
  int totalLines = 0;
  
  for (String line in lines) {
    if (line.startsWith('SF:')) {
      // Save previous file if exists
      if (currentFile != null) {
        coverageData[currentFile] = CoverageData(currentFile, coveredLines, totalLines);
      }
      
      // Start new file
      currentFile = line.substring(3);
      coveredLines = 0;
      totalLines = 0;
    } else if (line.startsWith('DA:')) {
      // DA:line_number,hit_count
      final parts = line.substring(3).split(',');
      if (parts.length == 2) {
        final hitCount = int.tryParse(parts[1]) ?? 0;
        if (hitCount > 0) {
          coveredLines++;
        }
        totalLines++;
      }
    }
  }
  
  // Save last file
  if (currentFile != null) {
    coverageData[currentFile] = CoverageData(currentFile, coveredLines, totalLines);
  }
  
  return coverageData;
}

Map<String, DirectoryCoverage> calculateDirectoryCoverage(Map<String, CoverageData> coverageData) {
  final directoryCoverage = <String, DirectoryCoverage>{};
  
  for (final entry in coverageData.entries) {
    final file = entry.key;
    final data = entry.value;
    
    // Extract directory from file path (handle both / and \ separators)
    String directory;
    final normalizedFile = file.replaceAll('\\', '/');
    if (normalizedFile.contains('lib/adapters/')) {
      directory = 'lib/adapters/';
    } else if (normalizedFile.contains('lib/services/')) {
      directory = 'lib/services/';
    } else if (normalizedFile.contains('lib/ui/')) {
      directory = 'lib/ui/';
    } else if (normalizedFile.contains('lib/theme/')) {
      directory = 'lib/theme/';
    } else if (normalizedFile.contains('lib/pose/')) {
      directory = 'lib/pose/';
    } else {
      continue; // Skip other files
    }
    
    // Accumulate coverage for this directory
    if (directoryCoverage.containsKey(directory)) {
      final existing = directoryCoverage[directory]!;
      directoryCoverage[directory] = DirectoryCoverage(
        existing.coveredLines + data.coveredLines,
        existing.totalLines + data.totalLines,
      );
    } else {
      directoryCoverage[directory] = DirectoryCoverage(
        data.coveredLines,
        data.totalLines,
      );
    }
  }
  
  return directoryCoverage;
}

void printCoverageReport(Map<String, DirectoryCoverage> directoryCoverage, double threshold) {
  print('Coverage Report:');
  print('================');
  
  // Sort directories for consistent output
  final sortedEntries = directoryCoverage.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  
  double totalCovered = 0;
  double totalLines = 0;
  
  for (final entry in sortedEntries) {
    final directory = entry.key;
    final data = entry.value;
    
    totalCovered += data.coveredLines;
    totalLines += data.totalLines;
    
    final status = data.coverage >= threshold ? '✅' : '❌';
    final thresholdText = data.coverage < threshold ? ' - BELOW THRESHOLD' : '';
    
    print('${directory.padRight(20)}: ${data.coverage.toStringAsFixed(1)}% $status (${data.coveredLines}/${data.totalLines} lines)$thresholdText');
  }
  
  print('================');
  final overallCoverage = totalLines > 0 ? (totalCovered / totalLines) * 100 : 0.0;
  final overallStatus = overallCoverage >= threshold ? '✅' : '❌';
  print('Overall: ${overallCoverage.toStringAsFixed(1)}% $overallStatus');
  
  // Print detailed file breakdown for directories below threshold
  print('\nDetailed breakdown for directories below threshold:');
  for (final entry in sortedEntries) {
    if (entry.value.coverage < threshold) {
      print('\n${entry.key} (${entry.value.coverage.toStringAsFixed(1)}%):');
      // This would require re-parsing to show individual files
      // For now, just show the summary
    }
  }
}
