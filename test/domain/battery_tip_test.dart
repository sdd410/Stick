import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/battery_tip.dart';

void main() {
  test('Xiaomi and POCO return tips, Google returns null', () {
    expect(batteryTipFor('Xiaomi'), isNotNull);
    expect(batteryTipFor('POCO'), isNotNull);
    expect(batteryTipFor('Redmi'), isNotNull);
    expect(batteryTipFor('Google'), isNull);
    expect(batteryTipFor(''), isNull);
  });

  test('every listed brand matches, case-insensitive', () {
    for (final b in ['samsung', 'OPPO', 'Vivo', 'realme', 'SAMSUNG']) {
      expect(batteryTipFor(b), isNotNull, reason: b);
    }
  });
}
