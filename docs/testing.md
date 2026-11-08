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

Run a benchmark from `app/`, for example:

```sh
flutter test test/benchmarks/sync_worker_benchmark.dart --reporter expanded
```

Run timing measurements alone on the same machine and workload. Benchmarks use
two warmups and five samples without a timing gate. Pure CPU times and main
isolate scheduler gaps do not measure Android frames, input latency or energy.
Fixture sizes and result assertions live in each benchmark's source; measured
results and their limits belong to the linked historical reports.

| Benchmark under `app/test/benchmarks/` | What it compares | Recorded evidence |
| --- | --- | --- |
| `merge_benchmark.dart` | Pure state merge and remote-behind checks | [0.8.4](reviews/0.8.4/README.md#measurements) |
| `watchlist_benchmark.dart` | Selective reads against full-state materialization | [0.8.4](reviews/0.8.4/README.md#measurements) |
| `recommendations_benchmark.dart` | Candidate/watchlist ranking, with an output digest | [2026-11-06](reviews/2026-11-06/README.md#measurements) |
| `sync_apply_benchmark.dart` | Unchanged application and SQL read count | [0.9.0](reviews/0.9.0/README.md#host-measurements) |
| `taste_profile_benchmark.dart` | Taste construction at several input sizes | [0.9.2](reviews/0.9.2/README.md#validation) |
| `ui_worker_benchmark.dart` | Worker transfer/preparation and scheduler gaps | [0.9.4](reviews/0.9.4/README.md#host-responsiveness-measurements) |
| `people_shelves_benchmark.dart` | Role filtering/sorting versus prepared shelves | [0.9.5](reviews/0.9.5/README.md#people-role-sorting-during-widget-builds) |
| `sync_worker_benchmark.dart` | Inline/worker merge, stale review and remote-behind | [0.9.5](reviews/0.9.5/README.md#large-sync-computations-on-the-ui-isolate) |

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
| Debounced comparison queries, serialized slow reads, obsolete scores and editor disposal | `features/rating_comparison_queue_test.dart`, `features/rating_note_test.dart` |
| Card external-rating cache failures, retained values and Retry | `features/title_ratings_failure_test.dart`, `features/title_ratings_test.dart` |
| Score edits preserving diary dates/order for all title kinds, re-rating after deletion and date-preserving sync | `data/library_test.dart`, `data/sync_test.dart` |
| Unknown dates in card headers in both locales, saved cards and removal of separate release notices | `app_test.dart` |
| Failed card/watchlist writes, Undo retry and release-date eligibility | `features/library_action_failure_test.dart` |
| Unknown personal-rating reads, Retry and retaining existing note drafts | `features/rating_load_guard_test.dart`, `features/rating_initial_state_test.dart` |
| Repeated rating-editor opening during pending local reads | `features/rating_opening_test.dart` |
| Pending/failed watchlist membership for movies, series and seasons, Retry and retained Rate access | `features/watchlist_initial_state_test.dart` |
| Repeated API-key submissions and bounded request spending | `features/api_key_actions_test.dart` |
| Retrying failed initial library reads on ratings, watchlist and statistics | `features/local_library_failure_test.dart` |
| People-page vertical position through empty/partial background refresh | `features/people_scroll_refresh_test.dart` |
| Renumbered seasons/episodes and conflicts | `data/renumbering_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Calibration thresholds, neighbours and score reel | `data/library_test.dart`, `features/calibration_visibility_test.dart`, `app_test.dart` |
| Sorting, source coverage, statistical aggregates | `data/comparison_test.dart`, `data/library_test.dart`, `app_test.dart` |
| Recommendation taste, retrieval rotation, ranking, hiding and lifecycle | `data/recommendations_test.dart`, `data/recommendation_resume_test.dart`, `data/recommendation_performance_test.dart`, `features/shelves_test.dart` |
| Pair selection, equality, corrections, stale answers and daily quotas | `data/pair_calibration_test.dart`, `data/pair_calibration_store_test.dart`, `features/pair_calibration_test.dart` |
| Pair-selection failure/retry and refreshed snapshots retaining an unsaved answer | `features/pair_calibration_test.dart` |
| People insights ignoring source/other-kind changes while retaining local title, poster, note and score edits | `data/insight_inputs_test.dart` |
| Theme/language persistence, Settings alignment, large text and list preferences | `features/preferences_test.dart`, `features/settings_layout_test.dart` |
| Failed/overlapping preference writes, retained later selections, Retry and source-filter preservation | `features/preference_failure_test.dart` |
| API-key layout on narrow phones with large text in both locales | `features/api_keys_layout_test.dart` |
| Offline cards, covers, delayed images and large text | `app_test.dart`, `features/cover_viewer_test.dart`, `features/cast_layout_test.dart` |
| Startup failure/retry and update checks | `features/startup_test.dart`, `features/update_check_test.dart`, `data/update*_test.dart` |
| Update-dismissal storage errors, repeated actions and a newer notice during saving | `features/update_dismiss_failure_test.dart` |
| Background-refresh queue, budgets, cancellation and lifecycle | `data/background_refresh_test.dart`, `features/background_lifecycle_test.dart` |
| Sync algebra, convergence, deletion records, malformed/oversized files | `data/sync_test.dart`, `data/sync_limits_test.dart` |
| Wrong TMDB detail identities and misplaced cached bodies | `data/tmdb_client_test.dart` |
| Interrupted key writes, unavailable sync metadata and background-refresh recovery | `data/api_keys_test.dart`, `data/sync_controller_test.dart`, `features/background_lifecycle_test.dart` |
| Import/export, comparison-only autosync, restore, account changes and concurrent edits | `data/sync_controller_test.dart`, `data/google_account_test.dart`, `app_test.dart` |
| Drive HTTP pagination, media upload/download, size limits and error mapping | `data/sync/drive_remote_test.dart` |
| Encrypted key merge, passwords, tampering, offline retry and account isolation | `data/sync/secrets_vault_test.dart`, `secrets_controller_test.dart` |
| Coordinated Drive deletion, repeated taps and failure recovery | `data/sync/sync_actions_test.dart` |
| Selective watchlist mutation reads, SQL part aggregates and retained selection history | `data/library_query_reads_test.dart` |
| Meaningful library emissions, stream errors/recovery and subscription cancellation | `data/library_stream_changes_test.dart`, `data/distinct_stream_test.dart` |
| Large sync-worker equivalence, bounded application reads and exact stale consent | `data/sync_compute_test.dart`, `data/sync_store_reads_test.dart` |
| Worker serialization, superseded inputs, disposal and error recovery | `data/latest_worker_test.dart`, `data/recommendation_performance_test.dart` |
| Statistics details, scroll stability, lazy people expansion, switcher gestures and glyphs | `features/stats_navigation_test.dart`, `features/stats_scroll_stability_test.dart`, `features/stats_layout_test.dart`, `features/stats_kind_switcher_test.dart`, `features/font_locale_test.dart` |
| Card facts, score colours and complete comparison shelves | `data/tmdb_client_test.dart`, `features/card_colors_test.dart`, `features/calibration_visibility_test.dart`, `app_test.dart` |
| Keyboard restoration, explicit dismissal and disposal during backgrounding | `features/keyboard_restore_test.dart`, `app_test.dart` |
| Paused-sync confirmation and consent fingerprint | `features/sync_screen_test.dart` |
| File-import UI cancellation, merge, replacement confirmation, unreadable/oversized files and storage failure | `features/sync_file_ui_test.dart` |
| Old-key responses after rebuilding a rating card and late failures after successful cache writes | `features/title_ratings_test.dart` |

Paths in the table are relative to `app/test/`. Rows describe the scenarios
present, not exhaustive coverage of every branch or platform interaction.

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
Native Samsung surface recreation requires the affected device; recorded
validation covers only the builds and scenarios named in the
[0.7.4 report](reviews/0.7.4/README.md).

Before a release, check onboarding and key persistence after a cold launch,
explicit Google sign-in versus quiet automatic sync, export/import through the
system picker, image gestures, background/resume and an update installed over
the existing signed app without clearing data. Two-phone offline edits and
subsequent sync in different orders are part of manual acceptance. Completion
status belongs to the [implementation plan](implementation-plan.md). Samsung
reproduction steps belong to
[Android troubleshooting](android-troubleshooting.md#samsung-android-14-resume);
historical device evidence is indexed in [reviews](reviews/README.md).
For keyboard restoration, focus search or a note, switch apps and return through
Recents. Repeat after explicitly dismissing the keyboard; it must stay hidden.
Inspect real-poster tints and related-title sections with large text and an
unreliable network; automated image tests use local stand-in artwork.
Never start an emulator on the Intel development Mac.

## Screenshot inspection

From `app/`, run `SCREENSHOTS=<directory> flutter test test/screenshots`.
These opt-in scenarios are skipped by default and produce PNGs for inspection;
they have no visual baseline assertions and are not functional regression tests.
