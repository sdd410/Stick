import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Slides the Home check-in knob all the way (slide mode, the default).
/// Scrolls it into view first: on a short screen the rescue card can push
/// the bar below the fold.
Future<void> slideToCheckIn(WidgetTester t) async {
  final knob = find.byKey(const Key('slide-knob'));
  await t.ensureVisible(knob);
  await t.pump();
  await t.drag(knob, const Offset(600, 0));
}
