import 'models.dart';

/// Day 1 clip (earliest) first, then up to [latest] newest others,
/// oldest to newest, without duplicates.
List<Clip> selectReplayClips(List<Clip> all, {int latest = 3}) {
  if (all.isEmpty) return const [];
  final sorted = [...all]
    ..sort((a, b) {
      final byTime = a.recordedAt.compareTo(b.recordedAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  final rest = sorted.skip(1).toList();
  final tail = rest.length > latest ? rest.sublist(rest.length - latest) : rest;
  return [sorted.first, ...tail];
}
