# Correctness and resource review — 0.9.0

Starting revision: `f8e6b10`, version `0.9.0+20`, clean working tree.
The user requested repeated review, repairs and verification, then stopped
further findings and requested documentation updates, a commit, push and release.
All changes in this review belong to the prepared 0.9.0+20 release. No schema,
sync-format or dependency change is needed.

## Confirmed findings and repairs

| Finding | Repair and regression evidence |
|---|---|
| Title cards used aggregate series/season credits, while analytics still requested ordinary credits. Earlier-season actors were omitted and aggregate crew jobs were not parsed. | Use `aggregate_credits` for TV/season analytics, preserve each person's professions and deduplicate them, retain ordinary film/episode credits and guest stars. Version the derived cache namespace to replace incomplete entries. `tmdb_client_test.dart` reproduces the old request and verifies roles; `people_index_test.dart` verifies cache replacement. |
| Moving the device clock backwards made future-dated external ratings appear fresh and prolonged the in-memory failure delay. Interactive and background refresh could remain suppressed until the old date. | Treat negative cache ages as stale and apply failure throttling only to timestamps at or before now. `ratings_service_test.dart` covers background eligibility, interactive refresh and recovery after a source failure. Both regressions failed before the repair. |
| A future last-sync timestamp suppressed automatic Drive sync on startup/resume. | Apply the five-minute throttle only when the last sync is at or before now. `sync_controller_test.dart` reproduces the missed startup sync and verifies ordinary quick resumes remain throttled. |
| Startup cache pruning called synchronous filesystem metadata reads for every cached response despite being an asynchronous cleanup. | Await file modification times. Existing file-cache tests verify expiration, the exact cutoff and missing/unavailable directories. No claim about measured Android startup improvement is made. |
| Source documentation promised complete mini-snapshot refresh every 30 days, which no worker implements. | Describe the existing card/save refresh and the separate translated-title refresh with 24-hour reuse. No new catalog scan is introduced. |
| Applying an unchanged 3,000-entry library performed 6,011 SELECTs, including per-row rereads of data already loaded inside the same transaction. Exact row ties also serialized and hashed identical payloads. Orphan cleanup decoded full notes and snapshots just to obtain keys. | Reuse the transaction snapshot, including newer unreferenced works; compare complete Drift values before hash tie-breaking; select only keys during orphan cleanup. `sync_store_reads_test.dart` checks bounded reads on both first and unchanged apply, complete row preservation and newer orphan metadata. Existing merge/convergence tests remain required. |
| API-source headings and required/optional labels overflowed at 320 dp with 2× text scaling in both locales. | Allow headings and labels to wrap. `api_keys_layout_test.dart` reproduces both overflowing layouts and verifies both supported locales. |
| The score reel could change while a save was pending, although persistence used the previously captured score. On failure, retry could submit a different draft. | Disable reel gestures/accessibility adjustments while saving and stop an existing fling at the captured score. Controlled-save regressions in `rating_note_test.dart` verify unchanged retry drafts both at rest and during a fling. The at-rest regression failed before the repair. |

## Host measurements

`test/benchmarks/sync_apply_benchmark.dart` applies 1,500 unchanged ratings with
512-character notes and 1,500 watchlist entries backed by 3,000 mini snapshots.
It uses a real in-memory SQLite database, two warmups and five measured runs,
and checks that every work, rating and watchlist row is preserved. The executor
interceptor counts actual SELECTs. Timing has no pass/fail threshold.

Before repair: median **2,242,954 µs**, samples **2,041,774; 2,082,693;
2,242,954; 2,322,553; 3,522,521**, with **6,011 SELECTs** in every measured run.
After reusing reads and selecting only orphan keys: median **1,112,069 µs**,
samples **801,472; 1,002,407; 1,112,069; 1,286,306; 1,634,775**, with **10 SELECTs**.
Including equality shortcuts: median **808,104 µs**, samples **675,171; 788,531;
808,104; 867,217; 982,225**, still **10 SELECTs**. The measured median is about
64% lower than the initial sample. These are host JIT samples during automated
verification, not Android frame-time measurements.

## Verification

The aggregate-credit repair passed 53 focused tests; clock/cache repairs passed
28; sync, convergence, bounded reads and key-field layouts passed 102; the rating
editor passed four. An intermediate full verification passed 545 tests with
20 opt-in renderers skipped, before the final sync/layout/editor changes.
Final `make verify TEST_ARGS='--coverage --reporter expanded'` passed:
**551 tests passed**, **20 opt-in renderers skipped**, formatting and analysis
clean, version-script fixtures passed. Release compilation is checked separately.
Tests use fakes and fixtures without external API requests. Phone performance,
real Google authentication and two-device synchronization remain separate from
host automated verification.
