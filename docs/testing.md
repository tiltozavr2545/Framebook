# Testing Framebook

Run `make verify` before handing over a change. It checks locked dependencies,
formatting, static analysis and the complete automated test suite on the pinned
Flutter 3.32.8 SDK. No API keys, Google account or connected phone are required.
Tests use recorded API responses, fake HTTP clients, in-memory SQLite and a fake
Drive; they must never contact the external services.

`make verify` also runs `make test-scripts`: isolated shell fixtures exercise
the version bump and PR gate, including malformed versions, numeric overflow,
monotonic builds and exact comparisons of large version components. The
fixture never changes the checkout's version or creates a Git commit.

An optional host microbenchmark is available with
`cd app && flutter test test/benchmarks/merge_benchmark.dart`. It measures a
merge plus the remote-behind check for 6,000 snapshots, 3,000 ratings with
512-character notes and 3,000 watchlist entries. It warms up twice and prints
the median of five samples; no timing threshold gates CI. Compare runs on the
same machine and workload. It does not measure Android frame time or battery.

`test/benchmarks/watchlist_benchmark.dart` measures the existing watchlist
stream alongside 3,000 ratings with 1,024-character notes and 50 watchlisted
films. Its joined-query comparison is valid for that movie-only fixture;
it is an optimization candidate, not a replacement for season/fence logic.

`test/benchmarks/recommendations_benchmark.dart` ranks 1,000 candidates and
1,000 watchlist entries against 500 taste signals. It prints five measured
samples after two warmups and a digest of all output rows for before/after
comparison. `data/recommendation_performance_test.dart` exercises real isolate
transfer, latest-result publication and immediate exclusions;
`data/latest_worker_test.dart` checks serialization, superseded inputs,
disposal and failure recovery. `features/stats_layout_test.dart` checks lazy
expansion across 1,000 people and drill-down before insights finish.

Run `make test-coverage` to write `app/coverage/lcov.info`, or
`make verify TEST_ARGS=--coverage` to collect it during the full verification. The report is local
and ignored by Git. Coverage measures executed Dart lines, not requirements or
correctness: an executed branch can still have a weak assertion. Generated
Drift/localization files should be excluded when interpreting application
coverage. Files absent from LCOV, including native Android code, are not covered
by that percentage.

## Automated coverage by behavior

| Behavior | Main tests |
|---|---|
| Onboarding, key checking/removal, navigation | `app_test.dart`, `data/api_keys_test.dart`, `data/key_validator_test.dart` |
| Search, people, pagination, stale responses, selected-title history | `features/search_controller_test.dart`, `features/search_history_test.dart`, `app_test.dart` |
| API parsing, typed identity matching, caching and quotas | `data/*_client_test.dart`, `data/ratings_service_test.dart`, `data/response_cache_test.dart` |
| Rating, notes, cancellation, deletion, watchlist, season grouping | `data/library_test.dart`, `features/rating_note_test.dart`, `app_test.dart` |
| Renumbered seasons/episodes and conflicts | `data/renumbering_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Calibration thresholds, neighbours and score reel | `data/library_test.dart`, `features/calibration_visibility_test.dart`, `app_test.dart` |
| Sorting, source coverage, statistical aggregates | `data/comparison_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Theme/language persistence, system-language changes, list preferences | `features/preferences_test.dart` |
| Offline cards, covers, delayed images and large text | `app_test.dart`, `features/cover_viewer_test.dart`, `features/cast_layout_test.dart` |
| Startup failure/retry and update checks | `features/startup_test.dart`, `features/update_check_test.dart`, `data/update*_test.dart` |
| Background-refresh queue, budgets, cancellation and lifecycle | `data/background_refresh_test.dart`, `features/background_lifecycle_test.dart` |
| Sync algebra, convergence, deletion records, malformed/oversized files | `data/sync_test.dart`, `data/sync_limits_test.dart` |
| Import/export, restore, account changes and concurrent edits | `data/sync_controller_test.dart`, `data/google_account_test.dart`, `app_test.dart` |
| Drive HTTP pagination, media upload/download, size limits and error mapping | `data/sync/drive_remote_test.dart` |
| Encrypted key merge, passwords, tampering, offline retry and account isolation | `data/sync/secrets_vault_test.dart`, `secrets_controller_test.dart` |
| Coordinated Drive deletion, repeated taps and failure recovery | `data/sync/sync_actions_test.dart` |
| Paused-sync confirmation and consent fingerprint | `features/sync_screen_test.dart` |
| File-import UI cancellation, merge, replacement confirmation, unreadable/oversized files and storage failure | `features/sync_file_ui_test.dart` |
| Old-key responses after rebuilding a rating card and late failures after successful cache writes | `features/title_ratings_test.dart` |

Paths in the table are relative to `app/test/`. Rows describe the scenarios
present, not exhaustive coverage of every branch or platform interaction.

## Regression-test conventions

- Assert observable behavior and persisted results. For a collection, check
  membership/count as well as element properties: `everyElement` also passes
  for an empty list. Check the complete ordering when absent-source rows matter.
- Exercise cancellation, failure and retry alongside successful operations.
  Use completers to control concurrent operations, rather than real network
  delays. Advance widget-test time for timers.
- UI scenarios use phone dimensions. Check deliberate wrapping/ellipsis at
  increased text scales where layout can break.
- Dispose widget trees and provider containers inside the test body, including
  failure paths. Pump afterward when disposal schedules Drift/Riverpod timers.
- Keep fixtures synthetic or recorded without credentials. Do not replace
  property/convergence tests with a handful of happy-path examples.

## Checks that still need a device

Dart tests cannot establish that Google Credential Manager, secure storage,
Android's file picker/share UI, external links or a signed APK work on a real
phone. Sync-screen coverage is selective: controller-level import/restore tests
are not a substitute for completing those flows through Android's file picker.
Native Samsung surface recreation also needs device verification.

Before a release, check onboarding and key persistence after a cold launch,
explicit Google sign-in versus quiet automatic sync, export/import through the
system picker, image gestures, background/resume and an update installed over
the existing signed app without clearing data. Two-phone offline edits and
subsequent sync in different orders remain an outstanding manual check; see
[implementation-plan.md](implementation-plan.md). Never start an emulator on the
Intel development Mac.

`test/screenshots/screens_test.dart` contains 20 opt-in render scenarios. They
are skipped without `SCREENSHOTS=<directory>` and produce PNGs for inspection;
they have no visual baseline assertions and are not functional regression tests.

## Rich title cards

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
