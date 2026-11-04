# Testing Framebook

Run `make verify` before handing over a change. It checks locked dependencies,
formatting, static analysis and the complete automated test suite on the pinned
Flutter 3.32.8 SDK. No API keys, Google account or connected phone are required.
Tests use recorded API responses, fake HTTP clients, in-memory SQLite and a fake
Drive; they must never contact the external services.

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

`test/screenshots/screens_test.dart` contains 18 opt-in render scenarios. They
are skipped without `SCREENSHOTS=<directory>` and produce PNGs for inspection;
they have no visual baseline assertions and are not functional regression tests.
