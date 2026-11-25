# Releasing Stick

## Branches

| Branch | What it is | Merges in | Releases to |
|---|---|---|---|
| `feat/…`, `fix/…` | One change each, deleted after merge | | nowhere directly |
| `develop` | **Base branch** (GitHub default, PRs target it) | feature PRs, after PR checks pass | testers: internal or closed track |
| `master` | **What is live** | a release PR from `develop` | production |

PR checks run on every PR into `develop` and `master`.

## Making a release

1. Add the Play release notes: `docs/release-notes/<version>.txt` (500 characters max, the `<en-US>` lines are optional). Merge it like any change.
2. GitHub → **Actions** → **Release to Play** → **Run workflow**:
   - **Use workflow from:** `develop` for testers, `master` for production.
   - **Version name:** e.g. `1.2.0`.
   - **Track:** `internal`, `closed` (Play's closed testing track, `alpha`) or `production`.
   - **Unlock all Pro features:** on for testing tracks, off for production (the workflow refuses Pro unlocked on production).
   - **Build number:** leave empty. It becomes `100 + run number`, so it always goes up.
3. The workflow runs the checks, builds the signed `.aab`, uploads it to the track **as a draft**, tags the commit `v<version>` and keeps the `.aab` under the run's **Artifacts** for 90 days.
4. Play Console → Stick → the track → the draft release → **Start rollout**.

Guard rails: production only from `master`; testers only from `develop` or `master`; a version can be released once (its tag must not exist yet); the bundle must be signed with the upload key and must not ask for internet, exact alarms or storage.

To ship to everyone: open a PR `develop` → `master`, merge it, then run the workflow on `master` with track `production`.

## One-time setup

### 1. Play Console: a service account that may upload

1. Google Cloud Console (console.cloud.google.com) → pick or create a project → **APIs & Services** → **Enable APIs** → enable **Google Play Android Developer API**.
2. **IAM & Admin** → **Service accounts** → **Create service account** (name e.g. `stick-release`) → **Done**.
3. Open it → **Keys** → **Add key** → **Create new key** → **JSON** → it downloads a `.json` file. Keep it private.
4. Play Console → **Users and permissions** → **Invite new users** → paste the service account's email (`…@….iam.gserviceaccount.com`) → **App permissions** → add **Stick** → tick **Release apps to testing tracks** and **Release to production, exclude devices, and use Play App Signing** → **Invite user**.

### 2. GitHub: repo secrets

github.com/sdd410/stick → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**, five times:

| Name | Value |
|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | the whole content of the `.json` key file |
| `ANDROID_KEYSTORE_BASE64` | run `base64 -i ~/stick-upload.jks \| pbcopy` and paste |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password (`storePassword` in `android/key.properties`) |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password (`keyPassword` in `android/key.properties`) |

### 3. GitHub: branches

- Rename `main` to `master`: **Settings** → **Branches** (or **General** → **Default branch**) → ✏️ next to `main`.
- Create `develop` from `master` and make it the **default branch** (**Settings** → **General** → **Default branch** → ⇄ → `develop`).
- Optional, recommended: **Settings** → **Branches** → **Add rule** for `master` and `develop`: require a pull request and the PR checks to pass before merging.

## Building by hand (fallback)

`flutter build appbundle --release --dart-define=ALL_PRO=true` with `android/key.properties` in place (never commit it). The version comes from `pubspec.yaml` unless `--build-name` / `--build-number` are given.
