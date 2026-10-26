# AGENTS.md

Context for an AI agent working in this repository, shared by every tool
(Codex, Claude Code and so on).

This file holds only what isn't in the code: environment constraints, working
conventions, invariants and pitfalls. Everything else lives where it should be
read:

| what | where |
|---|---|
| what the project is, what it does, the stack | [README.md](README.md) |
| version history | [CHANGELOG.md](CHANGELOG.md) |
| local schema, keys, invariants | [docs/data-model.md](docs/data-model.md) |
| which external APIs, id matching, cache, limits | [docs/external-sources.md](docs/external-sources.md) |
| the Google Drive file format, merging, export/import | [docs/sync.md](docs/sync.md) |
| how the client is built, default decisions | [docs/client-architecture.md](docs/client-architecture.md) |
| getting the API keys (step by step, for users) | [docs/api-keys.md](docs/api-keys.md), Russian translation [docs/api-keys.ru.md](docs/api-keys.ru.md) |
| the Google OAuth client, where the signing key is, how to release | [docs/operations.md](docs/operations.md) |
| the published home page and privacy policy (GitHub Pages) | [docs/gh-pages/](docs/gh-pages/) — edited here, not on the `gh-pages` branch: CI overwrites it on every push to `main` |
| MVP stages and progress | [docs/implementation-plan.md](docs/implementation-plan.md) |
| postponed work, open questions | [docs/future-development.md](docs/future-development.md) |
| historical: the idea and decisions before the start | [docs/project-brief.md](docs/project-brief.md) |

## Project

An app for myself and a couple of friends: search for films and series, rate
them, compare with Kinopoisk, IMDb and others. The author is the same as
Amicus's (`~/projects/lk-system`): Flutter/Riverpod/go_router experience is
there, but this project has no server, and all the complexity moves into the
client — a local database, external APIs with limits, sync through someone
else's storage. Work stage by stage following
[docs/implementation-plan.md](docs/implementation-plan.md), without running
ahead.

## Environment constraints

- **Two developers, two machines** — the same as Amicus's. Android is built on
  an old Intel MacBook Pro with macOS 12.7.6. Flutter newer than 3.32.8 doesn't
  run there (it needs macOS 14+), so the SDK is pinned to **3.32.8**. Don't
  suggest upgrading — the machine physically can't take a newer macOS, it is
  a dead end. The consequence for dependencies: a package version is chosen
  for the Dart of Flutter 3.32.8, not "the latest" — some packages' fresh
  majors need a newer SDK. The M4 MacBook Pro has no such limit, but uses the
  same SDK so that the lock file doesn't diverge.
- **iOS is postponed.** The MVP targets Android only. Don't delete the iOS
  platform code (`flutter create` makes it), but don't maintain it either.
- **There is no server, and there won't be in the MVP.** Don't suggest a
  "small backend" to proxy keys, cache or sync — it is a deliberate decision,
  see [docs/project-brief.md](docs/project-brief.md).

## Invariants

Rules the other decisions rest on. Breaking any of them is not a matter of
style, it is breakage.

- **The catalog is not stored.** Locally there is only a title's mini
  snapshot (title, year, poster, genres, external ids) — exactly enough for
  the list of ratings to open and sort without a network. Overviews, cast,
  full season lists never reach the database; the on-disk cache of HTTP
  responses is evictable and isn't carried by sync. The boundary is in
  [docs/data-model.md](docs/data-model.md).
- **API keys never reach the repository, the build or Google Drive.** Users
  enter them and they live in `flutter_secure_storage`. In logs and error
  reports a key is masked.
- **A score is stored as an integer number of half points** (`score_half`
  2…20 = 1.0…10.0). No `double` in the database or the sync file — the "same
  score" comparison in the calibration sheet must be exact.
- **A row's key is natural, not random.** A `work_key` like `tmdb:movie:603`
  or `tmdb:tv:1399:s1:e3` is derived from the source's ids. Two offline
  ratings of the same film on two devices are one row with a conflict, not
  two duplicate rows.
- **Synced rows are never physically deleted.** Deletion is `deleted_at` (a
  tombstone). Without it, merging resurrects what was deleted on another
  device.
- **`updated_at` changes on any user change of the row, and only on that.**
  A background refresh of the snapshot or the rating cache doesn't touch a
  rating's `updated_at` — otherwise it would win the merge over a real edit
  from another device.
- **The sync file format is versioned** (`format_version`) and read
  backwards-compatibly. A device with an older app version that sees a file
  of a newer version doesn't sync and asks to update — it doesn't overwrite
  the file with its own reduced view.

## Working conventions

- **Write all repo-facing text in English**: commit messages, docs,
  code comments/docstrings, and GitHub release bodies. Exception:
  anything genuinely user-facing that the app itself produces, and
  the `app/lib/l10n/app_ru.arb` localization file — those stay as-is.
  `docs/api-keys.ru.md` is user-facing too (the app opens it for a Russian
  UI): it stays a Russian translation of `docs/api-keys.md`, kept in step.
- **Local schema changes go only through drift migrations**, with a higher
  `schemaVersion`, a step in `migration` and a migration test on the previous
  schema's snapshot. `make codegen` rebuilds the drift code and the
  localization and (through `drift_dev make-migrations`) writes the new
  version's snapshot to `app/drift_schemas/` along with a test stub. No
  hand-written `ALTER`.
- **Generated code is committed** (`*.g.dart`, `lib/l10n/app_localizations*.dart`)
  and CI checks it against the sources. Changed a table or an ARB — run
  `make codegen` and commit the result.
- **The version is bumped in every PR**: `name+build` in `app/pubspec.yaml`,
  `build` is monotonic (it is Android's `versionCode`). Make targets as in
  Amicus: `make verify`, `make verify-version`, `make bump-*`.
- **Before handing over**: `make verify` (deps, format, analyze, tests) for
  `app/`.
- **Tests for pure logic are mandatory**: sync merging, building `work_key`,
  matching ids between sources, choosing neighbours for the calibration
  sheet, statistics aggregates. These are things you can't check by eye.
- **External APIs are never called in tests.** Source clients sit behind
  interfaces; tests use fakes with recorded responses (`test/fixtures/`).
- **Localization**: strings are in `app/lib/l10n/app_{en,ru}.arb`, generated
  with `flutter gen-l10n`, and the generated files are committed. Edit ARB
  files **as text**: rewriting them through `json.dump` eats the blank lines
  that split the file into groups.
- **Record decisions in `docs/`**, not only in code: the "why" lives in the
  documents here (there are no commented migrations as in Amicus). When a
  decision changes, the document is edited, not given a second one next to
  it.
- **`CLAUDE.md` is a thin wrapper around this file** and holds only what is
  specific to Claude Code (nothing so far). Shared conventions and pitfalls
  live only here; don't duplicate them.

## Pitfalls

Carried over from Amicus, where they cost real bugs; the stack is the same:

- **`ref` after `await` throws if the widget was unmounted** — in release
  too. Capture the container BEFORE the `await`
  (`ProviderScope.containerOf(context, listen: false)`), otherwise updating
  the neighbouring screens silently doesn't happen.
- **Time is UTC at the storage boundary.** The database and the sync file
  hold UTC (epoch milliseconds); it becomes local time only for display.
  Release dates from APIs (`release_date`, `first_air_date`) are dates without
  a time; never turn them into a `DateTime` with a time zone.
- **Check the back gesture only on `Navigator.push()` screens** — on screens
  reached with `context.go()` the stack is empty, and minimizing the app is
  legitimate.

Our own:

- **`*.g.dart` must not be excluded from analysis.** They are part files of
  libraries: the exclusion hid not style issues but a compile error. A
  "unused" import of `work_key.dart` was removed from `database.dart`, the
  generated code referred to it, and `flutter analyze` answered "No issues
  found" — only the tests failed.
- **`flutter create` doesn't put `INTERNET` into the main
  `AndroidManifest.xml`** — only into debug/profile. The debug build reaches
  the network, the release build doesn't. The permission is added; don't
  remove it as "redundant".
- **A tmdb id without its type is not an identifier.** TMDB numbers films
  and series separately, while PoiskKino stores the tmdb id without a type:
  `externalId.tmdb=603` returns a 1997 series first, not The Matrix (fixture
  `poiskkino/movie_by_tmdb_603.json`). Match by `imdb_id`, and by tmdb id only
  together with the type (`isSeries`). The same goes for any place where a
  tmdb id lives apart from `movie`/`tv`: that is why the type is part of
  `work_key`.
- **A package's "latest version" is usually incompatible with the pinned
  SDK.** `flutter pub add drift_dev` next to drift 2.31 doesn't resolve: fresh
  drift pulls `test`/`sqlite3` needing Dart 3.10+, while `test` is pinned
  through `flutter_test` from the SDK. The cure is lifting the constraint
  (`any`) — the solver finds the ceiling itself (drift 2.29). The chosen
  versions and ceilings are in
  [docs/client-architecture.md](docs/client-architecture.md).
- **The network on the development machine is slow (about 130 KB/s to
  pub.dev), and `flutter pub get` once hung there for 22 hours without a
  single error** — an archive download stalled mid-stream. The sign: the `-v`
  log doesn't grow for minutes on a `Creating … .tar.gz from stream` line.
  Kill it and restart; what is already in `~/.pub-cache` isn't downloaded
  again.
- **`future.whenComplete(() => map.remove(key))` deadlocks when the map holds
  that same future.** `remove` returns the removed value, `whenComplete`
  waits for whatever its callback returns, and the future ends up waiting for
  itself — no error, just a hang. Use a block body. Bit the in-flight dedupe
  in `ratings_service.dart`.
- **Don't let dio parse JSON for external APIs.** An unparsable body (a
  proxy's HTML on a 502) becomes `DioExceptionType.unknown`, which
  `isNetworkFailure` reads as offline. Clients request `ResponseType.plain`
  and parse with `tryJson`, so a bad body is a source error.
- **Widget tests with a drift `watch()` stream on screen fail with "Pending
  timers"**: closing the stream schedules a Timer during unmount, and the
  check runs before `addTearDown`. Unmount inside the test body and pump
  once with a non-zero duration (`cardTest` in `test/app_test.dart`).
- **The default widget test screen is 800×600, not a phone.** Layouts get
  tested at a width nobody uses, and `find` skips what is scrolled out of
  view. `pumpApp` sets 360×780 dp.
