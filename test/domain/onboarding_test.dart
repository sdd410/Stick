import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/onboarding.dart';

void main() {
  test('templates have unique ids and 6 popular', () {
    final ids = habitTemplates.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(templatesFor(TemplateCategory.popular).map((t) => t.id), [
      'walk',
      'read',
      'workout',
      'meditate',
      'water',
      'write',
    ]);
  });

  test('every category has templates', () {
    for (final c in TemplateCategory.values) {
      expect(templatesFor(c), isNotEmpty, reason: c.name);
    }
  });

  test('a category lists only its own templates, in order', () {
    expect(templatesFor(TemplateCategory.work).map((t) => t.id), [
      'write',
      'study',
      'code',
      'language',
    ]);
  });

  test('wallLine uses the quiz answer', () {
    expect(
      wallLine(QuitDayAnswer.day3),
      'You said day 3 gets you. Stick will be ready.',
    );
    expect(
      wallLine(QuitDayAnswer.weekOrTwo),
      'You said it fades after a week or two. Stick will be ready.',
    );
    const fallback = 'The first days are the hardest. Stick will be ready.';
    expect(wallLine(QuitDayAnswer.notSure), fallback);
    expect(wallLine(null), fallback);
  });

  test('promiseLines builds three lines', () {
    expect(
      promiseLines(
        name: 'Walk',
        tiny: 'Put on your shoes',
        quitDay: QuitDayAnswer.day2,
      ),
      [
        'Walk every day',
        'On bad days, just put on your shoes',
        "Show up on day 2, even if I don't feel like it",
      ],
    );
  });

  test('promiseLines falls back', () {
    final lines = promiseLines(
      name: ' Read ',
      tiny: '  ',
      quitDay: QuitDayAnswer.weekOrTwo,
    );
    expect(lines[0], 'Read every day');
    expect(lines[1], 'On bad days, just show up for 2 minutes');
    expect(lines[2], contains('day 3'));
  });

  test('reasonHint', () {
    expect(
      reasonHint(QuitReason.tired),
      'Too tired? The tiny version is enough today.',
    );
    expect(
      reasonHint(QuitReason.missedOne),
      'Missed one? Nothing resets here.',
    );
    expect(reasonHint(QuitReason.notSure), isNull);
    expect(reasonHint(null), isNull);
  });
}
