import 'day_clock.dart';

/// How one day of the week strip looks. A missed day is [other], the same as
/// a future one: Stick never shows misses.
enum WeekDayState { done, today, todayDone, other }

class WeekDay {
  const WeekDay({required this.day, required this.letter, required this.state});

  final DayKey day;
  final String letter;
  final WeekDayState state;
}

const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The Monday-to-Sunday week that contains [today].
List<WeekDay> weekStrip(DayKey today, Iterable<DayKey> checkInDays) {
  final done = checkInDays.toSet();
  final monday = addDays(today, 1 - DateTime.parse(today).weekday);
  return [
    for (var i = 0; i < 7; i++)
      () {
        final day = addDays(monday, i);
        final isToday = day == today;
        final isDone = done.contains(day);
        return WeekDay(
          day: day,
          letter: _letters[i],
          state: isToday
              ? (isDone ? WeekDayState.todayDone : WeekDayState.today)
              : (isDone ? WeekDayState.done : WeekDayState.other),
        );
      }(),
  ];
}
