# Client design

What the app is built with and what lives where. There is no server, so this
is the whole project's architecture, not "what the client does on top of the
schema" as in Amicus. The data schema is in [data-model.md](data-model.md),
the external APIs in [external-sources.md](external-sources.md), sync in
[sync.md](sync.md).

**Status: Stage 2.** Search, title cards and external ratings sit on top of
the Stage 1 skeleton (database, keys, settings, navigation). The list below
is the default decisions; if something is replaced along the way (drift by
something else, say), it is recorded right here, so that the document doesn't
silently drift away from the code.

---

## Default technical decisions

- **Flutter:** 3.32.8, pinned (a machine constraint — see [../AGENTS.md](../AGENTS.md));
  package versions are chosen for its Dart
- **State management:** Riverpod
- **Navigation:** go_router, bottom navigation through `StatefulShellRoute`
  (tabs: Search, My ratings, Watchlist, Stats; settings from the app bar)
- **Local database:** drift (SQLite) — typed queries, reactive `watch()`
  streams for Riverpod, migrations tested on schema snapshots
- **HTTP:** dio plus our own on-disk cache of TMDB responses
  (`lib/data/response_cache.dart`), with a TTL per request type from
  [external-sources.md](external-sources.md). Not `dio_cache_interceptor`:
  it extends `maxStale` on every hit, so a card opened often would never
  refresh. Our cache is one file per request in the OS cache directory; a
  fresh entry is served without the network, a stale one when there is no
  network or TMDB answered with an error. The API key never becomes part of
  a cache key. PoiskKino and OMDb responses don't go to the HTTP cache: their
  result is `external_ratings` rows
- **Images:** cached_network_image with its own `CacheManager` (1,500
  files, 90 days); the cache key is size plus `poster_path`, not the full URL
  (a lesson from Amicus: a cache key must not depend on what gets reissued).
  The CDN base address comes from `/configuration`, and until that loads,
  from the well-known default
- **Secrets:** flutter_secure_storage (API keys), behind the `KeyStorage`
  interface — replaced with memory in tests
- **External links:** url_launcher (the key guide opens in the browser, in
  the UI's language)
- **Settings:** shared_preferences
- **Google:** google_sign_in + googleapis (Drive v3) +
  extension_google_sign_in_as_googleapis_auth. google_sign_in resolved to
  7.2.0 — already the new API (authorization separate from sign-in, through
  `authorizationClient`); examples for 6.x don't apply to it
- **Serialization:** external API responses are parsed by hand into domain
  classes (`lib/data/sources/*`) through `Json`, a wrapper that reads a field
  of the wrong type as missing. json_serializable would get in the way here:
  a film and a series name the same field differently (`title`/`name`),
  dates can be an empty string, and a zero rating means "no votes". Clients
  take the body as a string and parse it themselves: in dio an unparsable
  body is `DioExceptionType.unknown`, which reads as "no network".
  json_serializable is still the default for the sync file format (Stage 5)
- **Statistics charts:** fl_chart
- **Linting/formatting:** flutter_lints + `dart format`, in CI from the first
  commit
- **Repository layout:** `app/` — the Flutter project (org
  `com.github.tiltozavr2545`, package `framebook`), `docs/` — documentation
- **Repository:** [github.com/tiltozavr2545/Framebook](https://github.com/tiltozavr2545/Framebook)

### Versions chosen for Flutter 3.32.8 (Stage 0)

| Package | Version | Note |
|---|---|---|
| flutter_riverpod | 3.3.2 | 3.4.1+ needs Dart 3.12 |
| go_router | 17.0.0 | |
| drift / drift_flutter / drift_dev | 2.29.0 / 0.2.7 / 2.29.0 | **ceiling**: drift 2.31 pulls sqlite3 and test, which need Dart 3.10+, while `test` is pinned through `flutter_test` from the SDK |
| build_runner / json_serializable | 2.7.1 / 6.11.2 | analyzer 7.7.1 |
| dio | 5.11.1 | `dio_cache_interceptor` dropped in Stage 2 — see "HTTP" above |
| crypto | 3.0.7 | HTTP cache file names are the sha1 of the key |
| cached_network_image / flutter_cache_manager | 3.4.1 / 3.4.5 | own `CacheManager` for posters |
| flutter_secure_storage | 10.3.4 | |
| shared_preferences | 2.5.3 | |
| google_sign_in | 7.2.0 | the new authorization API |
| googleapis / extension_google_sign_in_as_googleapis_auth | 15.0.0 / 3.0.0 | |
| fl_chart | 1.1.0 | |
| uuid / intl | 4.6.0 / 0.20.2 | |

`flutter pub upgrade --major-versions` is not a tool here: "newer" almost
always means "needs a fresher SDK", and the SDK is pinned. To upgrade one
package, lift its constraint (`any`) and see what the solver picks, as was
done for drift.

---

## Layers

```
lib/
  app/                  — entry point, router, theme, localization
  data/
    db/                 — drift: tables, queries, migrations
    sources/
      tmdb/             — catalog client and domain classes
      poiskkino/        — PoiskKino client (Kinopoisk rating)
      omdb/             — OMDb client (IMDb, RT, Metacritic)
      providers.dart    — clients built from keys and language
    ratings_service.dart — external ratings: cache → budget → source
    budget.dart         — daily limits and ceilings (api_budget)
    response_cache.dart — on-disk HTTP cache for TMDB
    source_failure.dart — why a source failed; JSON reading
    work_key.dart       — building and parsing work_key
  sync/                 — file format, merging (pure functions), Drive transport
  features/
    search/  title/  ratings/  watchlist/  stats/  settings/  onboarding/
  shared/               — poster, error screen, formatting
```

Rules:

- **A source client knows only its own API** and returns domain values, not
  its DTOs. The decision "where IMDb comes from — OMDb or PoiskKino" is made
  by `ratings_service`, not by a screen.
- **Sync merging is pure functions** over lists of rows, with no Drive and
  no database. The transport (Drive) and applying (a drift transaction) are
  separate. Only that way can the algorithm be tested on thousands of random
  sequences.
- **Screens read the database through `watch()` streams.** A sync that
  applied remote changes updates the open lists without manual `invalidate`.

---

## Startup and keys (Stage 1)

Before `runApp`, `main()` opens the database (creating `device_id` if there
is none), reads `SharedPreferences` and the keys, and passes all of it into
`ProviderScope` through overrides. The single reason: the first frame needs
the theme, the language and whether there is a TMDB key, otherwise the app
flashes the wrong theme or the main screen before onboarding.

The router keeps the user on onboarding while there is no TMDB key, and sends
them back there if the key is removed. The user leaves onboarding themselves,
with a button: after TMDB they may want to add the optional keys too.

A key check is one request (`KeyValidator`, `lib/data/key_validator.dart`)
with four outcomes: works / works but the limit is used up / rejected /
not reached. A rejected key isn't saved; "not reached" is saved marked "not
checked". The trial request to PoiskKino and OMDb is charged to the daily
budget like any other.

The shared HTTP client (`lib/data/http.dart`) doesn't throw on 4xx/5xx:
`{"Error": "Invalid API key!"}` with a 401 is an answer for the source's
client to read; only a network failure is an exception.

## Search and title cards (Stage 2)

Search is `search/multi`, sent as the user types (after a 400 ms pause) or
by the keyboard's search button; the answer to an outdated query is
dropped. TMDB pages load as the list is scrolled to its end. Results live
as long as the app is open: coming back to the tab shows the same search.

Cards nest inside the tab's branch (`/search/movie/603`,
`/search/tv/1399/s/1/e/3`) instead of opening on top of the shell: the
bottom navigation stays, and back leads to the season, the series, the
search, in order. There is one set of routes (`TitleRoutes.routes()`);
Stage 3 hangs the same set under "My ratings". The key is built from the
path through `WorkKey.tryParse`, so the rules are the same as everywhere.

There is no separate episode request: everything but the imdb id is in the
season response. The episode's imdb id is its own request
(`episode/{m}/external_ids`); if it fails, OMDb is asked by the series' imdb
id and the numbers.

Riverpod 3's automatic provider retry is off (`ProviderScope(retry: …)`): a
card error is offline or a TMDB refusal, and retrying those on a timer is
pointless. The error screen has a retry button.

## Title card

The loading order, so that the screen is useful right away:

1. The mini snapshot from `works`, if there is one: title, year, poster, your
   own score — instantly and without a network.
2. The TMDB card (through the HTTP cache): overview, seasons, TMDB rating.
3. External ratings from `external_ratings`: shown at once, even stale ones.
   In parallel, if they are older than 7 days and the budget allows, they are
   requested again.

Each rating source is a separate cell with its own state: value / no data /
no key / loading / error. One source failing doesn't break the card.

What a cell shows is decided by a pure function, `ratingCellState`
(`features/title/title_ratings.dart`), and every combination is covered by
a test:

- a value, once there is one, is always shown: while refreshing (with a
  small indicator), after a failure, even after the key was removed; older
  than 7 days, it is greyed out and dated ("as of Oct 12");
- `notFound` is "no data";
- no key is "add a key", and a tap opens Sources;
- otherwise it is loading, or the failure's reason: no connection, daily
  limit used up, key rejected, source error.

Which cells each kind gets: a film — Kinopoisk, IMDb, TMDB, RT, Metacritic;
a series — Kinopoisk, IMDb, TMDB; a season and an episode — IMDb and TMDB
(a season's IMDb is the episode average, labelled as such).

---

## Rating

- Input is a row of 19 values, 1.0…10.0 in steps of 0.5 (a snapping slider
  or a grid of buttons — decided on the mockup). Tapping the current score
  again doesn't delete it; deletion is a separate action with a confirmation.
- Saving is one transaction: `works` (the snapshot with all its ancestors) +
  `ratings` + a tombstone in `watchlist`.
- After saving — the **calibration sheet** (a bottom sheet): "The same",
  "A bit higher", "A bit lower"; the queries are in
  [data-model.md](data-model.md). Tapping another score in the sheet's header
  changes the one just given, and the sheet rebuilds. The sheet doesn't open
  if there are no other ratings of this kind.

---

## Offline

Without a network everything that rests on the database works: both lists,
sorting (including divergence by already cached ratings), statistics,
changing and deleting ratings, notes. Search and opening a card that isn't
in the HTTP cache aren't available offline; the screen says so plainly
instead of spinning an indicator.

---

## An update that outlives its screen

A rule from Amicus, same stack: `ref` after `await` throws if the widget was
unmounted in the meantime. Capture the `ProviderContainer` before the
`await`. Here it matters most for saving a rating, after which other tabs
update (lists, statistics). Thanks to drift's `watch()` streams there should
be few such places — but not zero.
