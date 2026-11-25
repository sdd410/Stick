/// Onboarding data and copy: habit templates, quiz answers and the lines
/// built from them. Pure Dart, so it is tested without Flutter.
library;

/// "When do you usually quit?" Stored by name; wording only, it never
/// changes the rescue or the learned quit day.
enum QuitDayAnswer { day1, day2, day3, weekOrTwo, notSure }

/// "Why do you usually stop?" Used for the rescue-screen hint.
enum QuitReason { tired, busy, bored, missedOne, notSure }

enum TemplateCategory { popular, body, mind, work }

/// Emoji for a habit typed in by hand (and for habits made before 1.1).
const String defaultEmoji = '⭐';

class HabitTemplate {
  const HabitTemplate({
    required this.id,
    required this.emoji,
    required this.name,
    required this.tiny,
    required this.category,
    this.popular = false,
  });

  final String id;
  final String emoji;
  final String name;
  final String tiny;

  /// The template's own category (never [TemplateCategory.popular]).
  final TemplateCategory category;
  final bool popular;
}

const List<HabitTemplate> habitTemplates = [
  HabitTemplate(
    id: 'walk',
    emoji: '🚶',
    name: 'Walk',
    tiny: 'Put on your shoes',
    category: TemplateCategory.body,
    popular: true,
  ),
  HabitTemplate(
    id: 'read',
    emoji: '📖',
    name: 'Read',
    tiny: 'Read one page',
    category: TemplateCategory.mind,
    popular: true,
  ),
  HabitTemplate(
    id: 'workout',
    emoji: '💪',
    name: 'Workout',
    tiny: 'Do one push-up',
    category: TemplateCategory.body,
    popular: true,
  ),
  HabitTemplate(
    id: 'meditate',
    emoji: '🧘',
    name: 'Meditate',
    tiny: 'Take three slow breaths',
    category: TemplateCategory.mind,
    popular: true,
  ),
  HabitTemplate(
    id: 'water',
    emoji: '💧',
    name: 'Drink water',
    tiny: 'Drink one glass',
    category: TemplateCategory.body,
    popular: true,
  ),
  HabitTemplate(
    id: 'write',
    emoji: '✍️',
    name: 'Write',
    tiny: 'Write one sentence',
    category: TemplateCategory.work,
    popular: true,
  ),
  HabitTemplate(
    id: 'run',
    emoji: '🏃',
    name: 'Run',
    tiny: 'Put on your running shoes',
    category: TemplateCategory.body,
  ),
  HabitTemplate(
    id: 'stretch',
    emoji: '🤸',
    name: 'Stretch',
    tiny: 'Touch your toes once',
    category: TemplateCategory.body,
  ),
  HabitTemplate(
    id: 'sleep',
    emoji: '😴',
    name: 'Sleep on time',
    tiny: 'Phone on the charger by 10:45',
    category: TemplateCategory.body,
  ),
  HabitTemplate(
    id: 'journal',
    emoji: '📓',
    name: 'Journal',
    tiny: 'Write one line about today',
    category: TemplateCategory.mind,
  ),
  HabitTemplate(
    id: 'gratitude',
    emoji: '🙏',
    name: 'Gratitude',
    tiny: 'Name one good thing',
    category: TemplateCategory.mind,
  ),
  HabitTemplate(
    id: 'lessPhone',
    emoji: '📵',
    name: 'Less phone',
    tiny: 'Put your phone in another room',
    category: TemplateCategory.mind,
  ),
  HabitTemplate(
    id: 'study',
    emoji: '📚',
    name: 'Study',
    tiny: 'Open your notes',
    category: TemplateCategory.work,
  ),
  HabitTemplate(
    id: 'code',
    emoji: '💻',
    name: 'Code',
    tiny: 'Open your editor',
    category: TemplateCategory.work,
  ),
  HabitTemplate(
    id: 'language',
    emoji: '🗣️',
    name: 'Learn a language',
    tiny: 'Do one lesson',
    category: TemplateCategory.work,
  ),
];

List<HabitTemplate> templatesFor(TemplateCategory c) => [
  for (final t in habitTemplates)
    if (c == TemplateCategory.popular ? t.popular : t.category == c) t,
];

String wallLine(QuitDayAnswer? a) {
  final first = switch (a) {
    QuitDayAnswer.day1 => 'You said day 1 gets you.',
    QuitDayAnswer.day2 => 'You said day 2 gets you.',
    QuitDayAnswer.day3 => 'You said day 3 gets you.',
    QuitDayAnswer.weekOrTwo => 'You said it fades after a week or two.',
    QuitDayAnswer.notSure || null => 'The first days are the hardest.',
  };
  return '$first Stick will be ready.';
}

/// The first attempt's quit day (Progress "Get past Day N" and the rescue
/// day) from "When do you usually quit?". After the first miss the learned
/// day takes over.
int firstQuitTarget(QuitDayAnswer? a) => switch (a) {
  QuitDayAnswer.day1 => 1,
  QuitDayAnswer.day2 => 2,
  QuitDayAnswer.day3 => 3,
  QuitDayAnswer.weekOrTwo => 7,
  QuitDayAnswer.notSure || null => 3,
};

String wallTitle(QuitDayAnswer? a) => 'Day ${firstQuitTarget(a)} is the wall.';

List<String> promiseLines({
  required String name,
  String? tiny,
  QuitDayAnswer? quitDay,
}) {
  final t = tiny?.trim();
  final small = (t == null || t.isEmpty) ? 'Show up for 2 minutes' : t;
  final day = firstQuitTarget(quitDay);
  return [
    '${name.trim()} every day',
    'On bad days, just ${_lowerFirst(small)}',
    "Show up on day $day, even if I don't feel like it",
  ];
}

String? reasonHint(QuitReason? r) => switch (r) {
  QuitReason.tired => 'Too tired? The tiny version is enough today.',
  QuitReason.busy => 'Too busy? Two minutes still counts.',
  QuitReason.bored => 'Bored? Do it a little differently today.',
  QuitReason.missedOne => 'Missed one? Nothing resets here.',
  QuitReason.notSure || null => null,
};

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
