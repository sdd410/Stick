import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slides the Home check-in knob all the way (slide mode, the default).
Future<void> slideToCheckIn(WidgetTester t) async {
  await t.drag(find.byKey(const Key('slide-knob')), const Offset(600, 0));
}
