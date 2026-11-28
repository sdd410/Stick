# Stick

**A habit app for people who quit by day 3.**

Most habit apps are built for perfect streaks. Stick is built for the day you usually give up. It learns when you tend to stop, shrinks the habit to a tiny version on that day, and plays back a message you recorded for yourself when you started.

App #001 of [@th3_on3guy](https://www.instagram.com/th3_on3guy/), a series that turns everyday problems into real apps, built in public. Android first (Flutter), iOS later.

## What it does

- **30-second setup:** name the habit, add a tiny version (optional) and why you're starting, set a reminder time, and optionally record a first voice or video message.
- **One button a day:** "Done today". The home screen shows your day as a big number or as a road (switch in Settings).
- **Learned quit day:** your first miss teaches Stick the day you usually stop. On that day, or the day after a miss, home switches to rescue mode: "Just do this. Get to day 4."
- **Messages to future you:** short voice or video clips (up to 15 s) that replay story-style on hard days and once a week.
- **No guilt:** a missed day pauses the count instead of wiping it, and "Pick it back up" continues where you were. "Fresh start" begins a new attempt and keeps the old ones on record.
- **Progress:** days you showed up, every attempt side by side, and tiny days (they count).
- **Reminders that survive:** daily local reminders that are planned weeks ahead and rescheduled after a reboot. A battery-saver tip appears on Xiaomi, Samsung, Oppo, Vivo and Realme.

## Privacy

Everything stays on the phone. There's no account, no backend, no analytics, and no internet permission at all; the PR checks fail any build that adds one. Microphone and camera are used only to record your own clips.

## Status

- Version 1.1 is in a Google Play closed test.
- Next: Stick Pro (home-screen widget, more than one habit, history calendar) by subscription or one-time purchase, then the public launch. The free core stays free.

## Run it

Requirements:
- Flutter 3.50+ (Dart 3.14);
- Android SDK with platform 36 (compileSdk 37 for the plugins);
- an emulator or a phone with USB debugging.

```bash
flutter pub get
flutter run                 # debug build on the connected device
flutter run --release       # real-world speed
```

On the emulator, turn on the mic in **Extended Controls (⋯) → Microphone → "Virtual microphone uses host audio input"**. To record video with your Mac's camera, set **Front camera → Webcam0** in the device's settings.

## Develop

```bash
flutter test                                   # all tests
flutter analyze --no-fatal-infos               # lints (warnings fail CI)
dart format lib test                           # formatting
dart run build_runner build --delete-conflicting-outputs   # after changing database tables
```

Pull requests into `develop` and `master` run three checks (`.github/workflows/pr-checks.yml`):
- **Sanity:** no keys committed, lockfile respected, formatting, generated code up to date.
- **Code check:** analyze and tests.
- **Build check:** release APK, a forbidden-permission scan, and target/min SDK.

**Release signing** reads `android/key.properties` (git-ignored). Without it, release builds fall back to the debug key, which Play rejects. See `docs/RELEASING.md` for releases and signing. Never commit the key or its passwords.

## Project layout

```
lib/
  domain/       pure rules: 3 am day clock, habit engine, reminder planner,
                replay rules, progress, battery tip
  data/         SQLite (drift) database and repository
  controller/   StickController: app state, every action runs in one queue
  services/     notifications, clip recorder, clip files, device info
  ui/           setup, home, record, replay, progress, celebration, settings
test/           unit, widget and end-to-end tests
drift_schemas/  database schema history for migrations
docs/           releasing guide and Play release notes
```

## Docs

| File | What's in it |
|---|---|
| `TESTING.md` | Device test checklist |
| `docs/RELEASING.md` | Branches, the Release to Play workflow and signing secrets |
| `docs/release-notes/` | What's new text for each Play release |
