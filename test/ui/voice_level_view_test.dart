import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/ui/record/voice_level_view.dart';

void main() {
  late StreamController<double> c;
  setUp(() => c = StreamController<double>.broadcast());
  tearDown(() => c.close());

  Future<void> show(WidgetTester t, {bool reduced = false}) async {
    Widget w = Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: VoiceLevelView(level: c.stream)),
    );
    w = MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: w,
    );
    await t.pumpWidget(w);
  }

  double h(WidgetTester t, int i) =>
      t.getSize(find.byKey(Key('voice-bar-$i'))).height;

  testWidgets('starts with 30 flat bars', (t) async {
    await show(t);
    for (var i = 0; i < 30; i++) {
      expect(find.byKey(Key('voice-bar-$i')), findsOneWidget);
      expect(h(t, i), 4);
    }
  });

  testWidgets('newest reading appears on the right', (t) async {
    await show(t);
    c.add(1.0);
    await t.pump();
    await t.pumpAndSettle();
    expect(h(t, 29), 56);
    expect(h(t, 28), 4);
  });

  testWidgets('readings scroll left', (t) async {
    await show(t);
    c.add(1.0);
    await t.pump();
    c.add(0.0);
    await t.pump();
    await t.pumpAndSettle();
    expect(h(t, 28), 56);
    expect(h(t, 29), 4);
  });

  testWidgets('clamps out-of-range levels', (t) async {
    await show(t);
    c.add(2.0);
    await t.pump();
    await t.pumpAndSettle();
    expect(h(t, 29), 56);
    c.add(-1);
    await t.pump();
    await t.pumpAndSettle();
    expect(h(t, 29), 4);
  });

  testWidgets('ring follows the voice level', (t) async {
    await show(t);
    double opacity() => t
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('voice-ring')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    double scale() => t
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.byKey(const Key('voice-ring')),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
    c.add(0.0);
    await t.pumpAndSettle();
    expect(opacity(), closeTo(0.15, 1e-9));
    expect(scale(), closeTo(0.72, 1e-9));
    c.add(1.0);
    await t.pumpAndSettle();
    expect(opacity(), closeTo(0.85, 1e-9));
    expect(scale(), closeTo(1.0, 1e-9));
  });

  testWidgets('ring hidden with reduced motion', (t) async {
    await show(t, reduced: true);
    expect(find.byKey(const Key('voice-ring')), findsNothing);
    await show(t);
    expect(find.byKey(const Key('voice-ring')), findsOneWidget);
  });

  testWidgets('cancels subscription on dispose', (t) async {
    await show(t);
    expect(c.hasListener, isTrue);
    await t.pumpWidget(const SizedBox());
    c.add(0.5);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(c.hasListener, isFalse);
  });
}
