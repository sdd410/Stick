import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../domain/day_clock.dart';
import '../domain/habit_engine.dart';
import '../domain/models.dart';

abstract class ReminderSink {
  Future<void> reschedule(Snapshot s, DateTime now);
  Future<bool> requestPermission();
}

/// Stand-in until the real notification sink exists.
class NoopReminderSink implements ReminderSink {
  @override
  Future<void> reschedule(Snapshot s, DateTime now) async {}

  @override
  Future<bool> requestPermission() async => false;
}

class StickController extends ChangeNotifier {
  StickController({
    required StickRepository repo,
    required Clock clock,
    required ReminderSink reminders,
  }) : _repo = repo,
       _clock = clock,
       _reminders = reminders;

  final StickRepository _repo;
  final Clock _clock;
  final ReminderSink _reminders;

  Snapshot? _snapshot;
  HomeState? _home;
  bool _loaded = false;

  Snapshot? get snapshot => _snapshot;
  HomeState? get home => _home;

  /// False until the first load finishes, so the UI never flashes setup.
  bool get loaded => _loaded;
  bool get needsSetup => _loaded && _snapshot == null;

  DayKey get _today => dayKeyOf(_clock());

  Future<Snapshot?> _load() async {
    final s = await _repo.load();
    _snapshot = s;
    _home = s == null ? null : _compute(s);
    return s;
  }

  HomeState _compute(Snapshot s) {
    Attempt? previous;
    for (final a in s.ended) {
      if (a.firstMissDay == null) continue;
      if (previous == null || a.number > previous.number) previous = a;
    }
    return computeHomeState(
      habit: s.habit,
      attempt: s.current,
      previous: previous,
      checkIns: s.currentCheckIns,
      clips: s.clips,
      flags: s.flags,
      today: _today,
    );
  }

  Future<void> _refresh() async {
    final s = await _load();
    _loaded = true;
    if (s != null) await _reminders.reschedule(s, _clock());
    notifyListeners();
  }

  Future<void> open() async {
    var s = await _load();
    final miss = _home?.firstMissToRecord;
    if (s != null && miss != null) {
      await _repo.recordFirstMiss(miss);
      s = await _load();
    }
    _loaded = true;
    if (s != null) await _reminders.reschedule(s, _clock());
    notifyListeners();
  }

  Future<void> createHabit({
    required String name,
    String? tiny,
    required String why,
    required int reminderMinutes,
  }) async {
    final now = _clock();
    final t = tiny?.trim();
    await _repo.createHabit(
      Habit(
        name: name.trim(),
        tiny: (t == null || t.isEmpty) ? null : t,
        why: why.trim(),
        reminderMinutes: reminderMinutes,
        createdAt: now,
      ),
      dayKeyOf(now),
    );
    await _refresh();
  }

  Future<bool> requestNotificationPermission() =>
      _reminders.requestPermission();

  Future<void> checkIn() async {
    final h = _home;
    if (h == null) return;
    await _repo.checkIn(_today, tiny: h.rescue != RescueReason.none);
    await _refresh();
  }

  Future<void> pickBackUp() async {
    await _repo.pickBackUp(_today);
    await _refresh();
  }

  Future<void> resetAttempt() async {
    await _repo.resetAttempt(_today);
    await _refresh();
  }

  Future<void> freshStart({required bool keepClips}) async {
    // Task 8 wires deletion of the returned clip files.
    await _repo.freshStart(keepClips: keepClips);
    await _refresh();
  }

  Future<void> markDay4Seen() =>
      _setFlags((f) => f.copyWith(day4Celebrated: true));

  Future<void> markWeeklyReplaySeen() {
    final day = _home?.dayNumber;
    return _setFlags((f) => f.copyWith(lastWeeklyReplayDayNumber: day));
  }

  Future<void> setHomeStyle(HomeStyle s) =>
      _setFlags((f) => f.copyWith(homeStyle: s));

  Future<void> _setFlags(Flags Function(Flags) change) async {
    final s = _snapshot;
    if (s == null) return;
    await _repo.setFlags(change(s.flags));
    await _refresh();
  }
}
