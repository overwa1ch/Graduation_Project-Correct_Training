#!/usr/bin/env dart
// generate_perf_report.dart
// Purpose: Extract and format performance metrics from test output
// Usage: dart tool/generate_perf_report.dart <test_output_file> [output_json]

import 'dart:io';
import 'dart:convert';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart generate_perf_report.dart <test_output_file> [output_json]');
    print('');
    print('Extracts performance metrics from test output and generates a JSON report.');
    exit(1);
  }

  final inputFile = File(args[0]);
  final outputFile = args.length > 1 ? File(args[1]) : null;

  if (!inputFile.existsSync()) {
    print('❌ Input file not found: ${inputFile.path}');
    exit(1);
  }

  final metrics = extractMetrics(inputFile);
  
  if (metrics.isEmpty) {
    print('⚠️  No performance metrics found in test output');
    exit(0);
  }

  final report = generateReport(metrics);
  
  if (outputFile != null) {
    outputFile.writeAsStringSync(jsonEncode(report));
    print('✅ Performance report saved to: ${outputFile.path}');
  } else {
    print(jsonEncode(report));
  }
  
  printSummary(metrics);
}

/// Extract performance metrics from test output
Map<String, dynamic> extractMetrics(File inputFile) {
  final metrics = <String, dynamic>{};
  final lines = inputFile.readAsLinesSync();
  
  for (final line in lines) {
    // Look for lines with 📊 emoji (performance markers)
    if (line.contains('📊')) {
      final metricLine = line.substring(line.indexOf('📊') + 1).trim();
      
      // Parse different metric formats
      if (metricLine.contains('Event Parsing:')) {
        metrics['event_parsing_eps'] = _extractNumber(metricLine, 'events/sec');
      } else if (metricLine.contains('Stream Processing:')) {
        metrics['stream_processing_eps'] = _extractNumber(metricLine, 'events/sec');
      } else if (metricLine.contains('Large Payload Parsing:')) {
        // Next line contains throughput
      } else if (metricLine.contains('Throughput:') && metricLine.contains('MB/sec')) {
        metrics['large_payload_mbps'] = _extractNumber(metricLine, 'MB/sec');
      } else if (metricLine.contains('ResultPopup First Render:')) {
        metrics['result_popup_render_ms'] = _extractNumber(metricLine, 'ms');
      } else if (metricLine.contains('CameraPage First Render:')) {
        metrics['camera_page_render_ms'] = _extractNumber(metricLine, 'ms');
      } else if (metricLine.contains('SettingsPage First Render:')) {
        metrics['settings_page_render_ms'] = _extractNumber(metricLine, 'ms');
      } else if (metricLine.contains('ResultPopup Rebuild:')) {
        metrics['result_popup_rebuild_ms'] = _extractNumber(metricLine, 'ms');
      } else if (metricLine.contains('Fixture Replay Throughput:')) {
        // Parse multi-line metric
        for (int i = lines.indexOf(line) + 1; i < lines.length && i < lines.indexOf(line) + 5; i++) {
          final nextLine = lines[i];
          if (nextLine.contains('Rate:')) {
            metrics['fixture_replay_eps'] = _extractNumber(nextLine, 'events/sec');
            break;
          }
        }
      } else if (metricLine.contains('Result Parsing:')) {
        for (int i = lines.indexOf(line) + 1; i < lines.length && i < lines.indexOf(line) + 5; i++) {
          final nextLine = lines[i];
          if (nextLine.contains('Rate:')) {
            metrics['result_parsing_pps'] = _extractNumber(nextLine, 'parses/sec');
            break;
          }
        }
      } else if (metricLine.contains('Rapid Navigation')) {
        for (int i = lines.indexOf(line) + 1; i < lines.length && i < lines.indexOf(line) + 5; i++) {
          final nextLine = lines[i];
          if (nextLine.contains('Average:')) {
            metrics['navigation_avg_ms'] = _extractNumber(nextLine, 'ms');
            break;
          }
        }
      }
    }
  }
  
  return metrics;
}

/// Extract numeric value from metric line
double _extractNumber(String line, String unit) {
  final regex = RegExp(r'(\d+\.?\d*)\s*' + RegExp.escape(unit));
  final match = regex.firstMatch(line);
  
  if (match != null) {
    return double.parse(match.group(1)!);
  }
  
  return 0.0;
}

/// Generate structured report
Map<String, dynamic> generateReport(Map<String, dynamic> metrics) {
  return {
    'timestamp': DateTime.now().toIso8601String(),
    'metrics': metrics,
    'summary': {
      'event_throughput_ok': _meetsThreshold(metrics['event_parsing_eps'], atLeast: 10000),
      'ui_render_ok': _checkRenderThresholds(metrics),
      'overall_health': _calculateOverallHealth(metrics),
    },
  };
}

/// Check if metric meets threshold
/// Check UI render thresholds
bool _checkRenderThresholds(Map<String, dynamic> metrics) {
  final checks = [
    _meetsThreshold(metrics['result_popup_render_ms'], lessThan: 100),
    _meetsThreshold(metrics['camera_page_render_ms'], lessThan: 150),
    _meetsThreshold(metrics['settings_page_render_ms'], lessThan: 150),
  ];
  
  return checks.where((c) => c).length >= 2; // At least 2/3 pass
}

/// Unified threshold checker
bool _meetsThreshold(dynamic value, {double? atLeast, double? lessThan}) {
  if (value == null) return false;
  final v = value as num;
  if (atLeast != null && v < atLeast) return false;
  if (lessThan != null && v >= lessThan) return false;
  return true;
}

/// Calculate overall health score (0-100)
int _calculateOverallHealth(Map<String, dynamic> metrics) {
  int score = 100;
  
  // Deduct points for slow operations
  final eventEps = metrics['event_parsing_eps'];
  if (eventEps is num && eventEps < 10000) {
    score -= 20;
  }
  
  final popupMs = metrics['result_popup_render_ms'];
  if (popupMs is num && popupMs > 100) {
    score -= 15;
  }
  
  final cameraMs = metrics['camera_page_render_ms'];
  if (cameraMs is num && cameraMs > 150) {
    score -= 15;
  }
  
  final navMs = metrics['navigation_avg_ms'];
  if (navMs is num && navMs > 100) {
    score -= 10;
  }
  
  return score.clamp(0, 100);
}

/// Print human-readable summary
void printSummary(Map<String, dynamic> metrics) {
  print('');
  print('Performance Summary');
  print('==================');
  
  if (metrics['event_parsing_eps'] != null) {
    final eps = (metrics['event_parsing_eps'] as num).toStringAsFixed(0);
    final status = (metrics['event_parsing_eps'] as num) >= 10000 ? '✅' : '❌';
    print('Event Parsing:      $eps events/sec $status');
  }
  
  if (metrics['result_popup_render_ms'] != null) {
    final ms = (metrics['result_popup_render_ms'] as num).toStringAsFixed(0);
    final status = (metrics['result_popup_render_ms'] as num) < 100 ? '✅' : '❌';
    print('ResultPopup Render: ${ms}ms $status');
  }
  
  if (metrics['camera_page_render_ms'] != null) {
    final ms = (metrics['camera_page_render_ms'] as num).toStringAsFixed(0);
    final status = (metrics['camera_page_render_ms'] as num) < 150 ? '✅' : '❌';
    print('CameraPage Render:  ${ms}ms $status');
  }
  
  if (metrics['navigation_avg_ms'] != null) {
    final ms = (metrics['navigation_avg_ms'] as num).toStringAsFixed(1);
    final status = (metrics['navigation_avg_ms'] as num) < 100 ? '✅' : '❌';
    print('Navigation Avg:     ${ms}ms $status');
  }
  
  print('');
  print('Health Score: ${_calculateOverallHealth(metrics)}/100');
}

