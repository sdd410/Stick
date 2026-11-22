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

  /// What gets stored in the database: relative to [root], so the rows
  /// survive a moved app directory. Paths outside [root] stay as they are.
  String relative(String path) =>
      p.isWithin(root.path, path) ? p.relative(path, from: root.path) : path;

  /// The inverse of [relative]: an absolute path usable for I/O.
  String resolve(String stored) =>
      p.isAbsolute(stored) ? stored : p.join(root.path, stored);

  /// Every file currently in the clips folder (absolute, normalized).
  List<String> listFiles() {
    final dir = Directory(p.join(root.path, 'clips'));
    if (!dir.existsSync()) return const [];
    return [
      for (final e in dir.listSync())
        if (e is File) p.normalize(e.path),
    ];
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
