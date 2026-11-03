# Operations

What to set up and what to press so the app builds, syncs and reaches
friends. There is no server, so operations come down to three things: the
external API keys, the Google OAuth client, and distributing the APK.

**Status: keys, signing and releases are in use since Stages 0–2; the
Google Cloud project for Drive sync since Stage 5 (0.5.0).**

---

## External API keys (every user does this)

Keys are neither in the repository nor in the build: everyone gets their own
and enters them in the app (onboarding or Settings → Sources). The
step-by-step guide for all three services, with what to enter in every form
field, is in [api-keys.md](api-keys.md) (Russian translation:
[api-keys.ru.md](api-keys.ru.md)).

The developer needs their own keys for tests. They never reach the
repository or the test fixtures (fixtures are recorded responses, without
request headers).

### Capturing fixtures

`scripts/capture-fixtures.sh` records live responses of all three APIs into
`app/test/fixtures/`. It takes the keys from a file outside the repository,
`~/.config/framebook/keys.env` (or the path in `FRAMEBOOK_KEYS`):

```sh
TMDB_TOKEN=eyJ...
POISKKINO_KEY=...
OMDB_KEY=...
```

A source without a key is skipped. The script spends 8 of the 200 daily
PoiskKino requests. At the end it checks that no key value ended up in the
saved files. Rerun it when the response format changes or a new request is
added.

---

## Google Cloud: OAuth for Drive

One Google Cloud project per app, set up by the repository owner.

1. Create a project and enable the **Google Drive API**.
2. **OAuth consent screen**: type External, name Framebook, a support email.
   The only scope is `.../auth/drive.appdata` (non-sensitive). Publishing
   needs Branding filled in: the home page
   `https://tiltozavr2545.github.io/Framebook/` and the privacy policy
   `https://tiltozavr2545.github.io/Framebook/privacy.html`, authorized
   domain `tiltozavr2545.github.io`. Both pages are GitHub Pages from the
   `gh-pages` branch; their source is `docs/gh-pages/`, copied over by
   `sync-gh-pages.yml` on main pushes that change `docs/gh-pages/**` (the same scheme as Amicus).
3. **Credentials → OAuth client ID → Android**: package name
   `com.github.tiltozavr2545.framebook` and the signing key's SHA-1. Several
   clients are needed — one for every key that signs builds:
   - the release keystore (builds for friends);
   - the debug keystore of **every** development machine
     (`~/.android/debug.keystore`; the Intel and M4 Macs have different
     ones).

   SHA-1: `keytool -list -v -keystore <file> -alias <alias>`.
   A SHA-1 mismatch is the most common cause of `ApiException: 10` on
   sign-in.
4. **Web client** (type "Web application", no origins or redirects) —
   required: google_sign_in 7 signs in on Android through Credential
   Manager, which wants a `serverClientId`. Its client id is in
   `app/lib/data/sync/google_account.dart` (`googleServerClientId`); a client
   id isn't a secret. The client secret isn't used and never goes into the
   repository.

Set up on 2026-10-26: project `framebook-512810`, the Drive API, Branding
with the GitHub Pages home page and privacy policy, the `drive.appdata`
scope, Android clients for the release key and the Intel Mac's debug key,
and the Web client.

### Testing or Production

While the OAuth app is in **Testing** status:

- only accounts from the Test users list (up to 100) can sign in — friends
  have to be added by hand;
- refresh tokens live **7 days**, after which a new sign-in is needed.

The repository's Stage 5 record says this app was moved to **Production**.
This is the recorded setup, not a live check of the Cloud console. For a new
installation of the Google Cloud project, verify the publishing status there;
leaving it in Testing requires maintaining the test-user list and can force
periodic reauthorization. The app never bypasses consent with an automatic
interactive authorization dialog.

---

## Signing and building

The release key was created on 2026-10-20 and doesn't depend on any one
person:

| Where | What | Why |
|---|---|---|
| GitHub repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | CI signs releases with them (`release-apk.yml`) |
| `~/.config/framebook/` on the Intel Mac | `framebook-release.jks` + `key.properties` | a backup copy: GitHub secrets can't be read back |
| `app/android/key.properties` (gitignored) | a copy of `key.properties` with an absolute path to the key | local `make build-apk` |

The password is random (32 characters) and written down nowhere but these
places. The key is RSA 4096, valid for 100 years, alias `framebook`.

Losing the key means the app can't be updated over the installed one:
friends would have to uninstall the old one, and with it any unsynced data.
The key is lost only if both the repository and the copy on the Mac vanish at
once. For peace of mind the copy of `~/.config/framebook/` could go somewhere
else too (a password manager, an encrypted archive in the cloud), but that is
optional.

Fingerprints — for the Android OAuth clients in Google Cloud (Stage 5):

| Key | SHA-1 |
|---|---|
| release (`framebook`) | `F4:07:7F:14:A1:36:FF:01:70:F1:CB:C6:4A:1A:F4:20:51:4C:0A:FD` |
| debug, Intel Mac | `D0:75:83:3B:53:FB:34:2B:78:97:6E:FD:5D:F3:2B:C4:EE:D0:5B:5B` |
| debug, M4 Mac | take it there: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |

Building:

- `make build-apk` → `flutter build apk --release`, a signed APK. One
  universal APK, no `--split-per-abi`: one file is simpler for friends than
  choosing an architecture.
- Without `key.properties` a release build **fails** rather than being
  silently signed with the debug key. To check that it compiles there is
  `make build-apk-check`: it explicitly allows debug signing, and CI builds
  the same way.
- To build signed on another machine (M4), copy `~/.config/framebook/` and
  `app/android/key.properties` there (the key path in it is absolute — adjust
  it for that machine).
- `keytool` and `apksigner` use the JDK from Android Studio:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. To check an
  APK's signature: `apksigner verify --print-certs <apk>`.
- `applicationId` is `com.github.tiltozavr2545.framebook`, `minSdk` 26,
  `targetSdk`/`compileSdk` 36.

---

## Distribution (Android)

- **A release is a tag.** Bump the version (`make bump-minor` etc.), add to
  [../CHANGELOG.md](../CHANGELOG.md), commit, then
  `git tag v0.2.0 && git push origin v0.2.0`. The `release-apk.yml` workflow
  checks that the tag matches the version in `pubspec.yaml`, runs analyze and
  the tests, builds the signed APK `framebook-0.2.0.apk`, verifies its
  signature and that the certificate is the release one (the SHA-1 above),
  and creates a GitHub Release with it.
- A release is done when the workflow is green and the APK is in the
  release's assets. The published APK isn't downloaded back to check it:
  the workflow has already verified it.
- The workflow fills the release body with GitHub's generated notes; replace
  them with written ones (`gh release edit vX.Y.Z --notes-file …`) — in
  English, like all repository text: what is new, how to install, the
  signing certificate's SHA-1, the TMDB attribution line.
- Installing at a friend's: download the APK from the release page, allow
  installs from that source, install. An update is a new APK over the old
  one, and the data stays (the same signing key, a higher `versionCode`).
- The app checks GitHub Releases on startup at most once per 24 hours after a
  successful response and offers the release page when a newer version is
  available. A failed request may retry on the next launch; Settings also
  offers a manual check.

---

## CI

GitHub Actions on every push/PR: `dart format --set-exit-if-changed`, a check
that generated code is up to date, `flutter analyze`, `flutter test`, a
version bump check on PRs, and an APK build with the debug key. Flutter in CI
is the same 3.32.8 as on the machines. CI needs no secrets: the tests never
call external APIs. Only `release-apk.yml` uses the signing secrets.

## Android data recovery

The main manifest references backup rules for Android 8–11 and data-extraction
rules for Android 12+. Both cloud backup and device transfer exclude the secure
storage preferences and wrapped-key preferences. Ordinary data can still be
backed up by Android. After a restore, API keys must be entered again or
restored through explicitly enabled encrypted key sync. Never test recovery by
uninstalling a user's only unsynced copy.

An initialization failure now has a retry screen; it does not delete the
rating database. Confirm cold start, process recreation, secure-key re-entry
and two-phone sync on physical devices before claiming device-level recovery.

## Samsung Android 14 resume investigation

On 2026-11-03 the user confirmed a black, apparently noninteractive window
on the latest release (0.7.3) after roughly five minutes in the background on
Samsung S23 / Android 14 / One UI 6. Immediate resume works; the user's Nothing
Phone does not show the issue. The previous apparent recovery after updating
was not a confirmed resolution.

This matches an upstream Samsung SurfaceView report:
[flutter/flutter#139630](https://github.com/flutter/flutter/issues/139630) and
[the One UI 6 reproduction](https://github.com/flutter/flutter/issues/139814).
These reports concern older Flutter versions and are supporting evidence,
not proof of the cause in this application. No affected-device logs have
been captured and no S23 reproduction has been run locally.

The 0.7.4+13 fix changes
`app/android/app/src/main/kotlin/com/github/tiltozavr2545/framebook/MainActivity.kt`.
`MainActivity` applies the upstream suggested delayed `requestLayout` to the
actual `FlutterSurfaceView` on Samsung API 34 only, after resume and regained
window focus, using a 100 ms delay to run after visibility/focus callbacks.
A new request replaces the previous pending one. Pending work is cancelled on
pause/destroy and on replacement of the surface. The callback checks attachment, foreground state and focus.
It does not restart the activity, reset navigation or change renderer.
On 2026-11-03, after receiving the signed 0.7.4 APK to share with the friend,
the user confirmed it works and authorized release. This is user-reported
affected-device validation; it is not a local reproduction or proof of the
exact upstream cause. The full regression checklist below remains useful
for future changes.

Validation on the affected physical phone:

1. Install a release-signed candidate over the existing app, preserving data.
2. Open a card with a saved rating, return home, and use another app for at
   least five minutes. Return through Recents; repeat after locking/unlocking
   and by opening the launcher icon. Check drawing, scrolling and taps.
3. Repeat an immediate return and a Google account-dialog round trip.
4. If the screen goes black, try rotating or opening Recents and returning
   again. Recovery after these actions supports the surface hypothesis but
   is not by itself a root-cause diagnosis.
5. With USB debugging available, compare `adb shell pidof
   com.github.tiltozavr2545.framebook` before/after the pause and capture
   logcat around the failure locally. Distinguish a surviving process with
   a lost surface from process recreation, a native crash or an ANR. Keep
   logs private; do not add account data or credentials to the repository.

Local verification: `make verify` passed (371 tests; 18 opt-in screenshots
skipped; formatting and analysis clean), and `make build-apk-check` compiled
the native workaround successfully (66.7 MB APK). These checks ran immediately
before the metadata-only version bump from 0.7.3+12 to 0.7.4+13. The APK from
that compile check is not a distributable 0.7.4 release. The version-bump check
is run against `origin/main`. No schema or sync-format change is involved.

A subsequent `make build-apk` produced the release-signed 0.7.4+13 APK.
Its package/version and release certificate were verified before it was copied
to Downloads for the user. The user then confirmed successful testing.
A different phone passing resume tests alone would not establish this Samsung
fix.
