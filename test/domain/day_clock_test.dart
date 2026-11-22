import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/day_clock.dart';

void main() {
  group('dayKeyOf', () {
    test('00:40 counts for the previous date', () {
      expect(dayKeyOf(DateTime(2026, 11, 22, 0, 40)), '2026-11-21');
    });
    test('02:59 counts for the previous date', () {
      expect(dayKeyOf(DateTime(2026, 11, 22, 2, 59)), '2026-11-21');
    });
    test('03:00 starts the new date', () {
      expect(dayKeyOf(DateTime(2026, 11, 22, 3, 0)), '2026-11-22');
    });
    test('crosses month and year boundaries', () {
      expect(dayKeyOf(DateTime(2027, 1, 1, 1, 0)), '2026-12-31');
    });
  });

  group('dayKeyOf across DST nights', () {
    test('spring forward night 2026-03-29', () {
      expect(dayKeyOf(DateTime(2026, 3, 29, 3, 0)), '2026-03-29');
      expect(dayKeyOf(DateTime(2026, 3, 30, 2, 59)), '2026-03-29');
    });
    test('fall back night 2026-10-25', () {
      expect(dayKeyOf(DateTime(2026, 10, 25, 2, 30)), '2026-10-24');
      expect(dayKeyOf(DateTime(2026, 10, 25, 3, 0)), '2026-10-25');
    });
  });

  group('daysBetween', () {
    test('simple range', () {
      expect(daysBetween('2026-11-21', '2026-11-24'), 3);
    });
    test('across year end', () {
      expect(daysBetween('2026-12-31', '2027-01-01'), 1);
    });
    test('DST week in Europe is not shifted', () {
      expect(daysBetween('2026-03-28', '2026-03-30'), 2);
    });
    test('negative when b is before a', () {
      expect(daysBetween('2026-11-24', '2026-11-21'), -3);
    });
  });

  group('addDays', () {
    test('rolls over month end', () {
      expect(addDays('2026-02-28', 1), '2026-03-01');
    });
    test('negative days', () {
      expect(addDays('2026-03-01', -1), '2026-02-28');
    });
  });
}
