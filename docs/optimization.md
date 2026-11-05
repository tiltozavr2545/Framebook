# Framebook 0.8.3 optimization investigation

Target: **0.8.3+17**. This document separates measured results from candidates.
The completed correctness review is in
[reviews/2026-11-05/README.md](reviews/2026-11-05/README.md).

## Baselines

The baseline universal release APK contains the November 5 review repairs and
still carries the preceding `0.8.2+16` metadata. It is 66,875,214 bytes
(66.9 MB). Measurements below are local Intel-host results, not device energy
or frame-time measurements. No diagnostic build was installed or published.
The normal universal build was then repeated with `0.8.3+17`; its APK has
the same byte size. Android manifest inspection confirms versionName 0.8.3
and versionCode 17.

| APK contents | Stored bytes, all included architectures |
|---|---:|
| Flutter engine libraries | 31,672,216 |
| Compiled Dart application/framework snapshots | 28,395,924 |
| SQLite libraries | 4,601,420 |
| Other native library | 22,900 |
| Seven application fonts | 424,033 |
| TMDB logo | 133,797 |

Native libraries account for 96.7% of this universal archive. This includes
framework/runtime code, not just Framebook source. The optional ARM64
size-analysis build is 27.2 MB; dependency libraries for other ABIs can still
be present in this diagnostic APK. It is not the universal distribution.

Flutter's ARM64 AOT summary attributes about 3 MB to Flutter, 823 KB to
Framebook, 223 KB to framework localizations, 207 KB to Drift, 119 KB to
fl_chart, 62 KB to googleapis and 60 KB to cryptography. These are attributed
snapshot sizes, not predictions of APK savings from removing a dependency.
The raw analysis is a local DevTools artifact, outside the repository.

## Measured work and prioritized candidates

### Implemented: avoid unnecessary sync payload hashes

`data/sync/merge.dart` now checks time, writer and deletion status before
hashing a complete payload. Ordering, deletion digests and format 4 are
unchanged. On the optional merge benchmark, median `mergeStates` plus
`remoteBehind` fell from 612,628 to 321,345 µs, about 48% for this workload.
The fixture contains 6,000 snapshots, 3,000 ratings with 512-character notes,
and 3,000 watchlist entries. Existing merge algebra/convergence tests pass.

### First runtime target: read only watchlist data

`Library.watchWatchlist` calls `SyncStore.read` for each notification, loading
every rating and its note, all snapshots, watchlist rows and sync registers.
The view only needs watchlist snapshots, relevant live-rating keys and
selection fences. Changes to works or sync-state metadata can trigger this
read even when the visible list is unchanged.

The optional watchlist benchmark uses 3,000 movie ratings with 1,024-character
notes and 50 watchlisted films. Median stream-to-first-value time was
99,464 µs. A joined-query comparison over the same movie-only data was
10,290 µs. This is a potential reduction in unnecessary work, not an already
implemented tenfold application speedup. A replacement must preserve season
grouping, rated-season exclusion, legacy derived fences, offline conflict
rules and transactional consistency.

### Energy and resume target: localized-title refresh

`data/library/localized_titles.dart` walks all live saved titles on startup,
language changes, successful sync and every resume. An unchanged language and
unchanged library can therefore reread and decode every cached TMDB card.
The HTTP cache reduces network calls but does not eliminate disk reads,
JSON parsing or snapshot checks.

The walk also has no foreground check between requests: pausing the app does
not deactivate it. A created non-auto-dispose provider can outlive the shell,
so it should also require a usable TMDB key before catalog work starts.

Track successful refreshes per language/title identity and invalidate them
when relevant snapshots change, or coalesce short resume cycles. Preserve
immediate language changes, new data arriving through sync, offline retry and
renumbered-part identity protection. Suspend work when backgrounded and resume
only the current generation. Measure cache reads/API calls and resume
latency before selecting the policy; no battery saving is claimed yet.

### Energy and lifetime target: background timers

`BackgroundRefreshNotifier._loop` schedules its next interval after a pass
even if that pass finished after disposal. Disposal during an in-flight
request can retain an obsolete loop/service until that timer fires. A paused
loop also wakes on its half-hour timer to discover that it is still paused.
The pacing flag is set by source completion even when a lookup short-circuits
because an IMDb ID is missing; this can add a three-second pause without an
external request. An actual-request signal should be distinct from completion.

Check cancellation before creating the next timer and use a resume signal
without a timed wake while backgrounded. Add lifecycle tests for disposal
during an active request and key changes during a pass. Preserve the initial
delay, foreground refresh cadence, daily budgets and prompt resume behavior.

### Memory and image work

Full-screen person photos and episode stills can request original images.
Several pages can be decoded near the current page; RGBA decode cost grows
with pixel count even when the network response is small. Bound decoding to
the viewport/zoom requirement while keeping the existing full-screen gestures.

`posterTintProvider` samples at most 4,096 pixels, but first reads all RGBA
pixels of the header image. Reopening a disposed card can repeat this work.
A small bounded cache of successful colours could avoid repeated readbacks;
failed loads must remain retryable. Profile image memory and frame time on a
physical device before changing decode resolution or cache lifetimes.

## APK-size options

- Measure `--split-debug-info` without obfuscation on the same universal
  build. Adoption requires keeping matching symbols for every distributed
  build and documenting stack-trace symbolization. The measured archive is
  62,664,526 bytes, down 4,210,688 bytes (6.3%) from the baseline. It retains
  ARM32, ARM64 and x86-64 application libraries. The three corresponding
  symbol files are retained locally; the release build defaults have not
  changed. This saves download/archive size, not application execution time.
- A separate ABI-specific download can save much more than removing small
  assets, but changes the existing single-universal-APK distribution choice.
  The current distribution remains universal.
- `json_serializable`/`json_annotation` and `cupertino_icons` have no direct
  application imports or annotations. They are cleanup candidates; the
  Cupertino font is already reduced to 848 unpacked bytes (533 stored bytes),
  so its removal alone cannot provide meaningful size savings. Removing an
  unused generator can reduce build work, not necessarily application CPU use.
- Native-library compression is a packaging tradeoff. AGP leaves libraries
  uncompressed/page-aligned by default for this minSdk. Compressed libraries
  require installation-time extraction and can increase installed disk use;
  compare archive size and installed storage separately before changing it.
  See [AGP packaging](https://developer.android.com/reference/tools/gradle-api/8.9/com/android/build/api/dsl/JniLibsPackaging)
  and [Android's extraction guidance](https://developer.android.com/guide/practices/page-sizes).

The measurement workflow follows
[Flutter's size-analysis guidance](https://docs.flutter.dev/perf/app-size).
No Flutter upgrade, database/protocol change, ABI removal or altered release
packaging has been applied by this investigation.

## Reproduction and next validation

```sh
cd app
flutter test test/benchmarks/merge_benchmark.dart
flutter test test/benchmarks/watchlist_benchmark.dart
flutter build apk --release --target-platform android-arm64 --analyze-size \
  --code-size-directory=/private/tmp/framebook-code-size -PallowDebugSigning=true
```

Host benchmarks use two warmups and five measured samples; they do not gate
CI on timing. Device measurements should cover cold/warm start, a large
library, repeated app switching, image browsing and foreground/background
request/timer counts. Real energy measurements and the two-device sync check
remain outstanding. The Intel Mac must not run an emulator.
