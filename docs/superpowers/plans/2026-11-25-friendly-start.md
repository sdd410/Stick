# Friendlier Start (update 1.1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 3-step text-field setup with an 8-screen, mostly-tap onboarding (welcome, 2-question quiz, habit templates, why, reminder, "Day 3 is the wall", "I promise" → first message), and use the quiz's reason on the rescue screen.

**Architecture:** Pure copy and template data live in a new domain file. The habit gains 4 stored fields (drift schema 1 → 2 with a real migration, because closed testers may already have v1 data). The setup UI is rewritten as a small state machine over one `SetupDraft`, built from a shared step scaffold; the habit is created only at the last screen.

**Tech Stack:** Flutter 3.50.1, drift (+ drift_dev schema tools), flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-25-friendly-update-design.md` (section "Update 1.1"). Mockups: `docs/superpowers/specs/mockups/friendly-update.png` screens 1–4.

## Global Constraints
- Colours/fonts from `lib/theme.dart` only: bg `#0B0B12`, lime `#C6FF3D`, muted `#6B6B78`; headings `ArchivoBlack`, body `Inter`. Dark UI, like the mockups.
- No new permissions, no new packages, no network. PR checks must stay green (`dart format lib test`, `flutter analyze --no-fatal-infos`, `flutter test`, generated code fresh).
- Android: system back = the on-screen back arrow on every step (predictive back on 16); edge-to-edge safe (`SafeArea`); text must scroll, not overflow, at 2× font scale.
- Onboarding is at most 8 screens. Every screen has one big bottom button (height 56, lime, full width).
- No made-up statistics anywhere in copy.
- Quiz answers never change the rescue/quit-day rules (decision 1 in the spec): wording only.
- Everything is free core; no gating code.
- Work on a new branch `feat/friendly-start` created from `feat/app-icon` (so 1.1 ships with the new icon).

## Review Focus
1. **Leaving setup half-way:** back from any step must keep earlier answers (draft lives in the flow state), and nothing is written to the database until the promise screen. Test: back from "wall" to "why" still shows the typed reason.
2. **Notification permission denied or throwing** at the reminder step must not block setup (existing behaviour). Test: a controller whose `requestNotificationPermission` throws still reaches Home.
3. **Upgrade from 1.0.0 (schema 1)** with an existing habit: app opens, habit intact, `emoji` = `⭐`, quiz fields null, rescue still works. Test: migration v1→v2 test with a v1 row.
4. **Empty / whitespace habit name** on the edit sheet ("My own habit"): Save disabled. Test in Task 4.
5. **Large font / small screen:** the template list and promise lines must scroll, the bottom button stays visible. Test: pump the flow at `textScaler: TextScaler.linear(2)` on a 360×640 surface with no overflow errors (Task 5).

---

### Task 1: Onboarding copy and templates (domain)

**Files:**
- Create: `lib/domain/onboarding.dart`
- Test: `test/domain/onboarding_test.dart`

**Interfaces:**
- Produces:
  - `enum QuitDayAnswer { day1, day2, day3, weekOrTwo, notSure }`
  - `enum QuitReason { tired, busy, bored, missedOne, notSure }`
  - `enum TemplateCategory { popular, body, mind, work }`
  - `class HabitTemplate { final String id, emoji, name, tiny; final TemplateCategory category; final bool popular; }` (const constructor)
  - `const List<HabitTemplate> habitTemplates`
  - `List<HabitTemplate> templatesFor(TemplateCategory c)` — `popular` returns those with `popular == true`, others filter by `category`, list order kept.
  - `String wallLine(QuitDayAnswer? a)`
  - `List<String> promiseLines({required String name, String? tiny, QuitDayAnswer? quitDay})`
  - `String? reasonHint(QuitReason? r)`
  - `const String defaultEmoji = '⭐'`

Exact data (copy as-is):

| id | emoji | name | tiny | category | popular |
|---|---|---|---|---|---|
| walk | 🚶 | Walk | Put on your shoes | body | yes |
| read | 📖 | Read | Read one page | mind | yes |
| workout | 💪 | Workout | Do one push-up | body | yes |
| meditate | 🧘 | Meditate | Take three slow breaths | mind | yes |
| water | 💧 | Drink water | Drink one glass | body | yes |
| write | ✍️ | Write | Write one sentence | work | yes |
| run | 🏃 | Run | Put on your running shoes | body | no |
| stretch | 🤸 | Stretch | Touch your toes once | body | no |
| sleep | 😴 | Sleep on time | Phone on the charger by 10:45 | body | no |
| journal | 📓 | Journal | Write one line about today | mind | no |
| gratitude | 🙏 | Gratitude | Name one good thing | mind | no |
| lessPhone | 📵 | Less phone | Put your phone in another room | mind | no |
| study | 📚 | Study | Open your notes | work | no |
| code | 💻 | Code | Open your editor | work | no |
| language | 🗣️ | Learn a language | Do one lesson | work | no |

Exact copy:
- `wallLine`: day1 → `You said day 1 gets you. Stick will be ready.`; day2 → `You said day 2 gets you. Stick will be ready.`; day3 → `You said day 3 gets you. Stick will be ready.`; weekOrTwo → `You said it fades after a week or two. Stick will be ready.`; notSure / null → `The first days are the hardest. Stick will be ready.`
- `promiseLines` returns 3 lines: `'$name every day'`; `'On bad days, just ${lowerFirst(tiny ?? "Show up for 2 minutes")}'`; `'Show up on day $n, even if I don\'t feel like it'` where n = 1/2/3 for day1/day2/day3, else 3. `lowerFirst` lower-cases only the first character. `name` and `tiny` are trimmed; empty tiny counts as null.
- `reasonHint`: tired → `Too tired? The tiny version is enough today.`; busy → `Too busy? Two minutes still counts.`; bored → `Bored? Do it a little differently today.`; missedOne → `Missed one? Nothing resets here.`; notSure / null → `null`.

- [ ] **Step 1: Write the failing tests** in `test/domain/onboarding_test.dart`:
  - `templates have unique ids and 6 popular` → ids are unique, `templatesFor(TemplateCategory.popular).map((t) => t.id)` equals `['walk','read','workout','meditate','water','write']`.
  - `every category has templates` → `templatesFor(c)` non-empty for each value.
  - `wallLine uses the quiz answer` → `wallLine(QuitDayAnswer.day3) == 'You said day 3 gets you. Stick will be ready.'`, `wallLine(null)` equals the notSure line.
  - `promiseLines builds three lines` → `promiseLines(name: 'Walk', tiny: 'Put on your shoes', quitDay: QuitDayAnswer.day2)` equals `['Walk every day', 'On bad days, just put on your shoes', "Show up on day 2, even if I don't feel like it"]`.
  - `promiseLines falls back` → `promiseLines(name: ' Read ', tiny: '  ', quitDay: QuitDayAnswer.weekOrTwo)[1] == 'On bad days, just show up for 2 minutes'` and `[0] == 'Read every day'` and `[2]` contains `day 3`.
  - `reasonHint` → tired line exact, `reasonHint(QuitReason.notSure)` and `reasonHint(null)` are null.
- [ ] **Step 2: Run** `flutter test test/domain/onboarding_test.dart` → FAIL (file missing).
- [ ] **Step 3: Implement** `lib/domain/onboarding.dart` with the interfaces and data above (pure Dart, no Flutter import).
- [ ] **Step 4: Run** the same test → PASS.
- [ ] **Step 5: Commit** `feat(domain): onboarding templates and copy`.

---

### Task 2: Store emoji, template and quiz answers on the habit (schema 2)

**Files:**
- Modify: `lib/domain/models.dart` (`Habit`)
- Modify: `lib/data/database.dart` (`Habits` table, `schemaVersion`, `migration`)
- Regenerate: `lib/data/database.g.dart`
- Create: `drift_schemas/drift_schema_v2.json`, `test/generated_migrations/` (drift_dev output)
- Modify: `lib/data/repository.dart` (`_habit`, `_habitCompanion`)
- Modify: `lib/controller/stick_controller.dart` (`createHabit`)
- Test: `test/data/repository_test.dart`, `test/data/migration_test.dart` (new), `test/controller/stick_controller_test.dart`

**Interfaces:**
- Consumes: `QuitDayAnswer`, `QuitReason`, `defaultEmoji` (Task 1).
- Produces:
  - `Habit` gains `final String emoji` (default `defaultEmoji` in the constructor), `final String? templateId`, `final QuitDayAnswer? quizQuitDay`, `final QuitReason? quizReason`; included in `copyWith` (nullable ones use the existing `_keep` sentinel pattern), `==` and `hashCode`.
  - `StickController.createHabit({required String name, String? tiny, required String why, required int reminderMinutes, String emoji = defaultEmoji, String? templateId, QuitDayAnswer? quizQuitDay, QuitReason? quizReason})`. Existing callers compile unchanged. `updateHabit` keeps the new fields via `copyWith`.
  - DB columns on `Habits`: `emoji` text, default `'⭐'`; `templateId` text nullable; `quizQuitDay` `textEnum<QuitDayAnswer>()` nullable; `quizReason` `textEnum<QuitReason>()` nullable. `schemaVersion => 2`.

- [ ] **Step 1: Write the failing tests**
  - `repository_test.dart`: `createHabit stores emoji, template and quiz answers` → create `_habit.copyWith(emoji: '🚶', templateId: 'walk', quizQuitDay: QuitDayAnswer.day3, quizReason: QuitReason.tired)`, `load()` returns an equal habit.
  - `repository_test.dart`: change the existing "throws for an unknown upgrade" test from `onUpgrade(…, 1, 2)` to `onUpgrade(…, 2, 3)`.
  - `migration_test.dart` (uses drift's `SchemaVerifier` with `test/generated_migrations/schema.dart`): `v1 to v2 keeps the habit` → start at v1, insert a v1 habit row (name `Walk`, tiny `Shoes on`, why `x`, reminderMinutes 480, createdAt 2026-11-20), migrate to 2 with `verifier.migrateAndValidate(db, 2)`, then `StickRepository(db).load()` gives a habit named `Walk` with `emoji == '⭐'`, `templateId == null`, `quizQuitDay == null`, `quizReason == null`.
  - `stick_controller_test.dart`: `createHabit passes quiz answers through` → after `createHabit(..., emoji: '📖', quizReason: QuitReason.busy)`, `c.snapshot!.habit.emoji == '📖'` and `quizReason == QuitReason.busy`.
- [ ] **Step 2: Run** `flutter test test/data test/controller` → FAIL (compile errors on the new fields).
- [ ] **Step 3: Implement** model fields, table columns, `schemaVersion => 2`, and the upgrade step:
  ```dart
  onUpgrade: (m, from, to) async {
    for (var v = from; v < to; v++) {
      switch (v) {
        case 1:
          await m.addColumn(habits, habits.emoji);
          await m.addColumn(habits, habits.templateId);
          await m.addColumn(habits, habits.quizQuitDay);
          await m.addColumn(habits, habits.quizReason);
        default:
          throw UnsupportedError('No migration from schema version $v to ${v + 1}');
      }
    }
  },
  ```
  Update the comment above it (schema 1 shipped in 1.0.0; one step per version). Map the fields in `_habit` / `_habitCompanion`, pass them through `createHabit`.
- [ ] **Step 4: Regenerate and dump**
  Run: `dart run build_runner build --delete-conflicting-outputs`
  Run: `dart run drift_dev schema dump lib/data/database.dart drift_schemas/`
  Run: `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
  Expected: `drift_schemas/drift_schema_v2.json` exists; `test/generated_migrations/schema.dart`, `schema_v1.dart`, `schema_v2.dart` exist.
- [ ] **Step 5: Run** `flutter test` → all PASS (existing 170+ tests plus new ones).
- [ ] **Step 6: Commit** `feat(data): habit emoji, template and quiz answers (schema 2)` including generated files and both schema dumps.

---

### Task 3: Shared onboarding widgets

**Files:**
- Create: `lib/ui/setup/setup_widgets.dart`
- Test: `test/ui/setup_widgets_test.dart`

**Interfaces:**
- Produces:
  - `StepScaffold({required String title, String? highlight, required double progress, required Widget body, required String buttonLabel, required VoidCallback? onButton, VoidCallback? onBack, VoidCallback? onSkip, Widget? below})` — top row: back arrow (`Icons.arrow_back_ios_new`, tooltip `Back`, hidden when `onBack` is null), lime progress bar (`LinearProgressIndicator`, value `progress`), `Skip` text button when `onSkip` set. Title in ArchivoBlack 27; `highlight` (if set) is a substring of `title` drawn in lime. Body is scrollable; button pinned at the bottom (56 high, full width, disabled style when `onButton` null); `below` sits under the button (used for "Skip recording").
  - `ChoiceCard({required String emoji, required String label, required bool selected, required VoidCallback onTap})` — rounded card (radius 18, fill `#16161F`), lime 2px border + lime check circle when selected; `Semantics(selected: selected, button: true)`.
  - `WallChart()` — `CustomPaint` of the mockup curve (high at day 1, low red dot at "Day 3", lime dot + `Day 4 → easier` after), label `motivation` top-left; fixed aspect 316:250; `Semantics(label: 'Motivation drops until day 3, then gets easier')`.

- [ ] **Step 1: Write the failing widget tests**
  - `StepScaffold disables the button without onButton` → `tester.widget<FilledButton>(find.byType(FilledButton)).onPressed == null`.
  - `StepScaffold shows Skip and Back only when given` → with both callbacks `find.text('Skip')` and `find.byTooltip('Back')` found; without, not found.
  - `ChoiceCard reports selection` → tapping calls `onTap`; `selected: true` shows `Icons.check`.
  - `StepScaffold scrolls at 2x text` → 360×640 surface, `MediaQuery(textScaler: TextScaler.linear(2))`, body = 6 ChoiceCards; `tester.takeException()` is null and the button is still hit-testable (`find.byType(FilledButton).hitTestable()` finds one).
- [ ] **Step 2: Run** `flutter test test/ui/setup_widgets_test.dart` → FAIL.
- [ ] **Step 3: Implement** the three widgets per the interface.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(ui): onboarding step scaffold, choice card, wall chart`.

---

### Task 4: Habit picker (templates + edit sheet)

**Files:**
- Create: `lib/ui/setup/habit_picker.dart`
- Test: `test/ui/habit_picker_test.dart`

**Interfaces:**
- Consumes: `habitTemplates`, `templatesFor`, `TemplateCategory`, `defaultEmoji` (Task 1); `StepScaffold` (Task 3).
- Produces:
  - `class PickedHabit { final String emoji; final String name; final String? tiny; final String? templateId; }`
  - `HabitPicker({required double progress, required VoidCallback onBack, required ValueChanged<PickedHabit> onPicked, PickedHabit? initial})` — a `StepScaffold` titled `Pick your habit` (highlight `habit`), category chips (`Popular`, `Body`, `Mind`, `Work`; Popular selected first), a list row per template (emoji tile, bold name, `Tiny: <tiny>` subtitle, `+` button; whole row tappable), and a floating `✎ My own habit` button. Its bottom button is hidden; picking happens through the sheet.
  - Tapping a row or "My own habit" opens a modal bottom sheet `Make it yours` with two fields: `Habit` (prefilled name; empty for own) and `Tiny version` (prefilled tiny; hint `Just show up for 2 minutes`), and a `Continue` button disabled while the trimmed name is empty. Continue closes the sheet and calls `onPicked` (emoji = template emoji or `defaultEmoji`, templateId = template id or null, empty tiny → null).

- [ ] **Step 1: Write the failing widget tests**
  - `popular shows the six popular habits` → `find.text('Walk')`, `find.text('Tiny: Put on your shoes')` found; `find.text('Run')` not found.
  - `category chip filters` → tap `Mind`; `Journal` found, `Walk` not found.
  - `template prefills the sheet and picks` → tap `Walk`, sheet shows fields with `Walk` and `Put on your shoes`; edit name to `Walk 20 minutes`; tap `Continue`; `onPicked` got `PickedHabit(emoji: '🚶', name: 'Walk 20 minutes', tiny: 'Put on your shoes', templateId: 'walk')`.
  - `own habit needs a name` → tap `✎ My own habit`; `Continue` disabled; enter `   `; still disabled; enter `Floss`; tap Continue; picked emoji `⭐`, templateId null, tiny null.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `habit_picker.dart`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(ui): habit templates picker`.

---

### Task 5: New setup flow

**Files:**
- Modify (rewrite): `lib/ui/setup/setup_flow.dart`
- Modify: `test/app_smoke_test.dart`, `test/e2e_test.dart` (setup section only)
- Test: `test/ui/setup_flow_test.dart` (new)

**Interfaces:**
- Consumes: everything from Tasks 1–4; `StickController.createHabit` (Task 2), `requestNotificationPermission`.
- Produces: `SetupFlow({Future<void> Function()? onRecordFirstClip, VoidCallback? onFinished})` — **same constructor as today**, so `lib/app.dart` is unchanged.

Screens, in order (progress = index / 7):

| # | Screen | Title (highlight) | Content | Button |
|---|---|---|---|---|
| 0 | welcome | `Built for the day you quit.` (`quit`) | the "S." logo tile (lime rounded square, black `S.` in ArchivoBlack), line `Most habit apps want a perfect streak. Stick plans for the day you want to stop.` | `Start` |
| 1 | quitDay | `When do you usually quit?` (`quit`) | ChoiceCards: 😮‍💨 `Day 1. I barely start`, 😩 `Day 2`, 🫠 `Day 3`, 📅 `After a week or two`, 🤷 `Not sure` | `Continue` (disabled until picked); Skip → next with null |
| 2 | reason | `Why do you usually stop?` (`stop`) | 😴 `Too tired`, ⏰ `Too busy`, 🥱 `Got bored`, 💔 `Missed one day and gave up`, 🤷 `Not sure` | same as 1 |
| 3 | habit | (HabitPicker) | | via sheet |
| 4 | why | `Why are you starting?` (`starting`) | text field hint `Your reason (optional)` + 3 chips that fill it: `Feel healthier`, `Prove I can stick to something`, `Less stress` | `Continue` (always enabled) |
| 5 | reminder | `When should Stick remind you?` (`remind`) | big time display + `CupertinoDatePicker(mode: time, use24hFormat: MediaQuery.alwaysUse24HourFormat)`; chips `Morning` 07:00, `Lunch` 13:00, `Evening` 19:00 (default 19:00) | `Continue` → `requestNotificationPermission()` (errors ignored, as today) then next |
| 6 | wall | `Day 3 is the wall.` (`wall`) | `WallChart`, `wallLine(quitDay)`, line `Stick is built for that dip: on your quit day it shows a rescue screen, a tinier version and your own message.` | `Got it` |
| 7 | promise | `I promise I will` (`I will`) | `promiseLines(...)` as lime-check rows; if `onRecordFirstClip != null`: mic circle + `Say it out loud. Future you will hear it on day 3.` | `I promise. Record it` (or `I promise` when recording is unavailable); `below`: `Skip recording` text button (only when recording is available) |

Behaviour:
- One `SetupDraft` (private class in the file: quitDay, reason, picked, why, minutes) survives back/forward. System back = on-screen back (`PopScope(canPop: step == 0)`); on step 0 back leaves the app as today.
- Nothing is saved before step 7. Both promise buttons call `createHabit(name, tiny, why, reminderMinutes, emoji, templateId, quizQuitDay, quizReason)` once (guard with `_starting` as today), then: `Record it` → `await onRecordFirstClip()` → `onFinished()`; `I promise` / `Skip recording` → `onFinished()`.
- Steps fade/slide with `AnimatedSwitcher` (200 ms).

- [ ] **Step 1: Write the failing tests** in `test/ui/setup_flow_test.dart` (use the in-memory controller pattern from `app_smoke_test.dart`):
  - `full flow creates the habit with quiz answers` → tap `Start`, `Day 3`, `Continue`, `Too tired`, `Continue`, `Walk`, `Continue` (sheet), tap chip `Feel healthier`, `Continue`, chip `Morning`, `Continue`, `Got it`, `I promise` (no recorder) → `c.snapshot!.habit` has name `Walk`, tiny `Put on your shoes`, why `Feel healthier`, reminderMinutes 420, emoji `🚶`, templateId `walk`, quizQuitDay day3, quizReason tired; `onFinished` called once.
  - `nothing is saved before the promise` → go to the wall screen; `c.needsSetup` still true.
  - `back keeps answers` → type `Head clear` on why, Continue, tap Back; field still shows `Head clear`.
  - `skip leaves the quiz answer empty` → tap `Skip` on both quiz screens, finish; `quizQuitDay` and `quizReason` null; wall shows `The first days are the hardest. Stick will be ready.`
  - `permission error does not block` → controller with a reminder sink whose `requestPermission` throws; flow still finishes.
  - `record path` → with `onRecordFirstClip` fake: `Skip recording` visible; tapping `I promise. Record it` calls the fake once, then `onFinished`.
  - `2x text on a small screen` → same as Task 3's overflow check, on the quiz and promise screens.
- [ ] **Step 2: Run** `flutter test test/ui/setup_flow_test.dart` → FAIL.
- [ ] **Step 3: Implement** the rewrite.
- [ ] **Step 4: Update old tests**: `app_smoke_test.dart` expects `find.text('Built for the day you quit.')` instead of `Step 1 of 3` (both tests). `e2e_test.dart` setup block becomes: Start → Skip → Skip → `Walk` → (clear tiny field) → Continue → type `Head clear` → Continue → Continue → Got it → I promise; the rest of the test is unchanged (`Attempt 1 · Day 1`, rescue texts, etc.). Note: clearing the tiny field keeps `Just show up for 2 minutes.` expectations later in the e2e valid; if the test asserts on `tinyLine`, keep it consistent.
- [ ] **Step 5: Run** `flutter test` → all PASS. Run `flutter analyze --no-fatal-infos` → no warnings. Run `dart format lib test`.
- [ ] **Step 6: Commit** `feat(ui): friendlier onboarding flow`.

---

### Task 6: Quiz reason on the rescue screen

**Files:**
- Modify: `lib/ui/home/home_screen.dart` (rescue block, after `tinyLine`)
- Test: `test/ui/home_rescue_hint_test.dart` (new)

**Interfaces:**
- Consumes: `reasonHint` (Task 1), `Habit.quizReason` (Task 2).

- [ ] **Step 1: Write the failing test** `rescue shows the reason hint` → create habit with `quizReason: QuitReason.tired`, move the clock to day 3 (as in `e2e_test.dart`), pump Home: `find.text('Too tired? The tiny version is enough today.')` found. Second test: with `quizReason: null` on day 3, no hint text and existing rescue copy unchanged; on day 2 (no rescue) the hint is not shown.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement**: when `showRescue` and `reasonHint(snap.habit.quizReason)` is non-null, show it under the tiny line (`bodyMedium`, muted, centered, 8 px gap).
- [ ] **Step 4: Run** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(home): rescue hint from the quiz reason`.

---

### Task 7: Version, docs and device check

**Files:**
- Modify: `pubspec.yaml` (`version: 1.1.0+2`)
- Modify: `TESTING.md` (add a "1.1 onboarding" checklist section)
- Modify: `stick-mvp.md` (Decisions: add the 3 decisions confirmed on 25 Nov 2026), `CLAUDE.md` (Status: 1.1 in progress on `feat/friendly-start`)
- Create: `docs/release-notes/1.1.0.txt`

- [ ] **Step 1:** Bump version; add release notes (≤ 500 chars, `<en-US>` block):
  ```
  <en-US>
  A friendlier start.
  • Pick your habit from a list, the tiny version is filled in for you
  • Two quick questions so Stick knows when and why you usually quit
  • "I promise" screen: say it out loud for future you
  • Rescue screen now speaks to your reason for stopping
  Tell me what feels confusing: @th3_on3guy on Instagram.
  </en-US>
  ```
- [ ] **Step 2:** `TESTING.md` checklist: fresh install flow on Android 16 emulator, Android 8 emulator, real phone; upgrade from 1.0.0 (install old AAB build, create habit, install 1.1 over it → habit intact); deny notifications at the reminder step; back gesture on every step (Android 16 predictive back); 2× font in system settings.
- [ ] **Step 3:** Run all PR checks locally: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --release` and confirm no `INTERNET` permission (`aapt2 dump permissions`).
- [ ] **Step 4: Commit** `chore: 1.1.0 version, release notes, test checklist`.
- [ ] **Step 5:** Hand the user the device checklist; build the AAB (`flutter build appbundle --release --dart-define=ALL_PRO=true`) only after they've run it.
