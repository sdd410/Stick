import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/repository.dart';
import '../domain/day_clock.dart';
import '../domain/habit_engine.dart';
import '../domain/models.dart';
import '../domain/onboarding.dart';
import '../services/clip_files.dart';

abstract class ReminderSink {
  Future<void> reschedule(Snapshot? s, DateTime now);
  Future<bool> requestPermission();
}

/// Stand-in until the real notification sink exists.
class NoopReminderSink implements ReminderSink {
  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async {}

  @override
  Future<bool> requestPermission() async => false;
}

class StickController extends ChangeNotifier {
  StickController({
    required StickRepository repo,
    required Clock clock,
    required ReminderSink reminders,
    ClipFiles? clipFiles,
  }) : _repo = repo,
       _clock = clock,
       _reminders = reminders,
       _clipFiles = clipFiles;

  final StickRepository _repo;
  final Clock _clock;
  final ReminderSink _reminders;
  final ClipFiles? _clipFiles;

  Snapshot? _snapshot;
  HomeState? _home;
  bool _loaded = false;
  Object? _loadError;

  Snapshot? get snapshot => _snapshot;
  HomeState? get home => _home;

  /// False until the first load finishes, so the UI never flashes setup.
  bool get loaded => _loaded;
  bool get needsSetup => _loaded && _snapshot == null;

  /// The error of the last [open] that failed, or null. Cleared by the next
  /// successful [open]. The UI shows a retry screen while not [loaded].
  Object? get loadError => _loadError;

  DayKey get _today => dayKeyOf(_clock());

  Future<Snapshot?> _load() async {
    var s = await _repo.load();
    final files = _clipFiles;
    if (s != null && files != null) {
      // Rows hold paths relative to the clip root; the app works with
      // absolute ones.
      s = s.withClips([
        for (final c in s.clips) c.copyWith(path: files.resolve(c.path)),
      ]);
    }
    _snapshot = s;
    _home = s == null ? null : _compute(s);
    return s;
  }

  HomeState _compute(Snapshot s) {
    return computeHomeState(
      habit: s.habit,
      attempt: s.current,
      previous: previousForQuitDay(s.ended),
      checkIns: s.currentCheckIns,
      clips: s.clips,
      flags: s.flags,
      today: _today,
    );
  }

  Future<void> _queue = Future<void>.value();

  /// Runs [op] after every earlier operation finished, so loads and writes
  /// never interleave. A failed op does not block the ones after it.
  Future<T> _run<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Reminders are best effort: a failing sink must never block the UI.
  Future<void> _reschedule(Snapshot? s) async {
    try {
      await _reminders.reschedule(s, _clock());
    } catch (e, st) {
      debugPrint('Reminder reschedule failed: $e\n$st');
    }
  }

  Future<void> _refresh() async {
    try {
      final s = await _load();
      _loaded = true;
      await _reschedule(s);
    } finally {
      notifyListeners();
    }
  }

  /// Makes rows and files agree: drops rows whose file is gone and, only on
  /// the first open (no recording can be pending then), files with no row.
  Future<void> _sweepClips({required bool orphans}) async {
    final files = _clipFiles;
    if (files == null) return;
    try {
      final kept = <String>{};
      for (final c in await _repo.allClips()) {
        final path = files.resolve(c.path);
        if (await files.exists(path)) {
          kept.add(p.normalize(path));
        } else {
          await _repo.deleteClip(c.id);
        }
      }
      if (orphans) {
        for (final f in files.listFiles()) {
          if (!kept.contains(f)) await files.delete(f);
        }
      }
    } catch (e) {
      debugPrint('Clip sweep failed: $e');
    }
  }

  Future<void> open() => _run(() async {
    try {
      await _sweepClips(orphans: !_loaded);
      var s = await _load();
      final miss = _home?.firstMissToRecord;
      if (s != null && miss != null) {
        await _repo.recordFirstMiss(miss);
        s = await _load();
      }
      _loaded = true;
      _loadError = null;
      await _reschedule(s);
    } catch (e) {
      _loadError = e;
      rethrow;
    } finally {
      notifyListeners();
    }
  });

  Future<void> createHabit({
    required String name,
    String? tiny,
    required String why,
    required int reminderMinutes,
    String emoji = defaultEmoji,
    String? templateId,
    QuitDayAnswer? quizQuitDay,
    QuitReason? quizReason,
  }) => _run(() async {
    final now = _clock();
    final t = tiny?.trim();
    await _repo.createHabit(
      Habit(
        name: name.trim(),
        tiny: (t == null || t.isEmpty) ? null : t,
        why: why.trim(),
        reminderMinutes: reminderMinutes,
        createdAt: now,
        emoji: emoji,
        templateId: templateId,
        quizQuitDay: quizQuitDay,
        quizReason: quizReason,
      ),
      dayKeyOf(now),
    );
    await _refresh();
  });

  /// Edits the habit after setup. Changing the reminder time re-plans the
  /// reminders, because every op ends in [_refresh].
  Future<void> updateHabit({
    required String name,
    String? tiny,
    required String why,
    required int reminderMinutes,
  }) => _run(() async {
    final s = _snapshot;
    if (s == null) return;
    final t = tiny?.trim();
    await _repo.updateHabit(
      s.habit.copyWith(
        name: name.trim(),
        tiny: (t == null || t.isEmpty) ? null : t,
        why: why.trim(),
        reminderMinutes: reminderMinutes,
      ),
    );
    await _refresh();
  });

  Future<bool> requestNotificationPermission() =>
      _reminders.requestPermission();

  Future<void> checkIn() => _run(() async {
    final h = _home;
    if (h == null) return;
    await _repo.checkIn(_today, tiny: h.rescue != RescueReason.none);
    await _refresh();
  });

  Future<void> pickBackUp() => _run(() async {
    await _repo.pickBackUp(_today);
    await _refresh();
  });

  Future<void> resetAttempt() => _run(() async {
    await _repo.resetAttempt(_today);
    await _refresh();
  });

  Future<void> freshStart({required bool keepClips}) => _run(() async {
    final paths = await _repo.freshStart(keepClips: keepClips);
    final files = _clipFiles;
    await _deleteFiles(files == null ? paths : paths.map(files.resolve));
    await _refresh();
  });

  Future<void> _deleteFiles(Iterable<String> paths) async {
    final files = _clipFiles;
    if (files == null) return;
    for (final p in paths) {
      try {
        await files.delete(p);
      } catch (e) {
        debugPrint('Clip file delete failed: $e');
      }
    }
  }

  Future<void> addClip(ClipType type, String path, int durationMs) =>
      _run(() async {
        final h = _home;
        if (h == null) throw StateError('No habit to attach the clip to');
        await _repo.addClip(
          type,
          _clipFiles?.relative(path) ?? path,
          h.dayNumber,
          durationMs,
          _clock(),
          attempt: h.attemptNumber,
        );
        await _refresh();
      });

  Future<void> deleteClip(int id) => _run(() async {
    final clip = _snapshot?.clips.where((c) => c.id == id).firstOrNull;
    await _repo.deleteClip(id);
    if (clip != null) await _deleteFiles([clip.path]);
    await _refresh();
  });

  Future<void> markDay4Seen() =>
      _setFlags((f, _) => f.copyWith(day4Celebrated: true));

  Future<void> markWeeklyReplaySeen() => _setFlags(
    (f, home) => f.copyWith(lastWeeklyReplayDayNumber: home?.dayNumber),
  );

  Future<void> setHomeStyle(HomeStyle s) =>
      _setFlags((f, _) => f.copyWith(homeStyle: s));

  Future<void> _setFlags(Flags Function(Flags, HomeState?) change) =>
      _run(() async {
        final s = _snapshot;
        if (s == null) return;
        await _repo.setFlags(change(s.flags, _home));
        await _refresh();
      });
}
