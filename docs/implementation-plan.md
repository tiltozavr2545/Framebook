# Implementation plan: Framebook (MVP)

A step-by-step plan for the MVP from [project-brief.md](project-brief.md). CI
and distribution are built into the stages rather than left for the end. The
platform is Android; iOS is postponed (see
[future-development.md](future-development.md)).

Every stage ends with a working APK you can install on your phone. The order
is chosen so that the riskiest questions (API availability, the key scheme)
are settled before anything is built on top of them.

## Progress

- [x] Stage 0 — Preparation, API checks, CI skeleton
- [x] Stage 1 — Local database, keys, settings
- [x] Stage 2 — Search and title card
- [x] Stage 3 — Ratings, notes, watchlist, calibration
- [x] Stage 4 — Comparison and statistics
- [x] Stage 5 — Google Drive: sync and backup
- [ ] Stage 6 — Polish and distribution
- [ ] Stage 7 — Code review, optimization, a second review

---

## Stage 0 — Preparation, API checks, CI skeleton

**Status:** done

1. ✅ **API availability check.** From the development machine all four APIs
   answer. The question "is TMDB reachable from Russia" is closed: the app's
   users don't go online from Russian IPs. TMDB stays the base of the
   catalog.
2. ✅ Every request from [external-sources.md](external-sources.md) was run
   with live keys (2026-10-23); the responses are fixtures in
   `app/test/fixtures/` (`scripts/capture-fixtures.sh`). What came out:
   - **a PoiskKino search by tmdb id is ambiguous**: a film and a series
     with the same TMDB number get mixed up, and `externalId.tmdb=603`
     returns a 1997 series first, not The Matrix. Matching was reworked: by
     `imdb_id` first, by tmdb id only with an `isSeries` filter;
   - seasons and episodes have no Kinopoisk rating — confirmed;
   - OMDb sends numbers as strings, errors differ only by text; series and
     episodes have no RT or Metacritic;
   - on TMDB `vote_average: 0` means "no votes".
3. ✅ `flutter create --org com.github.tiltozavr2545 --platforms=android,ios app`
   on Flutter 3.32.8. Package versions are chosen and pinned by the lock file
   — the table is in [client-architecture.md](client-architecture.md).
   Ceilings: drift 2.29 (2.31 doesn't go with `drift_dev` on Dart 3.8),
   Riverpod 3.3.2; google_sign_in resolved to 7.2.0, i.e. with the new
   authorization API.
   - Android: compileSdk/targetSdk 36, AGP 8.9.3, NDK 27, minSdk 26 — as in
     Amicus, for the same reasons. A release build without `key.properties`
     fails rather than being signed with the debug key (checked).
   - The release APK with all the plugins builds (`make build-apk-check`,
     46.6 MB — universal, with sqlite native libraries and the engine for
     every ABI).
4. ✅ Makefile (`verify`, `verify-version`, `bump-*`, `build-apk`,
   `build-apk-check`) and git hooks, modelled on Amicus
   (`make install-hooks` turns them on).
5. ✅ CI: `.github/workflows/ci.yml` — format, analyze, tests, an APK build
   signed with the debug key.
6. ✅ The release keystore is created and kept in GitHub secrets and in a
   copy outside the repository (the scheme is in
   [operations.md](operations.md)); a signed APK builds locally (`make
   build-apk`, the signature checked with `apksigner`) and in CI on a `v*`
   tag (`release-apk.yml` → GitHub Release).
   - ✅ APK 0.1.0 installed on the phone (2026-10-23): it starts, onboarding
     opens, theme and language follow the system.

## Stage 1 — Local database, keys, settings

**Status:** done (0.1.0)

1. ✅ drift: `works`, `ratings`, `watchlist`, `external_ratings`,
   `api_budget`, `sync_state`, `schemaVersion = 1`, a schema snapshot
   (`app/drift_schemas/`). The invariants are duplicated with CHECK
   constraints and foreign keys — the database itself enforces them, tests
   in `test/data/database_test.dart`.
2. ✅ `work_key.dart` — building and parsing, the parent and the chain of
   ancestors, tests for everything that must not parse.
3. ✅ Onboarding: entering and checking keys (TMDB is required), storing them
   in secure storage, the Settings → Sources screen. Key checks are covered
   by tests on recorded responses.
4. ✅ en/ru localization with a switch, theme (system/light/dark), a shell
   with four placeholder tabs.
5. ✅ `device_id` on first launch.

Along the way:
- The main Android manifest lacked the `INTERNET` permission (`flutter
  create` puts it only into debug/profile) — the release build would have
  had no network. Added.
- Excluding `*.g.dart` from analysis hid a compile error in the generated
  code; the exclusion is gone, and CI checks that the generated code matches
  the sources (`make codegen`).

## Stage 2 — Search and title card

**Status:** done (0.2.0)

1. ✅ A TMDB client behind an interface, an HTTP cache with TTLs.
2. ✅ Search (`search/multi`, films and series only), posters through an
   image cache.
3. ✅ Film and series cards; the season list; a season screen with its
   episodes; an episode card.
4. ✅ PoiskKino and OMDb clients, `ratings_service`: cache → budget →
   request, ids matched along the chain with no matching by title. Tests for
   matching and the budget run on the fixtures.
5. ✅ Rating cells on the card with every state (value / no data / no key /
   loading / error / stale).
6. ✅ TMDB attribution on the About screen.

Along the way:
- `dio_cache_interceptor` was replaced with our own cache: its `maxStale`
  slides forward on every hit, so a card opened often would never refresh
  (client-architecture.md, "HTTP").
- The budget split is done with ceilings on one shared counter
  (external-sources.md, "Request budget"); failures are throttled in memory
  so a new key retries at once.
- Widget tests run on a phone-sized screen; that caught the key buttons in
  Sources overflowing on a narrow screen.
- The snapshot refresh on card open (data-model.md) waits for Stage 3:
  nothing is in `works` until something is rated.

## Stage 3 — Ratings, notes, watchlist, calibration

**Status:** done (0.3.0)

1. ✅ Entering a 1–10 / 0.5 score and a note on a card of any kind; saving in
   one transaction together with the snapshot and its ancestors
   (`lib/data/library/`).
2. ✅ The average hint for a series and a season.
3. ✅ The calibration sheet: "The same", neighbours above and below, the same
   kind, editing the score from the sheet. Tests for choosing neighbours.
4. ✅ "My ratings": a filter by kind, sorting by date, score, year, title;
   works offline.
5. ✅ Watchlist: adding from a card, removal on rating.
6. ✅ Deleting a rating (tombstone) with a confirmation.

Along the way:
- The snapshot refresh on card open (deferred from Stage 2) is in: opening a
  card rewrites the snapshots that already exist, never creating new ones and
  never touching a rating's `updated_at`.
- The calibration sheet nudges the score with −/+ half-point buttons in its
  header rather than a row of every score: "a bit higher / lower" is what it
  is for, and it fits a phone.
- Seasons and episodes show your score next to them in the series' and the
  season's lists.
- Removing from the watchlist is instant with "Undo" instead of a
  confirmation dialog; deleting a rating does ask.
- Not done: a card opened offline that isn't in the HTTP cache still shows
  the error screen rather than its snapshot from `works` (step 1 of "Title
  card" in client-architecture.md) — moved to Stage 6, polish.
- Deleting orphan `works` rows (data-model.md) is a no-op for now: tombstoned
  rows keep referring to their snapshots, and tombstones are kept forever
  (sync.md). It comes together with tombstone cleanup.

## Stage 4 — Comparison and statistics

**Status:** done (0.4.0)

1. ✅ The "mine − theirs" difference next to every 1–10 rating on the card
   (Kinopoisk, IMDb, TMDB).
2. ✅ Sorting "My ratings" by divergence from Kinopoisk or IMDb: furthest
   apart, "I rate higher", "I rate lower"; rows without data at the end.
3. ✅ Background refresh of external ratings within the budget while the app
   is open (`lib/data/background_refresh.dart`); "ratings loaded for N of M"
   in the divergence sort and in the statistics.
4. ✅ Statistics: the distribution of your scores, the average deviation from
   Kinopoisk and IMDb (signed and absolute, with how many ratings it was
   computed over), the average by genre and decade, with a kind filter.
   Tests for the aggregates (`test/data/comparison_test.dart`).

Along the way:
- No difference next to Rotten Tomatoes and Metacritic: RT is a share of
  positive reviews and Metacritic a 0–100 score, so a difference with them
  would be a conversion, not a comparison (the brief: "a plain difference
  with no conversion").
- "Signed and absolute" became three orders: furthest apart (absolute), and
  signed in both directions — "I rate higher" and "I rate lower" — since
  signed descending alone would bury the other end under the "no data" rows.
- Background refresh asks about rated titles only, leaves TMDB alone (there
  is no card, so no TMDB vote to record), pauses only after titles that cost
  a request, and stops a pass when offline or when every source has spent
  its background share. It is off in widget tests: its passes run on timers.
- fl_chart is pinned at 1.0.0: 1.1 calls `Matrix4.translateByDouble` from
  vector_math 2.2, and Flutter 3.32 pins 2.1.4.
- 0.3.0 "would not install, the package is invalid" was a download broken
  by a network problem, not a broken release; downloading it again fixed it.
  The release workflow now verifies the APK's signature and certificate
  before publishing (operations.md, "Distribution").

## Stage 5 — Google Drive: sync and backup

**Status:** done (0.5.0); the check on two real phones is still owed.

1. ✅ Google Cloud: a project, the Drive API, the consent screen (published,
   with the home page and privacy policy on GitHub Pages), Android OAuth
   clients for the release and the Intel Mac's debug key, and a Web client
   whose id the app signs in with (see [operations.md](operations.md)).
2. ✅ The file format and merging — pure functions
   (`lib/data/sync/sync_file.dart`, `merge.dart`); property-based tests for
   the merge's algebra and for convergence of three devices under random
   edits and a random order of syncs (`test/data/sync_test.dart`).
3. ✅ The Drive transport (`drive_remote.dart`) behind an interface, and the
   pass itself (`sync_engine.dart`): finding/creating the file in
   `appDataFolder`, download, upload, a retry when `modifiedTime` changed,
   merging duplicates. Tested on an in-memory Drive.
4. ✅ Triggers: launch, returning to the app, 30 s after a change, a button
   (`sync_controller.dart`).
5. ✅ The first sign-in dialog with counters; sign-out; deleting the data
   from Drive (Settings → Sync and backup).
6. ✅ Daily copies (the last 7) and restoring from them.
7. ✅ Export and import to a file (merge / replace).
8. ⏳ A check on two phones: offline edits of the same film on both → syncs
   in different orders → the same result. Postponed until a second phone is
   at hand (no emulators on the development Mac); until then the convergence
   property tests stand in for it. Sign-in and the first upload to Drive
   were checked on a real phone with a release-signed build.

Along the way:
- google_sign_in 7 needs a Web client id on Android (Credential Manager
  signs in with it), so the "to be checked" in operations.md resolved to
  "required". The id is a constant in `google_account.dart`.
- Publishing the consent screen needs Branding: the home page and the
  privacy policy went to GitHub Pages (`docs/gh-pages/`, synced to the
  `gh-pages` branch by CI, as in Amicus).
- The convergence test caught drift writing a data class with
  `nullToAbsent`: an upsert left null columns out, so a winning version
  with no note, or a revived tombstone, kept the stale local value. Rows are
  written as full companions now — in sync and in the rating cache.

## Stage 6 — Polish and distribution

**Status:** not started

1. Empty states, errors without raw exception text, offline messages; a
   card opened offline shows its snapshot from `works` instead of an error.
2. Icon, name, splash screen.
3. ✅ Moving the OAuth app to Production — done in Stage 5: the consent
   screen is published, with Branding on GitHub Pages (see
   [operations.md](operations.md)).
4. A README with screenshots, installing at friends'. (The first GitHub
   release already happened at 0.1.0.)
5. The app's version on the About screen.
6. A new Search tab: a search field on top and, under it, a selection of
   films and series to browse instead of an empty screen. Which selection
   (TMDB has trending, popular, top rated, now playing / upcoming, on the
   air, by genre…) is to be decided when the stage starts: the options go to
   the user first.
7. A new score picker: a horizontal carousel of scores to swipe through
   instead of the row of chips — the closest example is Kinopoisk's picker,
   but horizontal. The calibration is built into it: while the carousel
   moves, it shows what else of this kind you rated at the score under the
   cursor and the nearest scores around it, so the comparison helps choose
   rather than coming as a separate sheet after the choice is made.
8. Cast and crew on the title card: actors and directors (and creators for
   a series), if TMDB gives them — `credits` for a film, `aggregate_credits`
   for a series, an episode's own credits and guest stars.

## Stage 7 — Code review, optimization, a second review

**Status:** not started

1. A full code review of the app: correctness first, then everything else
   it finds. Every bug found is fixed, with a test where it can have one.
2. Optimization once the bugs are fixed: less memory, CPU and battery, less
   network and disk, faster start and smoother scrolling — measured before
   and after rather than guessed.
3. After the optimization, a second full review that doesn't lean on the
   first one's results: a fresh look at the code as it is then, so that the
   first review's blind spots and anything the optimization broke get
   caught.
