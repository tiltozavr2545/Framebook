# Responsiveness review and repairs — 2026-11-06

Starting revision: `9c3c25a`, version `0.8.5+19`, clean working tree.
The user reported input lag, especially when favouriting a person. This review
covers the new recommendation/people/insight dependency graph and checks the
existing storage, sync, source, startup, navigation, image and Android
lifecycle boundaries against their tests and documented invariants. It is not
a claim that all possible runtime interleavings or device behavior are verified.
No dependency, schema or sync-format changes are needed. At the user's
request, these repairs are included in `0.8.5+19` without a new version bump.

## Findings and repairs

| Finding | Repair and evidence |
|---|---|
| The shell kept the recommendation feed active behind nested cards. Favourite changes restarted retrieval, then every result synchronously reranked the full pool on the UI isolate. | Precompute scores, genre sets and row diversity context; batch notifications. Large pools run in a separate isolate, with serialized workers, superseded-input skipping and an 80 ms debounce. Real-isolate regressions check transferred inputs, latest results and immediate hidden/rated exclusions. |
| Unchanged recommendation sources were repeatedly fetched/parsed after changing favourite people. | Reuse successful and in-flight jobs in a 64-entry client/language/day LRU; failures remain retryable. Tests count unchanged API calls and retries. |
| People browsing recomputed all people, roles and creative pairs inside `build`, including on every favourite change. Credit progress also retriggered whole-profile work. | Shared insights providers keyed by kind; select entry/candidate identity separately from progress. More than 80 ratings are analyzed in a serialized isolate worker. Unchanged index snapshots retain identity. |
| Favourite buttons watched the whole people list and rescanned/rebuilt for unrelated changes. | One shared ID set and per-person membership selection. Persistence and sync still use the original transaction/register. |
| Expanding all people in Stats eagerly built and laid out every profile inside a column. | Stats and insight rows use lazy slivers. A phone-sized test expands 1,000 people, checks that fewer than 40 tiles exist simultaneously and reaches the last person. |
| Optional catalog enrichment kept scheduling after backgrounding. | Share foreground state; stop starting work and resume incomplete credit passes. Controlled in-flight tests check four initial calls, no further background calls and completion after resume. |
| Concurrent failed Not interested writes restored an earlier optimistic set that had itself failed to persist. | Roll back to the last successfully persisted set. A failing fake store reproduces two overlapping failures and verifies the exact rollback. |
| Moving analytics to asynchronous work exposed a decade drill-down dependency on not-yet-ready insights. | Build its subset directly from the current ratings; a pending-insights widget test opens the correct decade. |

## Measurements

The optional `test/benchmarks/recommendations_benchmark.dart` ranks 1,000
candidates and 1,000 watchlist entries against 500 taste signals. Two warmups
precede five samples. On this Intel host, median pure-ranking time decreased
from **476,626 µs** to **108,125 µs** in the first optimized run (about 77%).
The final standalone run after full verification measured **70,424 µs**
(samples: 58,326; 63,924; 70,424; 73,532; 74,063 µs). Host/JIT scheduling
varies; these are measured samples, not a fixed latency bound.
The output digest remained
`1d7eeee141f3ce23b3ef17e3953cebbbddeb6b40df88c0290c03794c1792dd9f`,
covering keys, ordering, explanations and exploratory flags in all four rows.
The benchmark now asserts that baseline. Android uses the background worker
for this size of input; these JIT host timings do not measure phone input
latency, frame time, battery life or whole-app speed.

## Validation

`make verify TEST_ARGS='--coverage --reporter expanded'` passed: **532 tests**,
20 opt-in renderers skipped, formatting and analysis clean; version-script
fixtures passed. Non-generated Dart line coverage is **8,386 / 9,243 (90.7%)**.
Coverage is an audit aid, not a device performance or correctness guarantee.
The separate ranking benchmark also checks the unchanged output digest.
The release-signed universal APK built successfully: **63,351,792 bytes**,
package `com.github.tiltozavr2545.framebook`, version `0.8.5+19`. Signature
verification passed with the established SHA-1 certificate
`f4077f14a136ff0170f1cbc64a1af420514c0afd`. The Dart application includes
ARM32, ARM64 and x86-64. Matching symbols are kept separately in the ignored
`app/build/symbols/0.8.5+19-polish-20261106/` directory, preserving the earlier
preview's symbols.

The phone was initially unavailable, then appeared during final verification.
The APK was installed over the existing app with `adb install -r`, without
clearing data. Launch and the retained Discover content were checked. At the
user's request, further phone testing is left to them; no favourite was
changed by this review. These are installation/launch checks, not measured
phone input latency or frame times. Phone profiling and the two-device sync
scenario remain manual checks as described in [testing.md](../../testing.md).
No emulator or destructive Drive workflow was exercised. Automated checks
used fakes/fixtures without external API calls. The user subsequently confirmed
improved responsiveness on the phone and authorized committing these repairs.
No push or release is part of this task.
