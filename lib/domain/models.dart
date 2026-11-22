import 'day_clock.dart';

/// Marker so `copyWith` can tell "not passed" from an explicit null.
const Object _keep = Object();

class Habit {
  const Habit({
    required this.name,
    required this.tiny,
    required this.why,
    required this.reminderMinutes,
    required this.createdAt,
  });

  final String name;
  final String? tiny;
  final String why;
  final int reminderMinutes;
  final DateTime createdAt;

  Habit copyWith({
    String? name,
    Object? tiny = _keep,
    String? why,
    int? reminderMinutes,
    DateTime? createdAt,
  }) => Habit(
    name: name ?? this.name,
    tiny: identical(tiny, _keep) ? this.tiny : tiny as String?,
    why: why ?? this.why,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Habit &&
      other.name == name &&
      other.tiny == tiny &&
      other.why == why &&
      other.reminderMinutes == reminderMinutes &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(name, tiny, why, reminderMinutes, createdAt);
}

class Attempt {
  const Attempt({
    required this.number,
    required this.startDay,
    required this.quitTarget,
    this.firstMissDay,
    this.resumedDay,
    this.finalDay,
    this.endedDay,
  });

  final int number;
  final DayKey startDay;
  final int quitTarget;
  final int? firstMissDay;
  final DayKey? resumedDay;
  final int? finalDay;
  final DayKey? endedDay;

  Attempt copyWith({
    int? number,
    DayKey? startDay,
    int? quitTarget,
    Object? firstMissDay = _keep,
    Object? resumedDay = _keep,
    Object? finalDay = _keep,
    Object? endedDay = _keep,
  }) => Attempt(
    number: number ?? this.number,
    startDay: startDay ?? this.startDay,
    quitTarget: quitTarget ?? this.quitTarget,
    firstMissDay: identical(firstMissDay, _keep)
        ? this.firstMissDay
        : firstMissDay as int?,
    resumedDay: identical(resumedDay, _keep)
        ? this.resumedDay
        : resumedDay as DayKey?,
    finalDay: identical(finalDay, _keep) ? this.finalDay : finalDay as int?,
    endedDay: identical(endedDay, _keep) ? this.endedDay : endedDay as DayKey?,
  );

  @override
  bool operator ==(Object other) =>
      other is Attempt &&
      other.number == number &&
      other.startDay == startDay &&
      other.quitTarget == quitTarget &&
      other.firstMissDay == firstMissDay &&
      other.resumedDay == resumedDay &&
      other.finalDay == finalDay &&
      other.endedDay == endedDay;

  @override
  int get hashCode => Object.hash(
    number,
    startDay,
    quitTarget,
    firstMissDay,
    resumedDay,
    finalDay,
    endedDay,
  );
}

class CheckIn {
  const CheckIn({required this.day, required this.attempt, required this.tiny});

  final DayKey day;
  final int attempt;
  final bool tiny;

  CheckIn copyWith({DayKey? day, int? attempt, bool? tiny}) => CheckIn(
    day: day ?? this.day,
    attempt: attempt ?? this.attempt,
    tiny: tiny ?? this.tiny,
  );

  @override
  bool operator ==(Object other) =>
      other is CheckIn &&
      other.day == day &&
      other.attempt == attempt &&
      other.tiny == tiny;

  @override
  int get hashCode => Object.hash(day, attempt, tiny);
}

enum ClipType { voice, video }

class Clip {
  const Clip({
    required this.id,
    required this.type,
    required this.path,
    required this.recordedAt,
    required this.dayNumber,
    required this.durationMs,
    required this.attempt,
  });

  final int id;
  final ClipType type;
  final String path;
  final DateTime recordedAt;
  final int dayNumber;
  final int durationMs;

  /// Attempt number it was recorded in; 0 when kept across a fresh start.
  final int attempt;

  Clip copyWith({
    int? id,
    ClipType? type,
    String? path,
    DateTime? recordedAt,
    int? dayNumber,
    int? durationMs,
    int? attempt,
  }) => Clip(
    id: id ?? this.id,
    type: type ?? this.type,
    path: path ?? this.path,
    recordedAt: recordedAt ?? this.recordedAt,
    dayNumber: dayNumber ?? this.dayNumber,
    durationMs: durationMs ?? this.durationMs,
    attempt: attempt ?? this.attempt,
  );

  @override
  bool operator ==(Object other) =>
      other is Clip &&
      other.id == id &&
      other.type == type &&
      other.path == path &&
      other.recordedAt == recordedAt &&
      other.dayNumber == dayNumber &&
      other.durationMs == durationMs &&
      other.attempt == attempt;

  @override
  int get hashCode =>
      Object.hash(id, type, path, recordedAt, dayNumber, durationMs, attempt);
}

enum HomeStyle { bigNumber, road }

class Flags {
  const Flags({
    required this.day4Celebrated,
    required this.lastWeeklyReplayDayNumber,
    required this.homeStyle,
  });

  final bool day4Celebrated;
  final int? lastWeeklyReplayDayNumber;
  final HomeStyle homeStyle;

  Flags copyWith({
    bool? day4Celebrated,
    Object? lastWeeklyReplayDayNumber = _keep,
    HomeStyle? homeStyle,
  }) => Flags(
    day4Celebrated: day4Celebrated ?? this.day4Celebrated,
    lastWeeklyReplayDayNumber: identical(lastWeeklyReplayDayNumber, _keep)
        ? this.lastWeeklyReplayDayNumber
        : lastWeeklyReplayDayNumber as int?,
    homeStyle: homeStyle ?? this.homeStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is Flags &&
      other.day4Celebrated == day4Celebrated &&
      other.lastWeeklyReplayDayNumber == lastWeeklyReplayDayNumber &&
      other.homeStyle == homeStyle;

  @override
  int get hashCode =>
      Object.hash(day4Celebrated, lastWeeklyReplayDayNumber, homeStyle);
}

enum RescueReason { none, quitDay, paused, afterMiss }

class HomeState {
  const HomeState({
    required this.attemptNumber,
    required this.dayNumber,
    required this.checkedInToday,
    required this.paused,
    required this.rescue,
    required this.quitTarget,
    required this.lastQuitDay,
    required this.showDay4,
    required this.weeklyReplayDue,
    required this.clipPrompt,
    required this.firstMissToRecord,
  });

  final int attemptNumber;
  final int dayNumber;
  final bool checkedInToday;
  final bool paused;
  final RescueReason rescue;
  final int quitTarget;
  final int? lastQuitDay;
  final bool showDay4;
  final bool weeklyReplayDue;
  final bool clipPrompt;
  final int? firstMissToRecord;

  HomeState copyWith({
    int? attemptNumber,
    int? dayNumber,
    bool? checkedInToday,
    bool? paused,
    RescueReason? rescue,
    int? quitTarget,
    Object? lastQuitDay = _keep,
    bool? showDay4,
    bool? weeklyReplayDue,
    bool? clipPrompt,
    Object? firstMissToRecord = _keep,
  }) => HomeState(
    attemptNumber: attemptNumber ?? this.attemptNumber,
    dayNumber: dayNumber ?? this.dayNumber,
    checkedInToday: checkedInToday ?? this.checkedInToday,
    paused: paused ?? this.paused,
    rescue: rescue ?? this.rescue,
    quitTarget: quitTarget ?? this.quitTarget,
    lastQuitDay: identical(lastQuitDay, _keep)
        ? this.lastQuitDay
        : lastQuitDay as int?,
    showDay4: showDay4 ?? this.showDay4,
    weeklyReplayDue: weeklyReplayDue ?? this.weeklyReplayDue,
    clipPrompt: clipPrompt ?? this.clipPrompt,
    firstMissToRecord: identical(firstMissToRecord, _keep)
        ? this.firstMissToRecord
        : firstMissToRecord as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is HomeState &&
      other.attemptNumber == attemptNumber &&
      other.dayNumber == dayNumber &&
      other.checkedInToday == checkedInToday &&
      other.paused == paused &&
      other.rescue == rescue &&
      other.quitTarget == quitTarget &&
      other.lastQuitDay == lastQuitDay &&
      other.showDay4 == showDay4 &&
      other.weeklyReplayDue == weeklyReplayDue &&
      other.clipPrompt == clipPrompt &&
      other.firstMissToRecord == firstMissToRecord;

  @override
  int get hashCode => Object.hash(
    attemptNumber,
    dayNumber,
    checkedInToday,
    paused,
    rescue,
    quitTarget,
    lastQuitDay,
    showDay4,
    weeklyReplayDue,
    clipPrompt,
    firstMissToRecord,
  );
}
