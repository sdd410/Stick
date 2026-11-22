# Stick: Next Steps

Updated 22 Nov 2026. The MVP code is built: features 1–11 from `stick-mvp.md`, 170 tests passing, whole-app review clean.

- Code: the Flutter project sits directly in `apps/stick/` (git repo with remote `origin` = github.com/sdd410/stick, not pushed yet). Work is on branch `mvp`; `main` is an empty starting commit. Merge whenever you're ready (`git checkout main && git merge mvp`).
- Build plan: `apps/stick/stick-build-plan.md` (Tasks 1–12 done, Task 13 is the list below).
- Device checklist: `apps/stick/TESTING.md`.

## 1. Create the upload key (do this first, ~10 min)

Play needs every update signed with the same key. **If you lose it or its passwords, you can't update Stick.**

```bash
keytool -genkey -v -keystore ~/stick-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `apps/stick/android/key.properties` (already git-ignored, never commit it):

```
storeFile=/Users/sdd410/stick-upload.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

- [ ] Keystore created.
- [ ] `key.properties` filled in. Use the full path for `storeFile`.
- [ ] Keystore file and both passwords backed up outside the project (password manager + a second copy).

Without `key.properties`, release builds fall back to the debug key and print a warning. Play rejects those.

## 2. Test on devices (1–2 days)

Fill in `apps/stick/TESTING.md` for three devices:

- [ ] **Android 16 emulator**: `Pixel_8_Pro` is set up.
- [ ] **Android 8 emulator**: not installed yet. Only API 30 and 36 images exist. Install the API 26 image in Android Studio (Device Manager → Create device → API 26) or with `sdkmanager "system-images;android-26;google_apis;x86_64"`.
- [ ] **Your real phone over USB**: turn on USB debugging, then `cd apps/stick && ~/development/flutter/bin/flutter run --release -d <device-id>`.

Never checked on a device so far. Test these first:
- [ ] **Voice clip replay (.m4a)**. If voice clips get skipped, voice playback needs to switch to the `just_audio` package. Tell me and I'll make that change.
- [ ] **Video recording** with the front camera, then replay.
- [ ] **A reminder arrives** at the set time. Set it 2 minutes ahead; reminders are inexact, so allow a few minutes.
- [ ] **The reminder still arrives after a phone restart.**
- [ ] **Tapping "You left yourself a message"** opens the replay.
- [ ] **Denying mic/camera permission**, then allowing it from "Open settings".
- [ ] **Battery tip** shows on your phone's brand (Xiaomi, Samsung, Oppo, Vivo or Realme).
- [ ] **Both home styles** ("Big number" and "Road") look right. Change them in Settings → Home style.

## 3. Finish the look (~1 hour)

- [ ] **App icon:** replace the default Flutter icon with the lime S tile (from `brand/`). Easiest is the `flutter_launcher_icons` package, or Android Studio → New → Image Asset.
- [ ] **Screen-record both home styles** (big number and road) for the Design reel's "A or B?" vote.

## 4. Build the release and check it

```bash
cd apps/stick
~/development/flutter/bin/flutter build appbundle --release
~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest permissions build/app/outputs/bundle/release/app-release.aab
```

- [ ] The `.aab` exists at `build/app/outputs/bundle/release/app-release.aab`. Version is `1.0.0+1`.
- [ ] Permissions show **no** `INTERNET`, no `EXACT_ALARM`, no storage. The expected list is camera, record audio, post notifications, boot completed, wake lock, vibrate and network state.

## 5. Play Console paperwork (from the roadmap, section 4)

- [ ] Store listing: icon, feature graphic, screenshots, short and full description.
- [ ] Privacy policy URL. Say that microphone and camera are used only for the clips, which stay on the phone, and that there's no account and no data collection.
- [ ] Data safety form ("no data collected or shared"), content rating, target audience.
- [ ] Upload the `.aab` to a **closed testing** track.

## 6. Closed test (14 days, fixed)

- [ ] Invite 15–20 testers from the waitlist (Google needs 12 opted in for 14 days in a row).
- [ ] Track: 60% reach day 4, 40% still checking in on day 7.
- [ ] Reels along the way: Design (A or B?), Build: clips, Test: recruiting ("Comment TEST").

## Decisions made during the build (change any you disagree with)

- **Reminders plan 28 days ahead.** Someone who stops opening the app still gets reminders for 4 weeks.
- **"Days you showed up" counts each calendar day once.**
- **An attempt that ends before any check-in learns quit day 1.** The next attempt then shows the rescue screen from Day 1.
- **"Last time you stopped on Day N"** uses the most recent attempt that had a miss.
- **Battery tip** shows in Settings and once after every setup on those brands.
- **Backups:** habit data is included; clips are left out of Google cloud backup (25 MB limit) but are copied when moving directly to a new phone.
- **Fresh start** asks "Keep my clips?" with No as the default.
- **compileSdk 37** (the camera and notification packages need it). The Play target is still Android 16 (API 36).

## Small known issues (fine for the closed test)

- **Replay:** tapping "next" twice very quickly can skip only one clip, and the replay doesn't resume after you leave the app mid-clip.
- **Weekly replay:** it opens right after the check-in that reaches Day 7, rather than the next time you open the app.
- **Permission screen:** after returning from Settings without allowing access, a "Try again" button shows that does nothing (use "Open settings").

## Still open (decide later)

- Where new motivation messages come from (a bigger built-in set, fetched from the internet, or AI-written).
- When to add the Pro in-app purchase: before production or in an update.
