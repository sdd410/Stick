import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/setup/habit_picker.dart';

void main() {
  late List<PickedHabit> picked;

  Future<void> pump(WidgetTester t) async {
    picked = [];
    t.view.physicalSize = const Size(400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: HabitPicker(progress: 0.4, onBack: () {}, onPicked: picked.add),
      ),
    );
  }

  FilledButton continueButton(WidgetTester t) =>
      t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));

  testWidgets('Popular shows the six popular habits', (t) async {
    await pump(t);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Tiny: Put on your shoes'), findsOneWidget);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Run'), findsNothing);
  });

  testWidgets('a category chip filters the list', (t) async {
    await pump(t);
    await t.tap(find.text('Mind'));
    await t.pump();
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Walk'), findsNothing);
  });

  testWidgets('a template prefills the sheet and can be edited', (t) async {
    await pump(t);
    await t.tap(find.text('Walk'));
    await t.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);
    final name = find.byKey(const Key('habit-name'));
    final tiny = find.byKey(const Key('habit-tiny'));
    expect(t.widget<TextField>(name).controller!.text, 'Walk');
    expect(t.widget<TextField>(tiny).controller!.text, 'Put on your shoes');

    await t.enterText(name, 'Walk 20 minutes');
    await t.pump();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();

    expect(picked, hasLength(1));
    final p = picked.single;
    expect(p.emoji, '🚶');
    expect(p.name, 'Walk 20 minutes');
    expect(p.tiny, 'Put on your shoes');
    expect(p.templateId, 'walk');
    expect(find.text('Make it yours'), findsNothing);
  });

  testWidgets('an own habit needs a name', (t) async {
    await pump(t);
    await t.tap(find.text('✎ My own habit'));
    await t.pumpAndSettle();
    expect(continueButton(t).onPressed, isNull);

    await t.enterText(find.byKey(const Key('habit-name')), '   ');
    await t.pump();
    expect(continueButton(t).onPressed, isNull);

    await t.enterText(find.byKey(const Key('habit-name')), ' Floss ');
    await t.pump();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();

    final p = picked.single;
    expect(p.emoji, '⭐');
    expect(p.name, 'Floss');
    expect(p.tiny, isNull);
    expect(p.templateId, isNull);
  });

  testWidgets('clearing a template tiny version gives null', (t) async {
    await pump(t);
    await t.tap(find.text('Read'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('habit-tiny')), '  ');
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(picked.single.tiny, isNull);
    expect(picked.single.templateId, 'read');
  });

  testWidgets('coming back offers the earlier pick', (t) async {
    picked = [];
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: HabitPicker(
          progress: 0.4,
          onBack: () {},
          onPicked: picked.add,
          initial: const PickedHabit(
            emoji: '🚶',
            name: 'Walk 20 minutes',
            tiny: 'Put on your shoes',
            templateId: 'walk',
          ),
        ),
      ),
    );
    await t.tap(find.text('Continue with 🚶 Walk 20 minutes'));
    expect(picked.single.name, 'Walk 20 minutes');
    expect(picked.single.templateId, 'walk');
  });

  testWidgets('the sheet button stays above the system navigation bar', (
    t,
  ) async {
    await pump(t);
    t.view.padding = const FakeViewPadding(bottom: 48);
    t.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(t.view.resetPadding);
    addTearDown(t.view.resetViewPadding);
    await t.pump();
    await t.tap(find.text('Read'));
    await t.pumpAndSettle();
    final button = t.getRect(find.widgetWithText(FilledButton, 'Continue'));
    expect(button.bottom, lessThanOrEqualTo(900 - 48));
  });
}
