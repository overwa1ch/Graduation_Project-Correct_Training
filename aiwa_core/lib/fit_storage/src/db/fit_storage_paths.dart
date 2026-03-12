import 'dart:io';

import 'package:path/path.dart' as p;

class FitStoragePaths {
  final Directory rootDir;
  final Directory dbDir;
  final File dbFile;
  final Directory mediaDir;
  final Directory mediaObjectsDir;
  final Directory mediaThumbsDir;

  FitStoragePaths._({
    required this.rootDir,
    required this.dbDir,
    required this.dbFile,
    required this.mediaDir,
    required this.mediaObjectsDir,
    required this.mediaThumbsDir,
  });

  factory FitStoragePaths.fromAppDocumentsDir(Directory appDocumentsDir) {
    final root = Directory(p.join(appDocumentsDir.path, 'fit_storage'));
    final dbDir = Directory(p.join(root.path, 'db'));
    final mediaDir = Directory(p.join(root.path, 'media'));
    final objectsDir = Directory(p.join(mediaDir.path, 'objects'));
    final thumbsDir = Directory(p.join(mediaDir.path, 'thumbs'));
    return FitStoragePaths._(
      rootDir: root,
      dbDir: dbDir,
      dbFile: File(p.join(dbDir.path, 'fit.sqlite')),
      mediaDir: mediaDir,
      mediaObjectsDir: objectsDir,
      mediaThumbsDir: thumbsDir,
    );
  }

  Future<void> ensureInitialized() async {
    await dbDir.create(recursive: true);
    await mediaObjectsDir.create(recursive: true);
    await mediaThumbsDir.create(recursive: true);
  }
}
