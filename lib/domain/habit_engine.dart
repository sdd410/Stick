import 'day_clock.dart';
import 'models.dart';

/// Computes everything the Home screen needs from stored facts. Pure.
///
/// [previous] is the most recent ENDED attempt that has a non-null
/// `firstMissDay`, the same attempt [quitTargetFor] picks, so `lastQuitDay`
/// always matches the learned rescue day. The caller selects it.
/// [checkIns] are the check-ins of [attempt] only.
HomeState computeHomeState({
  required Habit habit,
  required Attempt attempt,
  required Attempt? previous,
  required List<CheckIn> checkIns,
  required List<Clip> clips,
  required Flags flags,
  required DayKey today,
}) {
  final dayNumber = checkIns.length + 1;
  final checkedInToday = checkIns.any((c) => c.day == today);

  // Latest of start day, last check-in and resume day (keys sort as dates).
  var anchor = attempt.startDay;
  for (final c in checkIns) {
    if (c.day.compareTo(anchor) > 0) anchor = c.day;
  }
  final resumed = attempt.resumedDay;
  if (resumed != null && resumed.compareTo(anchor) > 0) anchor = resumed;

  final paused = !checkedInToday && daysBetween(anchor, today) >= 2;

  final RescueReason rescue;
  if (checkedInToday) {
    rescue = RescueReason.none;
  } else if (paused) {
    rescue = RescueReason.paused;
  } else if (resumed == today) {
    rescue = RescueReason.afterMiss;
  } else if (dayNumber == attempt.quitTarget) {
    rescue = RescueReason.quitDay;
  } else {
    rescue = RescueReason.none;
  }

  return HomeState(
    attemptNumber: attempt.number,
    dayNumber: dayNumber,
    checkedInToday: checkedInToday,
    paused: paused,
    rescue: rescue,
    quitTarget: attempt.quitTarget,
    lastQuitDay: previous?.firstMissDay,
    showDay4: !flags.day4Celebrated && dayNumber >= 4,
    weeklyReplayDue:
        clips.isNotEmpty &&
        dayNumber % 7 == 0 &&
        flags.lastWeeklyReplayDayNumber != dayNumber,
    clipPrompt:
        (dayNumber == 7 || dayNumber == 14 || dayNumber == 21) &&
        !clips.any((c) => c.dayNumber == dayNumber),
    firstMissToRecord: paused && attempt.firstMissDay == null
        ? dayNumber
        : null,
  );
}

/// Quit day learned from the most recent attempt that has a first miss, else 3.
int quitTargetFor(List<Attempt> endedAttempts) {
  Attempt? best;
  for (final a in endedAttempts) {
    if (a.firstMissDay == null) continue;
    if (best == null || a.number > best.number) best = a;
  }
  return best?.firstMissDay ?? 3;
}

/// The day number an attempt stopped on: check-ins + 1.
int finalDayOf(List<CheckIn> attemptCheckIns) => attemptCheckIns.length + 1;

String tinyLine(Habit h) =>
    h.tiny == null ? 'Just show up for 2 minutes.' : 'Just do this: ${h.tiny}.';
