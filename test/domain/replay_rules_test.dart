import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/domain/replay_rules.dart';

Clip c(int id) => Clip(
  id: id,
  type: ClipType.voice,
  path: '$id.m4a',
  recordedAt: DateTime(2026, 11, id),
  dayNumber: id,
  durationMs: 5000,
  attempt: 1,
);

void main() {
  test('selectReplayClips day1 plus latest 3', () {
    final all = [c(3), c(1), c(6), c(2), c(5), c(4)];
    expect(selectReplayClips(all).map((e) => e.id), [1, 4, 5, 6]);
  });

  test('with 2 clips returns both', () {
    expect(selectReplayClips([c(2), c(1)]).map((e) => e.id), [1, 2]);
  });

  test('empty returns empty', () {
    expect(selectReplayClips([]), isEmpty);
  });
}
