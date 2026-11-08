# Framebook 0.8.4 optimization

Historical implementation and measurement evidence. Current runtime rules are
maintained in [client architecture](../../client-architecture.md); current
build/release procedures belong to [operations](../../operations.md).

Target: **0.8.4+18**. This records the implemented follow-up to the
[0.8.3 correctness review](../2026-11-05/README.md), the measurements,
and the limits of those measurements. No schema or sync-format change is needed.

## Completed work

- **Selective watchlist reads.** The stream joins live watchlist rows with
  their snapshots. It reads only the keys of relevant live season ratings,
  the required series snapshots and selection fences. It never loads rating
  notes, unrelated snapshots or deletion registers. Reads remain transactional;
  batches stay below SQLite parameter limits. Persisted and legacy derived
  fences use the same helper as sync. Fences are grouped by series before
  filtering. Regression coverage compares the old full-state result against
  the selective reader across 450 series, 900 seasons, live/deleted ratings,
  tombstones and conflicting offline selections.
- **Localized-title reuse.** Successful results are remembered for up to
  24 hours in the current language/key generation. Resume and sync still check
  saved snapshot identities, but unchanged titles do not reread and parse
  cached TMDB cards. Changed/imported snapshots and newly saved titles refresh;
  failures retry on resume. Key or language changes invalidate the generation.
  Only live keys and required snapshots are loaded, without rating notes or
  sync registers. Groups are built in one pass. Work requires a TMDB key and
  stops between requests while the app is not resumed; an in-flight result
  cannot update titles while backgrounded or after disposal. Renumbered-part
  identity checks and rating timestamps are preserved.
- **Foreground scheduling.** Background ratings refresh waits for a lifecycle
  signal while paused instead of creating half-hour wakeup timers. Disposal
  and key changes prevent an old in-flight pass from scheduling its next timer.
  Losing foreground status interrupts pacing waits. Cancellation is checked
  between sources as well as between titles. Pacing now uses an actual-lookup
  callback: a missing IMDb ID, an exhausted local budget or a shared in-flight
  request does not create an extra three-second delay. Queue joins avoid
  selecting rating notes, only required series ancestors are read, and no
  refresh timer is created without source keys. Source quotas, the foreground
  interval and the initial foreground delay remain in place.
- **Image memory.** Full-screen photos and stills decode to the physical
  viewport at up to fourfold zoom, capped at 4,096 pixels on each side
  (at most 64 MiB of RGBA per decoded image). Aspect ratio is retained and small
  images are not upscaled. Offline viewing and paging/zoom gestures remain
  available. Original downloads remain in the normal disk cache; the cap
  controls decoded memory, not transfer size. This is a per-image bound,
  not a cap on the entire Flutter image cache or process.
- **Poster colours.** A container-scoped LRU retains up to 128 successful
  colours, keyed by the resolved image URL. Reopening a card avoids another
  RGBA readback. Neither decoded images nor failures are retained by this
  cache; failed/offline loads remain retryable.
- **Smaller universal APK.** Release and compile-check targets use
  `--split-debug-info=build/symbols/<version+build>` without obfuscation.
  ARM32, ARM64 and x86-64 remain included. The release workflow requires all
  three symbol files and uploads them as `framebook-<version>-symbols`
  Actions artifacts for 90 days. Release assets contain only the APK; download
  symbols before artifact expiry and retain a local backup for crash decoding.
  See [operations.md](../../operations.md#android-symbols) for symbolization.
- **Unused dependencies.** Removed the direct `cupertino_icons`,
  `json_serializable` and `json_annotation` declarations and the unused
  generator's `source_helper`. Other resolved versions stay unchanged;
  `json_annotation` remains a required transitive development dependency.
- **Sync hashing (shipped in 0.8.3).** Compare timestamps, writers and deletion
  status before hashing payloads. Merge ordering and format 4 are unchanged.

## Measurements

Measurements are synthetic Intel-host results, not physical-device battery
or frame-time measurements. They demonstrate avoided work, not a tenfold
speedup of the whole application or a measured battery-life improvement.

The 0.8.3 universal release APK is **66,875,214 bytes**. Native libraries
account for 96.7% of the archive:

| APK contents | Stored bytes, all included architectures |
|---|---:|
| Flutter engine libraries | 31,672,216 |
| Compiled Dart application/framework snapshots | 28,395,924 |
| SQLite libraries | 4,601,420 |
| Other native library | 22,900 |
| Seven application fonts | 424,033 |
| TMDB logo | 133,797 |

The preliminary same-source split-debug-info build was **62,664,526 bytes**,
a reduction of 4,210,688 bytes (6.3%). The final **0.8.4+18** universal
compile-check APK is **62,663,440 bytes** (62.7 MB), saving
4,211,774 bytes (6.3%) against 0.8.3. All three ABIs and matching symbol
files were verified. The manifest reports versionName 0.8.4 and versionCode 18.

On the optional merge benchmark, median `mergeStates` plus `remoteBehind`
fell from 612,628 to 321,345 microseconds, about 48%. The fixture contains
6,000 snapshots, 3,000 ratings with 512-character notes and 3,000 watchlist
entries. Existing merge algebra/convergence tests pass.

The initial watchlist investigation measured 99,464 microseconds for the
full-state reader and 10,290 microseconds for a movie-only joined-query
prototype. The committed benchmark now compares the actual selective reader
with the former full-state approach over 3,000 ratings with long notes and
50 watchlisted films. Its measured median was **10,278 microseconds** for
the selective reader versus **69,238 microseconds** for the full-state
baseline (about 85% less elapsed time in this fixture). Season semantics are
separately covered by regressions.

Localized-title tests count API method calls: an unchanged resume adds no
calls after success; an imported changed snapshot refreshes; a failed title
retries; the 24-hour boundary refreshes again. A blocked-request lifecycle test
checks that backgrounding neither applies its result nor starts the next title.
Image decoding tests verify a 1,000 × 2,000 source becomes 200 × 400 within a
400 × 400 decode budget. Poster-colour tests cover reuse and failed-load retry.

## Evaluated options not selected

These are deliberate decisions for this release, not unfinished repairs:

- **Separate ABI downloads:** larger download savings, but they change the
  agreed single-universal-APK installation flow. All three ABIs stay supported.
- **Native-library compression:** it can shrink the archive while increasing
  installed storage through extraction. Retain AGP's existing packaging;
  see [AGP packaging](https://developer.android.com/reference/tools/gradle-api/8.9/com/android/build/api/dsl/JniLibsPackaging)
  and [Android's extraction guidance](https://developer.android.com/guide/practices/page-sizes).
- **Replacing small libraries or dropping translations:** ARM64 analysis
  attributed roughly 3 MB to Flutter, 823 KB to Framebook, 223 KB to framework
  localizations, 207 KB to Drift, 119 KB to fl_chart, 62 KB to googleapis and
  60 KB to cryptography. Those snapshot attributions do not predict archive
  savings and do not justify replacing working dependencies.

## Reproduction and validation limits

```sh
cd app
flutter test test/benchmarks/merge_benchmark.dart
flutter test test/benchmarks/watchlist_benchmark.dart
cd ..
make verify
make build-apk-check
```

Host benchmarks use two warmups and five measured samples and do not gate CI
on timing. Flutter's [size-analysis guidance](https://docs.flutter.dev/perf/app-size)
explains the diagnostic AOT report. Physical-device cold/warm start, image
memory, frame-time and energy measurements, and the two-device sync check
remain manual validation work. The Intel Mac must not run an emulator.

`make codegen` passed without generated-code or schema changes. Full
`make verify TEST_ARGS='--coverage --reporter expanded'` passed: **474 tests**,
18 opt-in renderers skipped, formatting and analysis clean. Non-generated
line coverage is **6,990 / 7,687 (90.9%)**. The retained-timer regression was
also checked against a temporary restoration of the original bug: it failed
on the pending timer, then passed with the production fix restored.
`make verify-version BASE_REF=HEAD` and `make build-apk-check` passed before
commit. The physical-phone check found no connected device; no emulator was
started and no real-account sync was performed.

## Release workflow recovery

The first 0.8.4 release attempt passed tests but stopped during Gradle startup:
the hosted runner's default Java 25 was incompatible with Gradle 8.12. CI and
release jobs selected Temurin JDK 21. The current recovery procedure is in
[operations](../../operations.md#ci-java-and-release-recovery).
