// diagnostics_logger.dart
// Version: v1.0
// Purpose: Append minimal, privacy-safe diagnostics events to <sessionRoot>/diagnostics.log (JSON Lines)

import 'dart:convert';
import 'dart:io';

class DiagnosticsLogger {
  final String sessionRoot;
  final File _logFile;

  DiagnosticsLogger(this.sessionRoot)
      : _logFile = File(_join(sessionRoot, 'diagnostics.log'));

  static String _join(String a, String b) => a.endsWith('/') || a.endsWith('\\') ? '$a$b' : '$a/$b';

  Future<void> _ensureDir() async {
    await _logFile.parent.create(recursive: true);
  }

  Future<void> logStart({required Map<String, dynamic> input, required Map<String, dynamic> params, required String sessionId}) async {
    await _append({
      'event': 'START',
      'sessionId': sessionId,
      'input': _redactInput(input),
      'params': _redactParams(params),
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> logPhase({required String sessionId, required String phase}) async {
    await _append({
      'event': 'PHASE',
      'sessionId': sessionId,
      'phase': phase,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> logProgress({required String sessionId, required String phase, required int processed, required int total, num? p95MsPerFrame, int? etaSec}) async {
    final payload = <String, dynamic>{
      'event': 'PROGRESS',
      'sessionId': sessionId,
      'phase': phase,
      'processed': processed,
      'total': total,
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
    if (p95MsPerFrame != null) payload['p95MsPerFrame'] = p95MsPerFrame;
    if (etaSec != null) payload['etaSec'] = etaSec;
    await _append(payload);
  }

  Future<void> logDone({required String sessionId, required String artifactsRoot, Map<String, dynamic>? extra}) async {
    await _append({
      'event': 'DONE',
      'sessionId': sessionId,
      'artifactsRoot': _redactPath(artifactsRoot),
      if (extra != null) ..._redactGeneric(extra),
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> logError({required String sessionId, required String code, required String message, Map<String, dynamic>? details}) async {
    await _append({
      'event': 'ERROR',
      'sessionId': sessionId,
      'code': code,
      'message': message,
      if (details != null) 'details': _redactGeneric(details),
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> logRetry({required String sessionId, required int retryCount}) async {
    await _append({
      'event': 'RETRY',
      'sessionId': sessionId,
      'retryCount': retryCount,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> logCleanup({required int removedSessions}) async {
    await _append({
      'event': 'CLEANUP',
      'removedSessions': removedSessions,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _append(Map<String, dynamic> obj) async {
    await _ensureDir();
    // Avoid NaN/Infinity
    final normalized = _normalizeNumbers(obj);
    final line = jsonEncode(normalized);
    // Append with newline. Ensure file exists first to avoid race on some platforms
    final sink = _logFile.openWrite(mode: FileMode.append, encoding: utf8);
    sink.writeln(line);
    await sink.flush();
    await sink.close();
  }

  static Map<String, dynamic> _normalizeNumbers(Map<String, dynamic> obj) {
    dynamic fix(dynamic v) {
      if (v is num) {
        if (v.isNaN || v.isInfinite) return 0;
        return v;
      }
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), fix(val)));
      if (v is List) return v.map(fix).toList();
      return v;
    }
    return fix(obj) as Map<String, dynamic>;
  }

  static Map<String, dynamic> _redactInput(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      final key = e.key;
      final val = e.value;
      if (key.toLowerCase().contains('path') || key.toLowerCase().contains('uri')) {
        out[key] = _redactPath(val?.toString() ?? '');
      } else {
        out[key] = val;
      }
    }
    return out;
  }

  static Map<String, dynamic> _redactParams(Map<String, dynamic> params) {
    // Params generally safe, but enforce strings in known path-like keys
    return _redactGeneric(params);
  }

  static Map<String, dynamic> _redactGeneric(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    for (final e in map.entries) {
      final k = e.key;
      final v = e.value;
      if (k.toLowerCase().contains('path') || k.toLowerCase().contains('uri')) {
        out[k] = _redactPath(v?.toString() ?? '');
      } else {
        out[k] = v;
      }
    }
    return out;
  }

  static String _redactPath(String p) {
    if (p.isEmpty) return p;
    var s = p.replaceAll('\\', '/');
    // Remove drive letter (Windows) and leading home segments
    s = s.replaceFirst(RegExp(r'^[A-Za-z]:/'), '/');
    s = s.replaceFirst(RegExp(r'^/Users/[^/]+'), '/Users/_redacted');
    s = s.replaceFirst(RegExp(r'^/home/[^/]+'), '/home/_redacted');
    return s;
  }
}


