// support_bundle.dart
// Version: v1.1
// Purpose: Create support_bundle.zip with selected diagnostics files under <sessionRoot>

import 'dart:io';
import 'package:archive/archive.dart';

class SupportBundleService {
  /// Export a support bundle at <sessionRoot>/support_bundle.zip
  /// Included files if present:
  /// - result.json
  /// - logs/perf.json
  /// - logs/run.log
  /// - configs_snapshot.json
  /// - diagnostics.log
  static Future<File> export(String sessionRoot) async {
    final output = File(_join(sessionRoot, 'support_bundle.zip'));
    await output.parent.create(recursive: true);

    final archive = Archive();

    void addIfExists(String relativePath) {
      final f = File(_join(sessionRoot, relativePath));
      if (f.existsSync()) {
        final bytes = f.readAsBytesSync();
        final internalPath = relativePath.replaceAll('\\', '/');
        archive.addFile(ArchiveFile(internalPath, bytes.length, bytes));
      }
    }

    addIfExists('result.json');
    addIfExists('logs/perf.json');
    addIfExists('logs/run.log');
    addIfExists('configs_snapshot.json');
    addIfExists('diagnostics.log');

    final encoder = ZipEncoder();
    final zippedBytes = encoder.encode(archive) ?? <int>[];
    await output.writeAsBytes(zippedBytes, flush: true);
    return output;
  }

  static String _join(String a, String b) =>
      a.endsWith('/') || a.endsWith('\\') ? '$a$b' : '$a/$b';
}
