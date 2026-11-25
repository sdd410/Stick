import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/week_strip.dart';

void main() {
  test('Monday-to-Sunday week around a Wednesday', () {
    final w = weekStrip('2026-11-25', [
      '2026-11-23',
      '2026-11-24',
      '2026-11-17',
    ]);
    expect(w.map((d) => d.letter).join(), 'MTWTFSS');
    expect(w.first.day, '2026-11-23');
    expect(w.last.day, '2026-11-29');
    expect(w.map((d) => d.state), [
      WeekDayState.done,
      WeekDayState.done,
      WeekDayState.today,
      WeekDayState.other,
      WeekDayState.other,
      WeekDayState.other,
      WeekDayState.other,
    ]);
  });

  test('today checked in is todayDone', () {
    final w = weekStrip('2026-11-25', ['2026-11-25']);
    expect(w[2].state, WeekDayState.todayDone);
  });

  test('a Sunday still starts the week on Monday', () {
    final w = weekStrip('2026-11-29', const []);
    expect(w.first.day, '2026-11-23');
    expect(w.last.state, WeekDayState.today);
  });

  test('a missed day looks like any other day', () {
    final w = weekStrip('2026-11-26', ['2026-11-23']);
    expect(w[1].state, WeekDayState.other); // Tuesday, missed
  });
}
