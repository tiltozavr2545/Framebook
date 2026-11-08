# Android troubleshooting

Recovery procedures and Samsung surface-resume diagnostics. General
device acceptance checks belong to [testing](testing.md#checks-that-still-need-a-device);
build/signing procedures belong to [operations](operations.md).

## Data recovery

The main manifest references backup rules for Android 8–11 and data-extraction
rules for Android 12+. Both cloud backup and device transfer exclude the secure
storage preferences and wrapped-key preferences. Ordinary data can still be
backed up by Android. After a restore, API keys must be entered again or
restored through explicitly enabled encrypted key sync. Never test recovery by
uninstalling a user's only unsynced copy.

An initialization failure offers Retry; it does not delete the
rating database. Confirm cold start, process recreation, secure-key re-entry
and two-phone sync on physical devices before claiming device-level recovery.

## Samsung Android 14 resume

The activity applies a delayed layout request to the Flutter surface after
resume and regained focus on Samsung API 34 only. Pending callbacks are
replaced or cancelled on pause/destroy and surface replacement; execution
requires an attached, focused foreground surface. It preserves activity and
navigation state. The implementation lives in
`app/android/app/src/main/kotlin/com/github/tiltozavr2545/framebook/MainActivity.kt`.

Affected-device reports, the upstream hypothesis and original build/test
results are retained in the [0.7.4 investigation](reviews/0.7.4/README.md).
Use the procedure below to validate changes on an affected phone.

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
