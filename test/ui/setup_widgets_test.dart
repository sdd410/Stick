import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/setup/setup_widgets.dart';

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: stickTheme(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('StepScaffold disables the button without onButton', (t) async {
    await t.pumpWidget(
      _app(
        const StepScaffold(
          title: 'Pick one',
          progress: 0.2,
          body: SizedBox(),
          buttonLabel: 'Continue',
          onButton: null,
        ),
      ),
    );
    final b = t.widget<FilledButton>(find.byType(FilledButton));
    expect(b.onPressed, isNull);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('StepScaffold shows Skip and Back only when given', (t) async {
    var back = 0, skip = 0;
    await t.pumpWidget(
      _app(
        StepScaffold(
          title: 'Pick one',
          progress: 0.2,
          body: const SizedBox(),
          buttonLabel: 'Continue',
          onButton: () {},
          onBack: () => back++,
          onSkip: () => skip++,
        ),
      ),
    );
    await t.tap(find.byTooltip('Back'));
    await t.tap(find.text('Skip'));
    expect((back, skip), (1, 1));

    await t.pumpWidget(
      _app(
        StepScaffold(
          title: 'Pick one',
          progress: 0.2,
          body: const SizedBox(),
          buttonLabel: 'Continue',
          onButton: () {},
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('StepScaffold can hide its button', (t) async {
    await t.pumpWidget(
      _app(
        const StepScaffold(
          title: 'Pick one',
          progress: 0.2,
          body: SizedBox(),
          buttonLabel: null,
          onButton: null,
        ),
      ),
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ChoiceCard reports taps and shows its selection', (t) async {
    var taps = 0;
    Widget card(bool selected) => _app(
      Scaffold(
        body: ChoiceCard(
          emoji: '🫠',
          label: 'Day 3',
          selected: selected,
          onTap: () => taps++,
        ),
      ),
    );
    await t.pumpWidget(card(false));
    expect(find.byIcon(Icons.check), findsNothing);
    await t.tap(find.text('Day 3'));
    expect(taps, 1);
    await t.pumpWidget(card(true));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('WallChart paints and has a description', (t) async {
    await t.pumpWidget(_app(const Scaffold(body: WallChart())));
    expect(
      find.bySemanticsLabel('Motivation drops until day 3, then gets easier'),
      findsOneWidget,
    );
  });

  testWidgets('StepScaffold scrolls at 2x text on a small phone', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _app(
        StepScaffold(
          title: 'When do you usually quit?',
          highlight: 'quit',
          progress: 0.3,
          body: Column(
            children: [
              for (var i = 0; i < 6; i++)
                ChoiceCard(
                  emoji: '🫠',
                  label: 'Choice number $i',
                  selected: i == 2,
                  onTap: () {},
                ),
            ],
          ),
          buttonLabel: 'Continue',
          onButton: () {},
        ),
        textScale: 2,
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
  });
}
