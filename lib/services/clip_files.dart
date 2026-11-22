import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/models.dart';

/// Where clip files live: `<root>/clips/<millis>.m4a|.mp4`.
class ClipFiles {
  ClipFiles(this.root);

  final Directory root;

  String newPath(ClipType t, DateTime at) {
    final dir = Directory(p.join(root.path, 'clips'))
      ..createSync(recursive: true);
    final ext = t == ClipType.voice ? 'm4a' : 'mp4';
    return p.join(dir.path, '${at.millisecondsSinceEpoch}.$ext');
  }

  Future<bool> exists(String path) => File(path).exists();

  /// Deleting a file that is already gone is not an error.
  Future<void> delete(String path) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }
}
