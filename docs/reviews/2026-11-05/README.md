# Repository audit and repairs — 2026-11-05

Starting revision: `2fa1641`, app version `0.8.2+16`, with a clean working tree. This is
a repair/review record, not a claim that every file or runtime interleaving
is verified. After closing the review, the user requested version `0.8.3+17`
for these repairs and the optimization work. The review and measurement
steps did not publish or install an APK or access real-account data. Commit,
push and release were authorized separately after the review was closed.

## Confirmed defects and repairs

Each functional finding below was first reproduced by a test asserting the
desired behavior, then repaired. Test logs are local under `/private/tmp/`.

| Finding | Repair | Regression evidence |
|---|---|---|
| Concurrent cache writers shared one temporary file; overlapping writes published unreadable JSON. | Each write owns a unique staging directory, atomically renames a complete file, then cleans up. | 24 overlapping writes through two cache instances leave one complete readable response. |
| A valid cache envelope with a broken body blocked a card even with working network. | Invalid cached JSON is a miss; it cannot be a fresh answer or fallback. | A damaged body is refetched and repaired. |
| Unreadable HTTP 200 from TMDB prevented use of a valid stale card. | Fall back to decoded stale data without caching the invalid response. | HTML HTTP 200 preserves the stale response. |
| Fractional API IDs were truncated; overflowing JSON exponents could throw during integer conversion. | Integer fields require integral, finite values; floating-point IDs must be exactly representable. Nonfinite numeric fields are omitted. | Direct JSON-helper regressions include fractional IDs, overflow, NaN and infinity. |
| Source ratings accepted nonfinite and out-of-scale values, including OMDb string `Infinity`. | Validate each source scale and nonnegative OMDb vote counts before persistence. | TMDB, PoiskKino and OMDb boundary regressions. |
| Title sorting placed five-digit episode numbers before smaller four-digit numbers. | Pad episode numbers to the full five-digit range supported by WorkKey. | Complete ordering across E999, E9999, E10000, E99999 and the next season. |
| Version tooling accepted malformed names and unsafe build numbers; comparisons lost precision on large parts. | Share canonical validation, enforce positive bounded builds, prevent bump overflow, compare names as exact decimal strings. | Disposable shell fixtures cover valid bumps, malformed versions, overflow, unchanged files on failure and monotonic comparisons. |
| Failed Google initialization poisoned all subsequent retries, and explicit sign-in initialization errors escaped the typed UI boundary. | Retain successful/in-flight initialization, clear failed futures and translate sign-in initialization failures. | Fake SDK fails once then succeeds; configuration failures become SignInException. No network/account access. |
| Discover shelf captions overflowed at large font sizes. | Allocate scalable caption height independently of fixed-size posters. | 320 dp layout at 1.0×, 1.8×, 2.0× and 3.0×, including title wrapping and year bounds. |
| A request using an old API key replaced the status after a dependency rebuild. | Scope refresh callbacks to their individual build lifetime; Notifier.ref.mounted alone is insufficient because the notifier survives rebuilds. | Controlled requests finish in reverse order after replacing the ratings service. |
| A late failed request overwrote ratings already fetched successfully by a new service instance. | Insert error rows with primary-key conflict DO NOTHING, checking absence atomically at write time. | Old request starts, new request persists KP/IMDb values, old request fails; both successful rows must survive. |
| Storage failure after confirming an import escaped the UI error boundary. | Catch application-stage failures and show the existing file-operation error without reporting success. | Import UI tests cover file cancellation, merge, replacement confirmation/cancellation, failed persistence, unreadable/oversized files and too-new formats. |

Documentation corrections include the README's current version, actual TMDB
credits requests, watchlist season snapshots, numeric/cache failure rules and
the newly automated shell checks. The completed Discover accessibility item
was removed from postponed work.

## Measured sync optimization

Version comparisons previously computed SHA-256 over both complete row
payloads before checking timestamps. Hashes now run only on an exact tie of
timestamp, writer and deletion status; the ordering and file format are
unchanged. Existing merge algebra/convergence regressions remain required.

The optional `test/benchmarks/merge_benchmark.dart` exercises two synthetic
states with 6,000 snapshots, 3,000 ratings (512-character notes), and 3,000
watchlist entries each. A sample performs both `mergeStates` and
`remoteBehind`; two warmups precede five measured runs. On this Intel host,
median elapsed time decreased from 612,628 µs to 321,345 µs (about 48%).
These Flutter-test/JIT host measurements are a comparison for this workload,
not an Android latency, battery or whole-application speed claim. No runtime
timing threshold was added to the test suite.

## Validation and remaining scope

- Cache regressions: 48 passed after repair.
- Google account regressions: 8 passed after repair.
- Discover shelf tests: 5 passed after repair.
- Version script fixtures: passed; now included in `make verify` and CI.
- Structural checks parsed 41 tracked JSON/ARB and 21 XML/plist files; existing
  tracked shell scripts passed `sh -n`.
- Final review verification: `make verify TEST_ARGS=--coverage` passed with
  464 tests, 18 opt-in renderers skipped, clean formatting/analysis, and
  passing shell fixtures. Ratings-race tests and all 11 import-UI scenarios
  are included. The same full verification passed after the requested
  `0.8.3+17` metadata bump, as did `make verify-version BASE_REF=HEAD`.
- LCOV: 6,897/7,602 executed Dart lines (90.7%), excluding generated
  files/localizations. `main.dart` and native code are absent from that ratio;
  table declaration getters are included even though runtime schema code is
  generated. Coverage is not a correctness sign-off.
- `make codegen` passed without generated-code or schema changes.
- Final `make build-apk-check` passed: 66,875,214-byte universal APK (66.9 MB),
  including the race and import repairs. After the metadata bump, a normal
  universal build has the same size and manifest versionName 0.8.3 /
  versionCode 17. No APK was installed or published.
- All 380 relative Markdown file links resolved. All current shell scripts
  passed syntax checks. PNG structure/CRCs passed for 27 tracked images;
  seven font files have valid sfnt signatures.
- The review phase is closed at the user’s request. Further work addresses
  application size, runtime performance and energy use.


No emulator, live external API, destructive Drive workflow or device restore
has been exercised. The physical-device boundaries in [testing.md](../../testing.md)
still apply. Installed Google Sign-In implementation was inspected to check
initialization ownership; dependency versions were not changed.
