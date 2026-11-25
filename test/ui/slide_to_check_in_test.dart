import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/home/slide_to_check_in.dart';

void main() {
  late List<String> haptics;
  late int done;
  late int longPresses;

  setUp(() {
    haptics = [];
    done = 0;
    longPresses = 0;
  });

  Widget app({bool enabled = true, String label = 'Slide when done'}) =>
      MaterialApp(
        theme: stickTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SlideToCheckIn(
                label: label,
                onDone: enabled ? () => done++ : null,
                onLongPress: () => longPresses++,
              ),
            ),
          ),
        ),
      );

  Future<void> pump(WidgetTester t, {bool enabled = true}) async {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await t.pumpWidget(app(enabled: enabled));
  }

  final knob = find.byKey(const Key('slide-knob'));

  testWidgets('a full slide checks in once with ticks then a firm tap', (
    t,
  ) async {
    await pump(t);
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    expect(done, 1);
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('a short slide springs back with no check-in', (t) async {
    await pump(t);
    final start = t.getTopLeft(knob);
    await t.drag(knob, const Offset(130, 0));
    await t.pumpAndSettle();
    expect(done, 0);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    expect(t.getTopLeft(knob), start);
  });

  testWidgets('a second slide does not check in twice', (t) async {
    await pump(t);
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    await t.drag(knob, const Offset(-330, 0));
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('disabled does nothing and shows its label', (t) async {
    await t.pumpWidget(app(enabled: false, label: 'Done for today ✓'));
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    expect(done, 0);
    expect(find.text('Done for today ✓'), findsOneWidget);
  });

  testWidgets('re-enabled for a new day it works again', (t) async {
    await pump(t);
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    await t.pumpWidget(app(enabled: false, label: 'Done for today ✓'));
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.drag(knob, const Offset(330, 0));
    await t.pumpAndSettle();
    expect(done, 2);
  });

  testWidgets('TalkBack can check in without dragging', (t) async {
    final handle = t.ensureSemantics();
    await pump(t);
    final node = t.getSemantics(find.bySemanticsLabel('Done today'));
    t.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    await t.pumpAndSettle();
    expect(done, 1);
    handle.dispose();
  });

  testWidgets('long press calls onLongPress', (t) async {
    await pump(t);
    await t.longPress(find.byType(SlideToCheckIn));
    expect(longPresses, 1);
    expect(done, 0);
  });
}
