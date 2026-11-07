# Android troubleshooting

Recovery procedures and the Samsung surface-resume investigation. General
device acceptance checks belong to [testing](testing.md#checks-that-still-need-a-device);
build/signing procedures belong to [operations](operations.md).

## Data recovery

The main manifest references backup rules for Android 8–11 and data-extraction
rules for Android 12+. Both cloud backup and device transfer exclude the secure
storage preferences and wrapped-key preferences. Ordinary data can still be
backed up by Android. After a restore, API keys must be entered again or
restored through explicitly enabled encrypted key sync. Never test recovery by
uninstalling a user's only unsynced copy.

An initialization failure now has a retry screen; it does not delete the
rating database. Confirm cold start, process recreation, secure-key re-entry
and two-phone sync on physical devices before claiming device-level recovery.

## Samsung Android 14 resume

On 2026-11-03 the user confirmed a black, apparently noninteractive window
on release 0.7.3 after roughly five minutes in the background on
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

### Reproduction and validation

Run this on the affected physical phone:

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

### Historical verification

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
