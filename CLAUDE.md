# Stick (App #001)

A small Android app (Flutter) for people who quit new habits by day 3. Read this first in every session that touches this repo.

## Docs in this repo
- `stick-mvp.md`: the spec, with the free core, the Pro list and the decisions.
- `Stick Roadmap to Launch.md`: the roadmap.
- `stick-build-plan.md`: the original 13-task build plan.
- `stick-next-steps.md`: what's left before Play (signing key, device tests, icon, release, Play Console, closed test).
- `TESTING.md`: the device checklist (Android 16 emulator, Android 8 emulator, real phone).
- `docs/superpowers/specs/` and `docs/superpowers/plans/`: design docs and plans for each change after the MVP.

## Status (22 Nov 2026)
- The MVP is built and merged to `main` (PR #1).
- Design decisions are settled (see "Decisions" in `stick-mvp.md`):
  - the quit day is learned from the first miss;
  - voice or video clips with story-style replay;
  - fresh start;
  - a free Progress screen;
  - two home styles, "Big number" and "Road", switchable in Settings;
  - a share card after the test.
- Open branches (not pushed):
  - `feat/habit-name-progress`: the habit name on Home and a clearer Progress screen.
  - `feat/voice-record-ui`: live voice bars and a smaller stop square.
- Known open issue: inexact reminders can arrive hours late, because Android allows a delay of up to 75% of the lead time. A fix that books each reminder with a fixed window has been proposed and not decided.

## Stack and commands
- Flutter 3.50.1 at `~/development/flutter`, Android SDK at `~/Library/Android/sdk`. compileSdk 37 (needed by the plugins), targetSdk 36, minSdk 24. App ID `com.th3on3guy.stick`.
- Packages:
  - `drift` (SQLite);
  - `flutter_local_notifications` with `timezone`;
  - `camera` and `record` for clips;
  - `video_player`;
  - `permission_handler`;
  - `device_info_plus`.
- Run on a device or emulator: `~/development/flutter/bin/flutter run`.
- Tests: `flutter test`.
- Checks: `flutter analyze --no-fatal-infos` and `dart format lib test`.
- After changing a drift table: `dart run build_runner build --delete-conflicting-outputs`. Commit the generated code and dump the schema to `drift_schemas/`.
- PR checks (`.github/workflows/pr-checks.yml`, on PRs into `main`) fail if:
  - a key file is committed (`key.properties`, `*.jks`, `*.keystore`, `local.properties`);
  - formatting is off, or the generated code is stale;
  - analyze reports warnings, or tests fail;
  - the release APK has a forbidden permission (`INTERNET`, exact alarms, storage, media).
- Release signing reads `android/key.properties`. Never commit it or any keystore.

## Code layout
- `lib/domain`: pure rules.
  - `day_clock`: days start at 3 am.
  - `habit_engine`: Day N = check-ins + 1, pause after a gap of 2 or more days, learned quit day, rescue.
  - `reminder_planner`: plans 28 days of reminders.
  - `replay_rules`, `progress`, `battery_tip`.
- `lib/data`: the drift database and `StickRepository` (with a `Snapshot`).
- `lib/controller`: `StickController`. Every operation goes through one queue.
- `lib/services`: notifications, clip recorder, clip files, device info.
- `lib/ui`: setup, home, record, replay, progress, celebration, settings.

## Free vs Pro
- Everything built so far is free core. **No Pro feature exists yet, and nothing is locked.**
- Pro list (from `stick-mvp.md`), none built yet:
  - more than one habit;
  - history calendar;
  - themes;
  - custom reminder text;
  - goal-hopping lock;
  - home screen widget;
  - "I can't today" button;
  - the one-time Pro purchase itself (after the closed test).
- **How features get switched:**
  - The app has no INTERNET permission. That's the privacy promise, and the PR checks enforce it, so there's no remote config.
  - Plan: one `tiers` map (`Feature` → free/pro) in a single file, and every screen asks `canUse(Feature.x)`.
  - Test builds use `--dart-define=ALL_PRO=true`, so closed testers get everything.
  - Production unlocks through a Google Play Billing one-time purchase.
  - Moving a feature between tiers means a one-line change and a Play release.
  - Add this gating together with the first Pro feature (likely the widget).

## Rules
- Follow the series-wide "App development" rules in `../../CLAUDE.md`: Android compatibility, the process, and testing on two emulators and a real phone.
- Ask the user before changing a decided feature.
- Commit and push only when the user asks.
