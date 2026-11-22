/// A day in Stick ends at 3 am local time. Keys look like `yyyy-MM-dd`.
typedef DayKey = String;

typedef Clock = DateTime Function();

const _dayStartHour = 3;

/// The day a local moment belongs to (00:00-02:59 count for the day before).
DayKey dayKeyOf(DateTime local) {
  // Work on the wall-clock fields in UTC so DST changes cannot shift the result.
  final wall = DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
  ).subtract(const Duration(hours: _dayStartHour));
  return _format(wall);
}

/// Whole days from [a] to [b] (b - a).
int daysBetween(DayKey a, DayKey b) => _parse(b).difference(_parse(a)).inDays;

DayKey addDays(DayKey d, int n) => _format(_parse(d).add(Duration(days: n)));

DateTime _parse(DayKey d) {
  final p = d.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _format(DateTime utc) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}';
}
