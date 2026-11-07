# Testing

Run `make verify` before handing over a code change, unless the current task
explicitly limits verification. It checks locked dependencies, formatting,
static analysis and the complete automated test suite on the
[pinned SDK](development.md#sdk-and-dependencies). No API keys, Google account
or connected phone are required. Tests use recorded API responses, fake HTTP
clients, in-memory SQLite and a fake Drive; they must never contact external
services.

For documentation-only changes, check links, anchors, topic ownership and
consistency with the existing checkout.

`make verify` also runs `make test-scripts`: isolated shell fixtures exercise
the version bump and PR gate, including malformed versions, numeric overflow,
monotonic builds and exact comparisons of large version components. The
fixture never changes the checkout's version or creates a Git commit.

## Host benchmarks

An optional host microbenchmark is available with
`cd app && flutter test test/benchmarks/merge_benchmark.dart`. It measures a
merge plus the remote-behind check for 6,000 snapshots, 3,000 ratings with
512-character notes and 3,000 watchlist entries. It warms up twice and prints
the median of five samples; no timing threshold gates CI. Compare runs on the
same machine and workload. It does not measure Android frame time or battery.

`test/benchmarks/watchlist_benchmark.dart` measures the existing watchlist
stream alongside 3,000 ratings with 1,024-character notes and 50 watchlisted
films. It compares the production selective reader with the former full-state
approach. This fixture measures movie-only reads; separate regressions cover
season grouping and selection fences.

`test/benchmarks/recommendations_benchmark.dart` ranks 1,000 candidates and
1,000 watchlist entries against 500 taste signals. It prints five measured
samples after two warmups and a digest of all output rows for before/after
comparison. `data/recommendation_performance_test.dart` exercises real isolate
transfer, latest-result publication and immediate exclusions;
`data/latest_worker_test.dart` checks serialization, superseded inputs,
disposal and failure recovery. `features/stats_layout_test.dart` checks lazy
expansion across 1,000 people and drill-down before insights finish.

`test/benchmarks/sync_apply_benchmark.dart` measures unchanged sync application
with 3,000 snapshots, 1,500 ratings and 1,500 watchlist entries and counts SQL
reads through the real executor. `data/sync_store_reads_test.dart` gates bounded
reads for both initial and unchanged application, row preservation and newer
unreferenced metadata. See [the 0.9.0 review](reviews/0.9.0/README.md) for measurements.

## Coverage reports

Run `make test-coverage` to write `app/coverage/lcov.info`, or
`make verify TEST_ARGS=--coverage` to collect it during the full verification. The report is local
and ignored by Git. Coverage measures executed Dart lines, not requirements or
correctness: an executed branch can still have a weak assertion. Generated
Drift/localization files should be excluded when interpreting application
coverage. Files absent from LCOV, including native Android code, are not covered
by that percentage.

## Capturing API fixtures

`scripts/capture-fixtures.sh` records live responses of all three APIs into
`app/test/fixtures/`. It takes the keys from a file outside the repository,
`~/.config/framebook/keys.env` (or the path in `FRAMEBOOK_KEYS`):

```sh
mkdir -p ~/.config/framebook
umask 077
nano ~/.config/framebook/keys.env
```

File contents:

```sh
TMDB_TOKEN=eyJ...
POISKKINO_KEY=...
OMDB_KEY=...
```

A source without a key is skipped. The script spends 8 of the 200 daily
PoiskKino requests. At the end it checks that no key value ended up in the
saved files. Rerun it when the response format changes or a new request is
added. If a fixture-capture key is rotated, update this private file as well
as any app installation using that key.

## Automated coverage by behavior

| Behavior | Main tests |
| --- | --- |
| Onboarding, key checking/removal, navigation | `app_test.dart`, `data/api_keys_test.dart`, `data/key_validator_test.dart` |
| Search, people, pagination, stale responses, selected-title history | `features/search_controller_test.dart`, `features/search_history_test.dart`, `app_test.dart` |
| API parsing, typed identity matching, caching and quotas | `data/*_client_test.dart`, `data/ratings_service_test.dart`, `data/response_cache_test.dart` |
| Rating, notes, cancellation, deletion, watchlist, season grouping | `data/library_test.dart`, `features/rating_note_test.dart`, `app_test.dart` |
| Renumbered seasons/episodes and conflicts | `data/renumbering_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Calibration thresholds, neighbours and score reel | `data/library_test.dart`, `features/calibration_visibility_test.dart`, `app_test.dart` |
| Sorting, source coverage, statistical aggregates | `data/comparison_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Recommendation taste, retrieval rotation, ranking, hiding and lifecycle | `data/recommendations_test.dart`, `data/recommendation_resume_test.dart`, `data/recommendation_performance_test.dart`, `features/shelves_test.dart` |
| Pair selection, equality, corrections, stale answers and daily quotas | `data/pair_calibration_test.dart`, `data/pair_calibration_store_test.dart`, `features/pair_calibration_test.dart` |
| Theme/language persistence, Settings alignment, large text and list preferences | `features/preferences_test.dart`, `features/settings_layout_test.dart` |
| API-key layout on narrow phones with large text in both locales | `features/api_keys_layout_test.dart` |
| Offline cards, covers, delayed images and large text | `app_test.dart`, `features/cover_viewer_test.dart`, `features/cast_layout_test.dart` |
| Startup failure/retry and update checks | `features/startup_test.dart`, `features/update_check_test.dart`, `data/update*_test.dart` |
| Background-refresh queue, budgets, cancellation and lifecycle | `data/background_refresh_test.dart`, `features/background_lifecycle_test.dart` |
| Sync algebra, convergence, deletion records, malformed/oversized files | `data/sync_test.dart`, `data/sync_limits_test.dart` |
| Import/export, comparison-only autosync, restore, account changes and concurrent edits | `data/sync_controller_test.dart`, `data/google_account_test.dart`, `app_test.dart` |
| Drive HTTP pagination, media upload/download, size limits and error mapping | `data/sync/drive_remote_test.dart` |
| Encrypted key merge, passwords, tampering, offline retry and account isolation | `data/sync/secrets_vault_test.dart`, `secrets_controller_test.dart` |
| Coordinated Drive deletion, repeated taps and failure recovery | `data/sync/sync_actions_test.dart` |
| Paused-sync confirmation and consent fingerprint | `features/sync_screen_test.dart` |
| File-import UI cancellation, merge, replacement confirmation, unreadable/oversized files and storage failure | `features/sync_file_ui_test.dart` |
| Old-key responses after rebuilding a rating card and late failures after successful cache writes | `features/title_ratings_test.dart` |

Paths in the table are relative to `app/test/`. Rows describe the scenarios
present, not exhaustive coverage of every branch or platform interaction.

Pair regressions cover deterministic score/genre neighbourhoods, conflicting
and non-strict equality chains, all legal score-boundary corrections, duplicate
submission, quota races, stale ratings and preserving concurrent note edits.
They also cover v2-to-v3 data preservation, v6 comparison codecs and merge laws,
legacy files, history retention during replacement, shared quotas through a fake
Drive, hidden scores, skips, equality confirmation and next-day resume. These
checks do not replace the two-physical-phone sync scenario.

## Regression-test conventions

- Changes to pure logic require tests: sync merging/convergence, natural-key
  construction, source-ID matching, calibration selection and statistical
  aggregates cannot be verified by looking at the UI.
- Assert observable behavior and persisted results. For a collection, check
  membership/count as well as element properties: `everyElement` also passes
  for an empty list. Check the complete ordering when absent-source rows matter.
- Exercise cancellation, failure and retry alongside successful operations.
  Use completers to control concurrent operations, rather than real network
  delays. Advance widget-test time for timers.
- UI scenarios use phone dimensions: the shared `pumpApp` uses 360 × 780 dp,
  rather than Flutter's default 800 × 600 test surface. Check deliberate
  wrapping/ellipsis at increased text scales where layout can break.
- Dispose widget trees and provider containers inside the test body, including
  failure paths. A Drift `watch()` stream may schedule a timer during
  unmount, before `addTearDown` runs: unmount inside the test body and pump
  once with a nonzero duration, as in `cardTest`.
- Keep fixtures synthetic or recorded without credentials. Do not replace
  property/convergence tests with a handful of happy-path examples.

## Checks that still need a device

Dart tests cannot establish that Google Credential Manager, secure storage,
Android's file picker/share UI, external links or a signed APK work on a real
phone. Sync-screen coverage is selective: controller-level import/restore tests
are not a substitute for completing those flows through Android's file picker.
Native Samsung surface recreation requires the affected device; its recorded
validation does not cover all lifecycle paths.

Before a release, check onboarding and key persistence after a cold launch,
explicit Google sign-in versus quiet automatic sync, export/import through the
system picker, image gestures, background/resume and an update installed over
the existing signed app without clearing data. Two-phone offline edits and
subsequent sync in different orders remain an outstanding manual check. The
checklist here defines the procedure; completion status is in the
[implementation plan](implementation-plan.md). Samsung reproduction steps and
existing device evidence belong to
[Android troubleshooting](android-troubleshooting.md#samsung-android-14-resume).
Never start an emulator on the Intel development Mac.

## Screenshot inspection

From `app/`, run `SCREENSHOTS=<directory> flutter test test/screenshots`.
These opt-in scenarios are skipped by default and produce PNGs for inspection;
they have no visual baseline assertions and are not functional regression tests.

## Title-card and keyboard regressions

`data/tmdb_client_test.dart` covers unknown finances, earliest valid release
dates without time-zone shifts, production-country parsing, collection order,
typed similar results and their cache. `features/card_colors_test.dart` checks
score-band boundaries (4 and 6.5 inclusive), normal-surface text contrast in
both themes and characteristic poster-colour sampling despite dark borders.
`features/calibration_visibility_test.dart` exercises all three independent
horizontal shelves, including titles beyond the former 4/2-item limits, at
normal and increased font scales. The library tests assert full group membership
and stable ordering. `app_test.dart` checks displayed movie facts, current-title and
duplicate exclusion, and opening collection/similar cards with Back navigation.

Keyboard scenarios in `app_test.dart` and `features/keyboard_restore_test.dart`
cover an open versus dismissed keyboard across a full lifecycle round trip,
multiline editors and removing the editor while backgrounded. Before release,
repeat on a physical phone: focus search or a note, switch apps, return through
Recents, then repeat after explicitly dismissing the keyboard. The dismissed
keyboard must stay hidden. Also inspect real-poster tints and collection/similar
sections with a large system font and unreliable network; automated image
renders use local placeholder artwork rather than live poster downloads.
