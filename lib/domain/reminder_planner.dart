import '../data/repository.dart';
import 'day_clock.dart';
import 'habit_engine.dart';
import 'models.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;

  /// Local wall-clock time.
  final DateTime at;
  final String title;
  final String body;
  final String? payload;
}

const _firstId = 100;

/// One reminder per day for the next [days] days, at the habit's reminder time.
///
/// Days after today are planned pessimistically: no further check-ins happen
/// (a check-in happens in the app, which re-plans). The engine decides what
/// each day looks like, so pause and quit-day rules live in one place.
List<PlannedReminder> planReminders(Snapshot s, DateTime now, {int days = 7}) {
  final today = dayKeyOf(now);
  final previous = previousForQuitDay(s.ended);
  final checkIns = s.currentCheckIns;
  final out = <PlannedReminder>[];
  for (var k = 0; k < days; k++) {
    final key = addDays(today, k);
    final at = _fireTime(key, s.habit.reminderMinutes);
    if (k == 0 && (checkIns.any((c) => c.day == key) || !at.isAfter(now))) {
      continue;
    }
    final state = computeHomeState(
      habit: s.habit,
      attempt: s.current,
      previous: previous,
      checkIns: checkIns,
      clips: s.clips,
      flags: s.flags,
      today: key,
    );
    out.add(_reminderFor(_firstId + k, at, s, state));
  }
  return out;
}

/// Reminder times before 3 am belong to the previous day key, so they fire on
/// the next calendar date.
DateTime _fireTime(DayKey key, int minutes) {
  final p = key.split('-').map(int.parse).toList();
  final extra = minutes < 180 ? 1 : 0;
  return DateTime(p[0], p[1], p[2] + extra, minutes ~/ 60, minutes % 60);
}

PlannedReminder _reminderFor(int id, DateTime at, Snapshot s, HomeState h) {
  final tiny = tinyLine(s.habit);
  final n = h.dayNumber;
  if (h.paused) {
    if (s.clips.isNotEmpty) {
      return PlannedReminder(
        id: id,
        at: at,
        title: 'You left yourself a message',
        body: 'Day $n · paused. Tap to hear it.',
        payload: 'replay',
      );
    }
    return PlannedReminder(
      id: id,
      at: at,
      title: 'Day $n · paused',
      body: 'Pick it back up. $tiny',
    );
  }
  if (h.rescue == RescueReason.quitDay) {
    return h.lastQuitDay == null
        ? PlannedReminder(
            id: id,
            at: at,
            title: 'Day 3. This is where most people quit. Not you.',
            body: tiny,
          )
        : PlannedReminder(
            id: id,
            at: at,
            title: 'Day $n. Last time you stopped here.',
            body: 'Not this time. $tiny',
          );
  }
  return PlannedReminder(
    id: id,
    at: at,
    title: 'Day $n of ${s.habit.name}',
    body: 'Show up today. $tiny',
  );
}
