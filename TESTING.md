# Stick device testing

Fill in one cell per device: `pass`, `fail` or a short note. Leave a cell blank
until it was tested. Test on an Android 16 emulator, an Android 8 (API 26)
emulator and a real phone over USB (`flutter run --release -d <id>`).

## Checklist

| # | Check | Android 16 emulator | Android 8 emulator | Real phone |
|---|---|---|---|---|
| 1 | Setup takes under 30 s | | | |
| 2 | Notification permission prompt appears (Android 13+ only) | | | |
| 3 | Check-in updates the screen instantly | | | |
| 4 | Move the device date +2 days: Home turns grey "paused", "Pick it back up" gives the rescue screen | | | |
| 5 | Day 3 rescue ("Day 3. This is where most people quit. Not you.") | | | |
| 6 | Learned quit day shows on attempt 2 | | | |
| 7 | Voice and video record, 15 s cap stops on its own | | | |
| 8 | Deny the microphone/camera permission: record screen explains why and offers "Open settings"; the prompt does not appear twice | | | |
| 9 | Deny, then allow in system settings, come back: recording works | | | |
| 10 | Permission deny flow on Android 13+: deny notifications in setup, setup still finishes and the app works | | | |
| 11 | Replay: tap gate, skip, "See all" | | | |
| 12 | Voice (.m4a) clip replays and plays sound | | | |
| 13 | Video clip records and replays | | | |
| 14 | Camera is released when the app goes to the background while recording (camera indicator off, no crash) | | | |
| 15 | Reminder arrives at the set time | | | |
| 16 | Scheduled reminder survives a reboot (release build) | | | |
| 17 | Tapping a "paused" reminder opens the replay (cold start and app open) | | | |
| 18 | Edge-to-edge: no content hidden under the status or navigation bar | | | |
| 19 | Predictive back gesture on Android 16 | | | |
| 20 | Setup: system back on every step goes to the previous step; on the welcome screen it leaves the app | | | |
| 21 | Progress numbers match what happened | | | |
| 22 | Fresh start, with and without keeping clips | | | |
| 23 | Battery tip shows for the real phone brand (Xiaomi, Samsung, Oppo, Vivo, Realme) | | | |
| 24 | App works in airplane mode | | | |

## 1.1 onboarding

**Uninstall any 1.0 build first.** 1.1 changed the database without an upgrade step, so installing over 1.0 fails to open.

| # | Check | Android 16 emulator | Android 8 emulator | Real phone |
|---|---|---|---|---|
| 25 | Fresh install: welcome → quiz → pick a template → why → reminder → wall → promise, in under 60 s | | | |
| 26 | Quiz Continue stays grey until an answer is picked; Skip works on both questions | | | |
| 27 | Template sheet: name and tiny version prefilled and editable; "My own habit" needs a name | | | |
| 28 | Back arrow and back gesture keep earlier answers (typed reason, picked habit) | | | |
| 29 | Reminder wheel and Morning / Lunch / Evening chips set the time; first reminder arrives at it | | | |
| 30 | Deny notifications at the reminder step: setup still finishes | | | |
| 31 | "I promise. Record it" opens recording, then Home; "Skip recording" goes straight Home | | | |
| 32 | Day 3 rescue shows the quiz hint (e.g. "Too tired? The tiny version is enough today.") | | | |
| 33 | System font at largest size: every onboarding screen scrolls, the big button stays visible | | | |

## 1.1 home, tabs, timer, intro

| # | Check | Android 16 emulator | Android 8 emulator | Real phone |
|---|---|---|---|---|
| 34 | Cold start plays the logo intro (dot drops, STICK slides in, ~0.8 s); a tap skips it; returning to the open app does not replay it | | | |
| 35 | "Remove animations" on (Accessibility): no intro, no sparks, number changes at once | | | |
| 36 | Week strip: today dashed, checked days lime; a missed day looks like a future day | | | |
| 37 | Slide: ticks at ¼ ½ ¾, a firm tap at lock, track fills lime; letting go early springs back with no buzz | | | |
| 38 | Check-in moment: number rolls up (Road style glides), today's circle pops, sparks, light tap | | | |
| 39 | Day 3 → 4: two strong taps, then the Day 4 screen | | | |
| 40 | Settings → Check-in Tap: Home shows the Done today button | | | |
| 41 | TalkBack: the slide is announced as "Done today" and a double-tap checks in | | | |
| 42 | Tabs: Home / Progress / Messages / Settings; back gesture on another tab goes to Home; on Home it leaves | | | |
| 43 | Messages tab: list, "+ Add a message", "▶ Play" | | | |
| 44 | First Home visit: slide tip, then Messages tip; never again after OK | | | |
| 45 | Rescue: "⏱ 2-min timer" and long-press on the slide open the timer; Pause/Resume; reaching 0 or Done checks the day in | | | |
| 46 | Quiz "Day 2" (or "a week or two"): wall screen and promise say day 2 (7), rescue shows that day, Progress says "Get past Day 2 (7)" | | | |
| 47 | Short phone (Android 8 emulator, small screen) in rescue: the slide bar is reachable (scroll if needed) | | | |

## Release bundle permission check

Build `flutter build appbundle --release`, then inspect the AAB (or an APK made
from it):

```
~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest permissions build/app/outputs/bundle/release/app-release.aab
```

| Check | Result |
|---|---|
| No `INTERNET` permission | |
| No `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` | |
| No `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE` | |
| Release is signed with the upload key (not the debug key) | |
