# Samsung Android 14 resume investigation — 0.7.4

Historical device reports and verification for the scoped Android workaround.
The current [reproduction procedure](../../android-troubleshooting.md#samsung-android-14-resume)
is maintained separately; this record does not establish coverage of later builds.

## Investigation and affected-device feedback

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
exact upstream cause. The linked reproduction procedure remains useful
for future changes.

## Recorded verification

Local verification: `make verify` passed (371 tests; 18 opt-in screenshots
skipped; formatting and analysis clean), and `make build-apk-check` compiled
the native workaround successfully (66.7 MB APK). These checks ran immediately
before the metadata-only version bump from 0.7.3+12 to 0.7.4+13. The APK from
that compile check is not a distributable 0.7.4 release. The version-bump check
ran against `origin/main`. No schema or sync-format change was involved.

A subsequent `make build-apk` produced the release-signed 0.7.4+13 APK.
Its package/version and release certificate were verified before it was copied
to Downloads for the user. The user then confirmed successful testing.
A different phone passing resume tests alone would not establish this Samsung
fix.
