import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/services/clip_files.dart';

void main() {
  late Directory tmp;
  late ClipFiles files;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('clipfiles');
    files = ClipFiles(tmp);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('newPath uses clips folder and extension per type', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000000123);
    final voice = files.newPath(ClipType.voice, at);
    final video = files.newPath(ClipType.video, at);
    expect(voice, '${tmp.path}/clips/1700000000123.m4a');
    expect(video, '${tmp.path}/clips/1700000000123.mp4');
    expect(Directory('${tmp.path}/clips').existsSync(), isTrue);
  });

  test('exists and delete; deleting a missing file is fine', () async {
    final p = files.newPath(ClipType.voice, DateTime.now());
    expect(await files.exists(p), isFalse);
    File(p).writeAsBytesSync([1, 2, 3]);
    expect(await files.exists(p), isTrue);
    await files.delete(p);
    expect(await files.exists(p), isFalse);
    await files.delete(p);
  });
}
