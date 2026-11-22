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
| 20 | Setup: system back on step 2 and 3 goes to the previous step | | | |
| 21 | Progress numbers match what happened | | | |
| 22 | Fresh start, with and without keeping clips | | | |
| 23 | Battery tip shows for the real phone brand (Xiaomi, Samsung, Oppo, Vivo, Realme) | | | |
| 24 | App works in airplane mode | | | |

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
