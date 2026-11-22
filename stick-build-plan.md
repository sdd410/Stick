# Stick MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Stick MVP (features 1–11 of the spec) as an offline Android Flutter app, ready for the 12-tester Google Play closed test.

**Architecture:** All habit rules (day count, 3 am day boundary, pause, learned quit day, rescue, replay triggers, reminder wording) live in pure Dart functions under `lib/domain/` with an injected clock, so they're fully unit-tested. A drift (SQLite) repository stores habit, attempts, check-ins, clips and flags. One `StickController` (ChangeNotifier) joins the two and drives the screens; notifications are re-planned from the domain on every app open and every state change.

**Tech Stack:** Flutter 3.50.1 / Dart 3.14, drift + sqlite3_flutter_libs, flutter_local_notifications + timezone + flutter_timezone, camera, record, video_player, path_provider, permission_handler, device_info_plus. Fonts bundled as assets (no runtime download).

**Spec:** `apps/stick/stick-mvp.md` (features 1–11, Screens, Data, Tech, Decisions). Roadmap: `apps/stick/Stick Roadmap to Launch.md`. Project rules: "App development" in `CLAUDE.md`.

## Global Constraints

- Flutter project lives in `apps/stick/`. Package name `stick`. **Android applicationId `com.th3on3guy.stick`** (permanent on Play once uploaded; confirm before Task 1).
- `targetSdk 36`, `compileSdk 36`, `minSdk 24`.
- No account, no login, no backend, no internet permission, no analytics. Works fully offline.
- Notifications: inexact only (`AndroidScheduleMode.inexactAllowWhileIdle`). Never declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.
- Ask for notification permission (Android 13+) in setup at the reminder step; microphone and camera only when the user first records.
- Edge-to-edge on Android 15+ (content respects system insets); predictive back on Android 16 (`android:enableOnBackInvokedCallback="true"`, `PopScope`, no `WillPopScope`).
- Reminders are rescheduled on every app open and after reboot.
- Battery-saver tip for Xiaomi (incl. Redmi, POCO), Samsung, Oppo, Vivo, Realme.
- Colors: background `#0b0b12`, accent lime `#c6ff3d`. Headings Archivo Black, body Inter.
- A day ends at **3 am** local time. Day N = completed check-ins in this attempt + 1.
- Clips: voice or video, max **15 s**, video at 720p (`ResolutionPreset.high`), stored in app documents dir under `clips/`.
- Fixed copy from the spec, verbatim: "Done today", "Just do this. Get to day 4.", "Day 3 · paused", "Pick it back up", "Just show up for 2 minutes", "Why are you starting?", "Record one for future you.", "▶ You have something to say", "You left yourself a message", "Last time you stopped on Day 5. Today is Day 5." (with real numbers), "Day 3. This is where most people quit. Not you."
- Out of scope (do not build): Pro features, in-app purchase, Day 4 share card, iOS, cloud.

## Review Focus

1. **Coming back after a long gap** (app closed 10 days) → shows paused once, records the first-miss day once (the day number at the miss, not 10), and never pauses twice for the same gap. Test in Task 3 (`long gap records first miss once`).
2. **Check-ins around the 3 am boundary and DST changes** (00:40, 02:59, 03:00; the night clocks change) → 00:40 and 02:59 count for the previous date, 03:00 for the new one; DST night does not create a fake miss. Test in Task 2.
3. **Double tap on "Done today"** or check-in from two quick rebuilds → exactly one check-in per day. Unique constraint + test in Task 4 (`second check-in same day is ignored`).
4. **Permission denied** (notifications, microphone, camera, or "don't ask again") → setup still finishes, the app works, recording explains why and offers "Open settings". Tests in Task 5 and Task 8.
5. **Clip file missing or recording interrupted** (storage cleared, call arrives at 10 s, app backgrounded) → replay skips missing files, an interrupted recording is either saved up to that point or discarded, never a crash or a zero-length clip. Tests in Task 8 and Task 9.

---

## File Structure

```
apps/stick/
  pubspec.yaml
  assets/fonts/ArchivoBlack-Regular.ttf, Inter-Regular.ttf, Inter-SemiBold.ttf
  android/app/build.gradle.kts            sdk levels, applicationId
  android/app/src/main/AndroidManifest.xml permissions, receivers, predictive back
  lib/
    main.dart                    boot: db, timezone, notifications, run app
    app.dart                     MaterialApp, theme, routing by state
    theme.dart                   colors, text styles
    domain/
      day_clock.dart             DayKey, dayKeyOf, daysBetween, addDays
      models.dart                Habit, Attempt, CheckIn, Clip, Flags
      habit_engine.dart          computeHomeState, quitTargetFor, finalDayOf
      replay_rules.dart          selectReplayClips
      reminder_planner.dart      planReminders, reminder copy
      progress.dart              computeProgress
      battery_tip.dart           batteryTipFor
    data/
      database.dart              drift tables + StickDatabase
      repository.dart            StickRepository (all writes/reads)
    controller/
      stick_controller.dart      ChangeNotifier joining engine + repo + services
      stick_scope.dart           InheritedNotifier to reach the controller
    services/
      notification_service.dart  schedule/cancel, permission, tap payload
      clip_recorder.dart         voice (record) + video (camera), 15 s cap
      clip_files.dart            paths, delete, existence check
    ui/
      setup/setup_flow.dart
      home/home_screen.dart, home_big_number.dart, home_road.dart
      replay/replay_screen.dart, clip_list_screen.dart
      record/record_screen.dart
      progress/progress_screen.dart
      celebration/day4_screen.dart
      settings/settings_screen.dart
  test/  (mirrors lib/)
```

---

### Task 1: Project scaffold, theme and Android config

**Files:**
- Create: `apps/stick/` via `flutter create`, `lib/theme.dart`, `lib/app.dart`, `assets/fonts/*`
- Modify: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `lib/main.dart`
- Test: `test/app_smoke_test.dart`

**Interfaces:**
- Produces: `StickColors.bg = Color(0xFF0B0B12)`, `StickColors.lime = Color(0xFFC6FF3D)`, `StickColors.muted = Color(0xFF6B6B78)` (paused grey); `ThemeData stickTheme()`; `class StickApp extends StatelessWidget` (temporary home: `Text('Stick')`).

- [ ] **Step 1:** `cd apps/stick && ~/development/flutter/bin/flutter create --org com.th3on3guy --project-name stick --platforms android app`, then `cd app && git init`.
- [ ] **Step 2:** Add dependencies with `flutter pub add drift sqlite3_flutter_libs path_provider path flutter_local_notifications timezone flutter_timezone camera record video_player permission_handler device_info_plus` and `flutter pub add -d drift_dev build_runner`. Expected: `flutter pub get` exits 0.
- [ ] **Step 3:** Download Archivo Black and Inter (Regular, SemiBold) TTFs from Google Fonts into `assets/fonts/`, declare them in `pubspec.yaml` as families `ArchivoBlack` and `Inter`.
- [ ] **Step 4: Write the failing test** `test/app_smoke_test.dart`: `pumpWidget(const StickApp())`, expect a `Scaffold` whose `backgroundColor` (or theme `scaffoldBackgroundColor`) is `Color(0xFF0B0B12)`, and `find.text('Stick')` findsOneWidget.
- [ ] **Step 5:** Run `flutter test test/app_smoke_test.dart`. Expected: FAIL (StickApp not defined).
- [ ] **Step 6:** Implement `theme.dart` (dark scheme, primary lime, headlines ArchivoBlack, body Inter) and `app.dart`. In `main.dart` call `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` with transparent system bars.
- [ ] **Step 7:** Android config: `build.gradle.kts` → `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24`, `applicationId = "com.th3on3guy.stick"`; core library desugaring on (needed by flutter_local_notifications). Manifest: `android:enableOnBackInvokedCallback="true"` on `<application>`; permissions `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `RECORD_AUDIO`, `CAMERA`; flutter_local_notifications `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` (with `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON` actions). App label "Stick".
- [ ] **Step 8:** Run `flutter test` (PASS) and `flutter build apk --debug` (exit 0).
- [ ] **Step 9: Commit** `git add -A && git commit -m "chore: scaffold Stick app with theme and Android 16 config"`

### Task 2: Day clock

**Files:**
- Create: `lib/domain/day_clock.dart`
- Test: `test/domain/day_clock_test.dart`

**Interfaces:**
- Produces: `typedef DayKey = String;` (format `yyyy-MM-dd`); `DayKey dayKeyOf(DateTime local)`; `int daysBetween(DayKey a, DayKey b)` (b − a, whole days); `DayKey addDays(DayKey d, int n)`; `typedef Clock = DateTime Function();`

- [ ] **Step 1: Write failing tests:**
  - `dayKeyOf(DateTime(2026,11,22,0,40)) == '2026-11-21'`
  - `dayKeyOf(DateTime(2026,11,22,2,59)) == '2026-11-21'`
  - `dayKeyOf(DateTime(2026,11,22,3,0)) == '2026-11-22'`
  - `daysBetween('2026-11-21','2026-11-24') == 3`, `daysBetween('2026-12-31','2027-01-01') == 1`
  - `daysBetween('2026-03-28','2026-03-30') == 2` (DST week in Europe; compute on UTC dates so DST can't shift it)
  - `addDays('2026-02-28', 1) == '2026-03-01'`
- [ ] **Step 2:** `flutter test test/domain/day_clock_test.dart` → FAIL.
- [ ] **Step 3:** Implement: `dayKeyOf` subtracts 3 h from the local wall time, takes y/m/d. `daysBetween`/`addDays` parse to `DateTime.utc(y,m,d)` and use `difference().inDays` / `add(Duration(days:n))`.
- [ ] **Step 4:** Tests PASS.
- [ ] **Step 5: Commit** `feat: add 3 am day clock`

### Task 3: Habit engine (pure rules)

**Files:**
- Create: `lib/domain/models.dart`, `lib/domain/habit_engine.dart`
- Test: `test/domain/habit_engine_test.dart`

**Interfaces:**
- Consumes: `DayKey`, `daysBetween`, `addDays` (Task 2).
- Produces:
  ```dart
  class Habit { String name; String? tiny; String why; int reminderMinutes; DateTime createdAt; }
  class Attempt { int number; DayKey startDay; int quitTarget; int? firstMissDay; DayKey? resumedDay; int? finalDay; DayKey? endedDay; }
  class CheckIn { DayKey day; int attempt; bool tiny; }
  enum ClipType { voice, video }
  class Clip { int id; ClipType type; String path; DateTime recordedAt; int dayNumber; int durationMs; }
  class Flags { bool day4Celebrated; int? lastWeeklyReplayDayNumber; HomeStyle homeStyle; }  // enum HomeStyle { bigNumber, road }
  enum RescueReason { none, quitDay, paused, afterMiss }
  class HomeState { int attemptNumber; int dayNumber; bool checkedInToday; bool paused; RescueReason rescue;
                    int quitTarget; int? lastQuitDay; bool showDay4; bool weeklyReplayDue; bool clipPrompt; int? firstMissToRecord; }
  HomeState computeHomeState({required Habit habit, required Attempt attempt, required Attempt? previous,
      required List<CheckIn> checkIns /* current attempt */, required List<Clip> clips, required Flags flags, required DayKey today});
  int quitTargetFor(List<Attempt> endedAttempts);   // most recent with firstMissDay, else 3
  int finalDayOf(List<CheckIn> attemptCheckIns);     // check-ins + 1
  String tinyLine(Habit h); // h.tiny == null ? 'Just show up for 2 minutes.' : 'Just do this: ${h.tiny}.'
  ```

Rules (decided here; the spec leaves these exact definitions open):
- `dayNumber = checkIns.length + 1`; `checkedInToday` = a check-in with `day == today`.
- **anchor** = latest of `attempt.startDay`, last check-in day, `attempt.resumedDay`. `paused = !checkedInToday && daysBetween(anchor, today) >= 2`. The start day itself never counts as a miss.
- `firstMissToRecord = paused && attempt.firstMissDay == null ? dayNumber : null`.
- `rescue`: if checked in → `none`; else `paused` → `paused`; else `resumedDay == today` → `afterMiss`; else `dayNumber == quitTarget` → `quitDay`; else `none`.
- `lastQuitDay = previous?.firstMissDay` (drives "Last time you stopped on Day N").
- `showDay4 = !flags.day4Celebrated && dayNumber >= 4`.
- `weeklyReplayDue = clips.isNotEmpty && dayNumber % 7 == 0 && flags.lastWeeklyReplayDayNumber != dayNumber`.
- `clipPrompt = dayNumber in {7,14,21} && !clips.any((c) => c.dayNumber == dayNumber)`.

- [ ] **Step 1: Write failing tests** (one `test` each, today fixed):
  - `new attempt is day 1, not paused, no rescue`
  - `setup day without check-in is not a miss` (start yesterday, no check-ins → paused false)
  - `two check-ins makes day 3 and rescue quitDay on attempt 1` (quitTarget 3)
  - `checked in today clears rescue`
  - `missed yesterday pauses and keeps day number` (check-ins on days −3, −2 → dayNumber 3, paused true, rescue paused, firstMissToRecord 3)
  - `long gap records first miss once` (last check-in 10 days ago → firstMissToRecord == dayNumber; with `attempt.firstMissDay = 3` already set → null)
  - `pick it back up today gives afterMiss rescue` (resumedDay today → paused false, rescue afterMiss)
  - `resumed then missed again pauses again without new first miss`
  - `quitTargetFor uses most recent attempt with a miss` (`[a1(firstMiss 3), a2(firstMiss 5)] → 5`; `[a1(5), a2(null)] → 5`; `[] → 3`)
  - `learned quit day triggers rescue` (quitTarget 5, 4 check-ins → rescue quitDay, lastQuitDay from previous)
  - `day 4 celebration once` (dayNumber 4, flag false → true; flag true → false)
  - `weekly replay on day 7 only once and only with clips`
  - `clip prompt on 7 14 21 unless a clip exists for that day`
  - `tinyLine fallback` → `'Just show up for 2 minutes.'`
- [ ] **Step 2:** `flutter test test/domain/habit_engine_test.dart` → FAIL.
- [ ] **Step 3:** Implement models (plain immutable classes with `copyWith`) and the functions per the rules above.
- [ ] **Step 4:** Tests PASS.
- [ ] **Step 5: Commit** `feat: add habit engine (day count, pause, learned quit day, rescue)`

### Task 4: Database and repository

**Files:**
- Create: `lib/data/database.dart`, `lib/data/repository.dart`
- Test: `test/data/repository_test.dart`

**Interfaces:**
- Consumes: models (Task 3), `quitTargetFor`, `finalDayOf`.
- Produces: `class StickDatabase` (drift; tables `Habits` (single row), `Attempts`, `CheckIns` with **unique(day, attempt)**, `Clips`, `Flags` (single row)); `StickDatabase.forTesting(QueryExecutor e)`.
  ```dart
  class StickRepository {
    StickRepository(StickDatabase db);
    Future<Snapshot?> load();  // null when no habit; Snapshot{Habit habit; Attempt current; List<Attempt> ended; List<CheckIn> allCheckIns; List<Clip> clips; Flags flags;}
    Future<void> createHabit(Habit h, DayKey today);              // also attempt 1, quitTarget 3
    Future<void> updateHabit(Habit h);
    Future<bool> checkIn(DayKey today, {required bool tiny});    // false if already checked in
    Future<void> pickBackUp(DayKey today);                       // sets resumedDay
    Future<void> recordFirstMiss(int dayNumber);
    Future<void> resetAttempt(DayKey today);                     // end current (finalDay, endedDay), new attempt with quitTargetFor
    Future<void> freshStart({required bool keepClips});          // wipes habit, attempts, check-ins, flags; clips rows+files unless kept
    Future<Clip> addClip(ClipType t, String path, int dayNumber, int durationMs, DateTime at);
    Future<void> deleteClip(int id);
    Future<void> setFlags(Flags f);
  }
  ```

- [ ] **Step 1: Write failing tests** with `StickDatabase.forTesting(NativeDatabase.memory())`:
  - `load returns null before setup`
  - `createHabit makes attempt 1 with quitTarget 3`
  - `second check-in same day is ignored` (second `checkIn` returns false, one row)
  - `resetAttempt stores finalDay and uses learned quit target` (attempt 1 firstMiss 5 → attempt 2 quitTarget 5; finalDay = check-ins + 1)
  - `freshStart keepClips false clears everything`; `freshStart keepClips true keeps clip rows`
  - `data survives reopening` (file-backed db in a temp dir, close, reopen, load equals)
- [ ] **Step 2:** Run `dart run build_runner build --delete-conflicting-outputs`, then `flutter test test/data/repository_test.dart` → FAIL.
- [ ] **Step 3:** Implement tables and repository. Production DB file `stick.sqlite` in app documents dir. Check-in insert uses `insertOrIgnore`.
- [ ] **Step 4:** Tests PASS.
- [ ] **Step 5: Commit** `feat: add drift storage and repository`

### Task 5: Controller and setup flow

**Files:**
- Create: `lib/controller/stick_controller.dart`, `lib/controller/stick_scope.dart`, `lib/ui/setup/setup_flow.dart`
- Modify: `lib/app.dart`, `lib/main.dart`
- Test: `test/controller/stick_controller_test.dart`, `test/ui/setup_flow_test.dart`

**Interfaces:**
- Consumes: `StickRepository`, `computeHomeState`, `Clock`.
- Produces:
  ```dart
  abstract class ReminderSink { Future<void> reschedule(Snapshot s, DateTime now); Future<bool> requestPermission(); }
  class StickController extends ChangeNotifier {
    StickController({required StickRepository repo, required Clock clock, required ReminderSink reminders});
    Snapshot? get snapshot; HomeState? get home; bool get needsSetup;
    Future<void> open();      // load, persist firstMissToRecord if any, reschedule reminders, notify
    Future<void> createHabit({required String name, String? tiny, required String why, required int reminderMinutes});
    Future<void> checkIn();   // tiny = home.rescue != none
    Future<void> pickBackUp(); Future<void> resetAttempt(); Future<void> freshStart({required bool keepClips});
    Future<void> markDay4Seen(); Future<void> markWeeklyReplaySeen(); Future<void> setHomeStyle(HomeStyle s);
  }
  class StickScope extends InheritedNotifier<StickController> { static StickController of(BuildContext c); }
  ```
  Every mutating method ends with reload → reschedule → `notifyListeners()`. `StickApp` shows `SetupFlow` when `needsSetup`, otherwise `HomeScreen` (placeholder until Task 6).

Setup flow (3 steps, spec feature 1): (1) habit name, (2) tiny version, optional, hint "Just show up for 2 minutes", (3) "Why are you starting?" + reminder time picker (default 19:00, my call) → on "Start" asks notification permission, then offers the optional first clip ("Record a message for future you" / "Skip"). Recording itself arrives in Task 8; until then the button is hidden.

- [ ] **Step 1: Write failing tests:**
  - controller: `open persists first miss` (fake repo state with gap → `recordFirstMiss` called once); `checkIn on rescue day is tiny`; `every change reschedules reminders` (fake `ReminderSink` counts calls).
  - setup widget: `name is required` (Next disabled on empty), `tiny is optional`, `denied notification permission still finishes setup` (fake sink returns false → controller has habit, home shown).
- [ ] **Step 2:** Run tests → FAIL.
- [ ] **Step 3:** Implement. `main.dart`: open DB, build repository, `StickController(clock: DateTime.now, ...)`, `controller.open()`, wrap `StickApp` in `StickScope`. Also call `open()` on `AppLifecycleState.resumed`.
- [ ] **Step 4:** Tests PASS.
- [ ] **Step 5: Commit** `feat: add controller and 3-step setup`

### Task 6: Home screen, style A "big number"

**Files:**
- Create: `lib/ui/home/home_screen.dart`, `lib/ui/home/home_big_number.dart`
- Test: `test/ui/home_screen_test.dart`

**Interfaces:**
- Consumes: `StickController.home`, `checkIn`, `pickBackUp`.
- Produces: `HomeScreen` (picks style from `flags.homeStyle`; owns the shared parts: "Attempt N · Day N" counter (tap → Progress, Task 11), "Add a message" button (→ Task 8), clip-prompt banner, rescue/paused handling); `HomeBigNumber({required HomeState state})` renders only the number area.

Copy:
- Normal: big "Day N", button "Done today". After check-in: "Done for today" (my call) and button disabled.
- Paused: number grey (`StickColors.muted`) "Day N · paused", button "Pick it back up".
- Rescue (quitDay, attempt 1 or no lastQuitDay): "Just do this. Get to day {dayNumber+1}." + `tinyLine`. With `lastQuitDay`: "Last time you stopped on Day {lastQuitDay}. Today is Day {dayNumber}." above. Rescue afterMiss: same tiny layout. If clips exist, rescue shows a "▶ You have something to say" button (→ Task 9); else shows the "why" text.
- Clip prompt banner on 7/14/21: "Record one for future you."

- [ ] **Step 1: Write failing widget tests** (fake controller states): `normal day shows Done today`, `tap Done today calls checkIn once even on double tap` (disable while awaiting), `paused shows grey Day 3 · paused and Pick it back up`, `rescue shows tiny version and Get to day 4`, `learned quit day shows Last time you stopped on Day 5. Today is Day 5.`, `rescue without clips shows why text`, `counter shows Attempt 4 · Day 2`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `feat: add home screen with rescue and pause`

### Task 7: Home style B "road" and style switch

**Files:**
- Create: `lib/ui/home/home_road.dart`
- Modify: `lib/ui/home/home_screen.dart`
- Test: `test/ui/home_road_test.dart`

**Interfaces:**
- Consumes: `HomeState`, `setHomeStyle`.
- Produces: `HomeRoad({required HomeState state})`: a vertical road of day markers from day 1 up to `max(quitTarget + 1, dayNumber + 2)`; past days lime dots, today a large lime marker with the number, the quit-target day marked with a flag and "Day N: last time you stopped" (or "Most people quit here" on attempt 1), day after the quit target labelled "Day {quitTarget+1}". Paused → today's marker grey. (Visual interpretation of "road"; reviewed with the user on device before the Design reel.)

- [ ] **Step 1: Failing tests:** `road shows markers up to quit target plus one`, `quit day flag shows Most people quit here on attempt 1`, `switching style rebuilds home with HomeRoad` (controller `setHomeStyle(HomeStyle.road)`).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `feat: add road home style`

### Task 8: Recording clips (voice or video)

**Files:**
- Create: `lib/services/clip_recorder.dart`, `lib/services/clip_files.dart`, `lib/ui/record/record_screen.dart`
- Modify: `lib/ui/setup/setup_flow.dart` (show optional first clip), `lib/ui/home/home_screen.dart` ("Add a message"), `StickController` (add `addClip`, `deleteClip`)
- Test: `test/services/clip_files_test.dart`, `test/ui/record_screen_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class ClipFiles { ClipFiles(Directory root); String newPath(ClipType t, DateTime at); /* clips/<millis>.m4a | .mp4 */ Future<bool> exists(String p); Future<void> delete(String p); }
  abstract class ClipRecorder { Future<PermissionResult> ensurePermission(ClipType t); Future<void> start(ClipType t, String path); Future<RecordedClip?> stop(); Stream<Duration> get elapsed; }
  // PermissionResult { granted, denied, permanentlyDenied }; RecordedClip { String path; int durationMs; }
  const maxClip = Duration(seconds: 15);
  const minClip = Duration(milliseconds: 800); // shorter → discarded
  ```
  Real implementation: voice via `record` (AAC-LC `.m4a`), video via `camera` front camera `ResolutionPreset.high` (720p) with audio. Auto-stop at 15 s. On `AppLifecycleState.paused`/`inactive` during recording → `stop()` (keeps what was recorded if ≥ `minClip`, else deletes file and returns null).

Record screen: choice "Voice" / "Video" → permission (`permission_handler`, asked only now) → live preview (video) or level meter (voice), big lime record button, 15 s ring countdown, then "Keep" / "Redo". Permanently denied → message "Stick needs the microphone (camera) to record. Nothing leaves your phone." + "Open settings" (`openAppSettings()`).

- [ ] **Step 1: Failing tests:** `newPath uses clips folder and extension per type`; record screen with fake recorder: `denied permission shows Open settings and does not crash`, `auto stops at 15 seconds` (fake elapsed stream emits 15 s → `stop` called), `too short recording is discarded` (stop returns null → no `addClip`), `background during recording keeps partial clip`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Manual check on the real phone: record 1 voice + 1 video, confirm files exist and play in the next task.
- [ ] **Step 6: Commit** `feat: record voice or video clips for future you`

### Task 9: Story-style replay

**Files:**
- Create: `lib/domain/replay_rules.dart`, `lib/ui/replay/replay_screen.dart`, `lib/ui/replay/clip_list_screen.dart`
- Modify: `home_screen.dart` (rescue button + weekly auto-open), `StickController` (`markWeeklyReplaySeen`)
- Test: `test/domain/replay_rules_test.dart`, `test/ui/replay_screen_test.dart`

**Interfaces:**
- Produces: `List<Clip> selectReplayClips(List<Clip> all, {int latest = 3})` → Day 1 clip (earliest `recordedAt`) first, then up to 3 latest others, oldest-to-newest, no duplicates. `ReplayScreen({required List<Clip> clips, String? headline})` route `/replay`; `ClipListScreen` ("See all", with delete).

Behavior: full screen, black, segment progress bars at top; starts on a tap gate "▶ You have something to say" (never auto-plays sound); tap right = next, tap left = previous, end → close. Video via `video_player`; voice also via `video_player` on a lime waveform-style card showing "Day N". Missing file → skipped silently (check `ClipFiles.exists` before building the list). Headline for fresh start: "Day 1 you said this. Still switching?".
Triggers: `home.weeklyReplayDue` → push replay once on open, then `markWeeklyReplaySeen()`; rescue button; notification payload `replay` (Task 10).

- [ ] **Step 1: Failing tests:** `selectReplayClips day1 plus latest 3` (6 clips → [c1,c4,c5,c6]), `with 2 clips returns both`, `empty returns empty`; widget: `does not play before tap`, `missing file is skipped`, `weekly replay opens once on day 7`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `feat: add story-style clip replay`

### Task 10: Reminders

**Files:**
- Create: `lib/domain/reminder_planner.dart`, `lib/services/notification_service.dart`
- Modify: `lib/main.dart` (init timezone, handle launch-from-notification), `StickController` wiring
- Test: `test/domain/reminder_planner_test.dart`

**Interfaces:**
- Consumes: `Snapshot`, `computeHomeState`, `dayKeyOf`, `addDays`, `tinyLine`.
- Produces:
  ```dart
  class PlannedReminder { int id; DateTime at; String title; String body; String? payload; }
  List<PlannedReminder> planReminders(Snapshot s, DateTime now, {int days = 7});
  class NotificationService implements ReminderSink { Future<void> init(void Function(String? payload) onTap); /* reschedule: cancelAll then zonedSchedule each, inexactAllowWhileIdle */ }
  ```

Planning rule: one reminder per day for the next 7 days at `habit.reminderMinutes`, ids `100 + k`. Today's is skipped if already checked in or the time has passed. Future days are planned **pessimistically** (assume no more check-ins; any check-in happens in the app, which re-plans): if checked in today, tomorrow is a normal/quit-day reminder for the current day number and days after are "paused"; if not checked in today, every future day is "paused". The reminder fires at the wall-clock time on the calendar date that belongs to that day key (reminder times before 3 am belong to the previous day key; my call).

Copy (my calls except where marked spec):
- normal: title "Day {n} of {habit}", body "Show up today. {tinyLine}"
- quit day, attempt 1: title **"Day 3. This is where most people quit. Not you."** (spec), body `tinyLine`
- quit day, learned: title "Day {n}. Last time you stopped here.", body "Not this time. {tinyLine}"
- paused with clips: title **"You left yourself a message"** (spec), body "Day {n} · paused. Tap to hear it.", payload `replay`
- paused, no clips: title "Day {n} · paused", body "Pick it back up. {tinyLine}"

- [ ] **Step 1: Failing tests:** `seven reminders when not yet checked in and time ahead`, `skips today after check-in`, `day 3 uses spec wording`, `learned quit day wording`, `future days after no check-in are paused with replay payload when clips exist`, `paused without clips has no payload`, `ids are stable 100 to 106`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement planner and service (`AndroidNotificationDetails` channel `daily`, importance default). `onTap('replay')` and `getNotificationAppLaunchDetails()` route to `/replay`. Permission via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`. **Step 4:** Run → PASS.
- [ ] **Step 5:** Verify no exact alarms: `flutter build apk --debug && ~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest permissions build/app/outputs/flutter-apk/app-debug.apk`. Expected: no line containing `EXACT_ALARM`.
- [ ] **Step 6:** On the emulator: set reminder 2 minutes ahead, background app, notification arrives (inexact: allow a few minutes); reboot emulator (`adb reboot`), confirm the next one is still scheduled (`adb shell dumpsys alarm | grep com.th3on3guy.stick`).
- [ ] **Step 7: Commit** `feat: add daily reminders with day-3 and missed-day wording`

### Task 11: Progress screen

**Files:**
- Create: `lib/domain/progress.dart`, `lib/ui/progress/progress_screen.dart`
- Test: `test/domain/progress_test.dart`, `test/ui/progress_screen_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class AttemptBar { int number; int length; bool beatQuitDay; bool isCurrent; }
  class Progress { int daysShowedUp; List<AttemptBar> bars; int quitDaysBeaten; int tinyDays; int clipCount; int nextQuitTarget; }
  Progress computeProgress(Snapshot s, HomeState h);
  ```
  `daysShowedUp` = all check-ins across attempts. Bar length = `finalDay` (ended) or `dayNumber` (current). `beatQuitDay` = length > that attempt's `quitTarget`. Next step button "Get past Day {quitTarget} this time" → pops to home. Never lists or shows missed days.

- [ ] **Step 1: Failing tests:** `days showed up never drops after reset`, `star when attempt passed its quit target`, `current bar marked now`, `tiny days counted`, widget `next step button label`, `no missed-day text anywhere` (`find.textContaining('miss')` findsNothing).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement; wire counter tap in home. **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `feat: add progress screen`

### Task 12: Day 4 celebration and Settings

**Files:**
- Create: `lib/ui/celebration/day4_screen.dart`, `lib/ui/settings/settings_screen.dart`, `lib/domain/battery_tip.dart`
- Modify: `home_screen.dart` (gear icon, day-4 push after check-in)
- Test: `test/domain/battery_tip_test.dart`, `test/ui/settings_screen_test.dart`, `test/ui/day4_screen_test.dart`

**Interfaces:**
- Produces: `String? batteryTipFor(String manufacturer)` (case-insensitive; `xiaomi|redmi|poco|samsung|oppo|vivo|realme` → tip text; else null). `Day4Screen` (one-time, after the check-in that makes `showDay4` true; "Day 4. You made it past the drop-off." + "Keep going" → `markDay4Seen()`).

Settings items: edit habit (name, tiny, why), reminder time (re-plans), manage clips (→ `ClipListScreen`), home style (Big number / Road), battery tip card when `batteryTipFor(device)` is non-null with "Open settings", **Reset** ("Start a new attempt. Your days stay counted." → confirm → `resetAttempt`), **Fresh start** (plays replay with headline "Day 1 you said this. Still switching?" if clips exist → confirm dialog → "Keep my clips?" (default No) → `freshStart` → setup). All back navigation via `PopScope`.
Battery tip also shown once after setup on those brands.

- [ ] **Step 1: Failing tests:** `batteryTipFor Xiaomi and POCO return tips, Google returns null`, `changing reminder time reschedules`, `reset asks to confirm then increases attempt number`, `fresh start shows replay first when clips exist`, `fresh start default deletes clips`, `day 4 screen shows once`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5: Commit** `feat: add day 4 celebration and settings`

### Task 13: Device testing and closed-test build

**Files:**
- Create: `apps/stick/TESTING.md` (checklist results), `android/key.properties` (not committed; add to `.gitignore`)
- Modify: `android/app/build.gradle.kts` (release signing)

- [ ] **Step 1:** `flutter analyze` → no issues; `flutter test` → all PASS.
- [ ] **Step 2:** Run the checklist on **Android 16 emulator**, **Android 8 (API 26) emulator** and **your real phone over USB** (`flutter run --release -d <id>`), and record pass/fail per device in `TESTING.md`:
  setup < 30 s · notification permission prompt (13+ only) · check-in updates instantly · change emulator date (+2 days) → paused grey, Pick it back up → rescue · day 3 rescue · learned quit day on attempt 2 · voice + video record, 15 s cap, deny then allow permission · replay tap gate, skip, See all · reminder arrives, survives reboot, tap opens replay when paused · edge-to-edge (no content under status/nav bars) · predictive back gesture on 16 · progress numbers match · fresh start with and without keeping clips · battery tip on real phone brand · app works in airplane mode.
- [ ] **Step 3:** Create upload keystore (`keytool -genkey -v -keystore ~/stick-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), wire `key.properties` into release signing. **Back up the keystore and passwords outside the repo.**
- [ ] **Step 4:** `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` exists. Version `1.0.0+1`.
- [ ] **Step 5: Commit** `chore: release signing and device test results`

---

## Timeline mapping (spec "Rough timeline")

| Spec days | Tasks |
|---|---|
| 1–2 | 1, 2, 4 |
| 3–4 | 3, 5, 6 |
| 5–6 | 7, plus reset/fresh start wiring from 12 |
| 7–10 | 8, 9 |
| 11–12 | 10 |
| 13–15 | 11, 12 |
| 16–18 | 13 |
