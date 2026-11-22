import '../data/repository.dart';
import 'models.dart';

class AttemptBar {
  const AttemptBar({
    required this.number,
    required this.length,
    required this.daysDone,
    required this.beatQuitDay,
    required this.isCurrent,
  });

  final int number;
  final int length;

  /// Check-ins in this attempt (days actually done).
  final int daysDone;
  final bool beatQuitDay;
  final bool isCurrent;
}

/// Numbers for the Progress screen. Every field only grows or stays when a
/// new attempt starts; nothing here counts or lists missed days.
class Progress {
  const Progress({
    required this.daysShowedUp,
    required this.bars,
    required this.tinyDays,
    required this.clipCount,
    required this.nextQuitTarget,
  });

  final int daysShowedUp;
  final List<AttemptBar> bars;
  final int tinyDays;
  final int clipCount;
  final int nextQuitTarget;
}

Progress computeProgress(Snapshot s, HomeState h) {
  final bars = <AttemptBar>[];
  final ended = [...s.ended]..sort((a, b) => a.number.compareTo(b.number));
  for (final a in ended) {
    // Same rule as finalDayOf: the day it stopped on is check-ins + 1.
    final length =
        a.finalDay ??
        s.allCheckIns.where((c) => c.attempt == a.number).length + 1;
    bars.add(
      AttemptBar(
        number: a.number,
        length: length,
        daysDone: s.allCheckIns.where((c) => c.attempt == a.number).length,
        beatQuitDay: length > a.quitTarget,
        isCurrent: false,
      ),
    );
  }
  bars.add(
    AttemptBar(
      number: s.current.number,
      length: h.dayNumber,
      daysDone: s.currentCheckIns.length,
      beatQuitDay: h.dayNumber > s.current.quitTarget,
      isCurrent: true,
    ),
  );
  return Progress(
    daysShowedUp: s.allCheckIns.map((c) => c.day).toSet().length,
    bars: bars,
    tinyDays: s.allCheckIns
        .where((c) => c.tiny)
        .map((c) => c.day)
        .toSet()
        .length,
    clipCount: s.clips.length,
    nextQuitTarget: h.quitTarget,
  );
}
