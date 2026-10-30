# Client design

What the app is built with and what lives where. There is no server, so this
is the whole project's architecture, not "what the client does on top of the
schema" as in Amicus. The data schema is in [data-model.md](data-model.md),
the external APIs in [external-sources.md](external-sources.md), sync in
[sync.md](sync.md).

**Status: Stage 6.** A design of its own and the polish (the editing-table
theme, the score reel, Discover, cast and people, saved cards offline) sit
on top of sync (Stage 5), comparison and statistics (Stage 4), your own
ratings and lists (Stage 3), search, cards and external ratings (Stage 2)
and the Stage 1 skeleton.

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
  The sync file (Stage 5) is read the same way, by hand, but strictly: a
  missing or mistyped field makes the whole file broken rather than a
  default (`lib/data/sync/sync_file.dart`).
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
| crypto | 3.0.7 | HTTP cache file names and sync deletion digests |
| cryptography | 2.9.0 | Argon2id and AES-256-GCM for optional encrypted key sync; requires Dart 3.3+ |
| cached_network_image / flutter_cache_manager | 3.4.1 / 3.4.5 | own `CacheManager` for posters |
| flutter_secure_storage | 10.3.4 | |
| shared_preferences | 2.5.3 | |
| google_sign_in | 7.2.0 | the new authorization API |
| googleapis / extension_google_sign_in_as_googleapis_auth | 15.0.0 / 3.0.0 | |
| googleapis_auth / http | 2.0.0 / 1.6.0 | direct since Stage 5: Drive errors and the authenticated client |
| file_picker | 11.0.3 | export ("Save to…") and import of the sync file |
| package_info_plus | 9.0.1 | the app version written into the sync file |
| fl_chart | 1.0.0 | **ceiling**: 1.1 needs vector_math 2.2 (`Matrix4.translateByDouble`), Flutter 3.32 pins 2.1.4 |
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
    library/            — the user's ratings and watchlist; title snapshots
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
them back there if the key is removed. The Drive restore route is also
available without a key. The user leaves onboarding themselves,
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

1. The TMDB card through the HTTP cache. If it can't load (offline,
   nothing cached) and the title has a snapshot in `works` (rated or on the
   watchlist), the **saved card** stands in: poster, title, year, your score
   and note, the last known ratings, and a line saying so with a retry
   (`features/title/saved_card.dart`, Stage 6). Without a snapshot, the
   error screen.
2. With the card: overview, cast and crew (`credits`), seasons, the TMDB
   rating.
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

When TMDB has renumbered a rated season or episode (Stage 6.5, the rules
are in [data-model.md](data-model.md), "When TMDB renumbers"), the card
asks inline rather than in a dialog: "Your rating of S1 · E5 was for an
episode that is now S1 · E3. Move it?" with Move and Keep, or, when a
rating already sits on the target, "Which score to keep?" with both scores
(`features/title/renumber_notice.dart`). It is built from the response the
screen already has and the stored ratings, so it costs no request:

- a series card asks about its seasons, above the season list;
- a season card asks about episodes now in this season (from any season of
  the series), above the episode list;
- an episode card asks only about its own number — under the header, or
  above "TMDB has no such title" when the number is gone.

One question at a time; an answered one disappears by itself (the notice
watches the ratings), and the next, if any, takes its place. An unanswered
one stays until answered — there is no "later".

---

Cast cards reserve space using the current text scale for two lines each of
name and role. Both wrap and ellipsize deliberately, so larger display text
does not clip the role or overflow the horizontal strip.

A cover on a movie, series, season or episode card opens a full-screen
viewer: the current image appears first, followed by UI-language,
original-language and textless variants. The viewer supports swipe and
pinch-to-zoom, using a cached small image while the larger size loads. A
saved offline card opens only its cached cover, without a network request.
TMDB's image configuration selects the large poster or still size.

## Rating (Stage 3)

All writes of the user's own data go through `Library`
(`lib/data/library/library.dart`); the screens never touch the tables.

- Every card has a "My rating" block between the header and the external
  ratings. It is built from the card's **lineage** — `WorkSnapshot`s of the
  title and all its ancestors, series first — because a rating is saved with
  all of them.
- Input is a bottom sheet with the **score reel** (Stage 6) and a note: a
  strip of film pulled through a gate, frames 1…10 in steps of 0.5, a
  haptic click per frame (`features/title/score_reel.dart`). In Stage 6
  it started on a blank leader frame so as not to nudge the choice; from
  Stage 6.5 it starts on 5, the middle of the scale, rather than on the
  minimum.
  Deletion is a separate action with a confirmation. Your own score is shown
  as "8" or "8.5", without a trailing ".0".
- Saving is one transaction: `works` (the snapshot with all its ancestors) +
  `ratings` + a tombstone in `watchlist`. Saving the same score and note
  again writes no new version — it would needlessly win a merge.
- The **calibration** runs under the reel while it moves (Stage 6; in
  Stage 3 it was a sheet after saving): up to four titles of the same kind
  at the score in the gate, and two each at the nearest scores below and
  above, laid out the way the strip runs — lower on the left. The queries
  are in [data-model.md](data-model.md). It is shown only once there are
  enough ratings of the kind: more than 20 for films, more than 10 for
  series, seasons and episodes each.
- A series and a season show the average of their rated parts under the
  score ("Your average over 4 episodes: 7.8"); seasons and episodes show
  your score next to them in the lists.
- Opening a card refreshes the snapshots that already exist (title in the
  current language, poster) — never creating new ones and never touching a
  rating's `updated_at`. A rated season's or episode's own TMDB id is the
  exception: it is kept while TMDB has another title under its number, so
  that the renumbering question isn't answered behind the user's back.

## Lists (Stage 3)

- **My ratings** — every live rating, joined with its snapshot and, for a
  season or an episode, the series' and season's snapshots, so a row reads
  "Game of Thrones · S1 · E3 · Lord Snow" with the season's poster. Filter by
  kind, sort by date rated, score, year or title (`arrangeRatings`, a pure
  function with tests; a season or an episode sorts under its series, in
  number order). The chosen filter and order last while the app is open.
- **Watchlist** — films and series, most recently added first. Removing is
  instant with "Undo" in a snackbar; rating a title removes it by itself.
- Both read the database through `watch()` streams, so they work offline and
  update by themselves. A row opens the card inside its own tab.

## Comparison and statistics (Stage 4)

- **"Mine − theirs"** is `divergence()` (`lib/data/library/divergence.dart`):
  your score minus the source's value, for the 1–10 sources only —
  Kinopoisk, IMDb, TMDB. Shown with its sign and one decimal ("+0.5",
  "−1.2", "±0"), next to the value in the card's cell once the title is
  rated.
- **My ratings** joins the cached Kinopoisk and IMDb rows into every row
  (`Library.watchRatings`), so the list re-sorts by itself when background
  refresh brings a value. The divergence sort compares with Kinopoisk or
  IMDb — the choice is remembered (`divergence_source` in
  `shared_preferences`) — in three orders: furthest apart, "I rate higher",
  "I rate lower". Rows without the value go last, most recent first, and
  say "no data".
- **Background refresh** (`lib/data/background_refresh.dart`) runs while the
  tabs are on screen and the app is in the foreground: a first pass ten
  seconds after start, then every half hour; a key change restarts it. A
  pass goes through rated titles that need asking — no rating at all first,
  then the oldest (`RatingsService.backgroundDue`) — one at a time, three
  seconds apart, within the background share of the budget
  ([external-sources.md](external-sources.md)). It stops when offline,
  when every source's share is spent, or when the app goes to the
  background. "Kinopoisk ratings loaded for N of M" counts the titles a
  source covers with the current keys that have its answer — a value or a
  definite "not there".
- **Statistics** is `computeStats` (`lib/data/library/stats.dart`), a pure
  function over the live ratings: count and average, the distribution by
  half points (an fl_chart bar chart), the deviation from Kinopoisk and IMDb
  (signed and absolute, over the titles that have the value), the average
  by genre (a season and an episode count under the series' genres) and by
  decade. A kind filter on top, as in My ratings. Genre names come from
  TMDB's genre lists through the HTTP cache; without them (offline, nothing
  cached) the genre section says so and the rest still works.

## Update checks

The latest stable GitHub release is checked at launch at most once per 24
hours; a manual check is available on About. Dismissal persists per version,
and the banner opens the release page. Offline and API errors are quiet during
automatic checks. Tests use a fake source, not the network.

The watchlist groups season entries under a tappable series header; the
header need not be a watchlist selection itself. Adding the whole series
and adding a season displace the opposite selection. The local and sync
rules, including concurrent offline selections, are in [sync.md](sync.md).
The series and season cards ask Move / Keep when TMDB renumbers a listed
season, using the ids already loaded on the card.

The comparison panel in the rating editor appears only with more than 20
other live film ratings or more than 10 other live ratings of the same TV,
season or episode kind. The threshold is checked before opening the editor,
so the reel stays in place while the score changes.

## Sync and backup (Stage 5)

The design is [sync.md](sync.md); here is what lives where in
`lib/data/sync/`.

- `sync_file.dart` — the file format: gzipped JSON with `format_version`,
  strict reading; a broken file and one from a newer app are different
  errors, and neither is ever overwritten.
- `merge.dart` — last write wins row by row, including permanent compact
  deletion registers. Deterministic tie breaking and equivalent full/compact
  deletions keep the merge commutative, associative and idempotent. Property
  tests check exactly that, and that three devices converge whatever the
  order of edits and syncs.
- `sync_store.dart` — the database side: reading the shared state, applying
  someone else's in one transaction (a row is written only where it wins over
  what is stored at that moment), and "replace everything". Rows are written
  as full companions: drift leaves null columns out of an upsert of a data
  class, which would keep a stale note or tombstone.
- `sync_engine.dart` — one pass over a `SyncRemote`, with the daily copies;
  `drive_remote.dart` is that remote on Drive's `appDataFolder`.
- `google_account.dart` — google_sign_in 7: Credential Manager sign-in with
  the Web client id, then Drive authorization for `drive.appdata` only. An
  interface, so widget tests run on a fake account and an in-memory Drive.
- `sync_controller.dart` — when to sync (launch and resume after 5 min, 30 s
  after a change to ratings or the watchlist, the button), the last sync and
  the last error for the screen, sign-out, deleting from Drive, the daily
  copies, export and import. Offline isn't shown as an error; an expired
  token is dropped and the call retried once.
- Settings → Sync and backup is `features/settings/sync_screen.dart`; export
  and import go through the system "Save to…" / file picker (file_picker).
  A paused-sync warning asks before applying compact deletions over unsynced
  live edits. Keep restores those entries with a newer version; Discard
  applies the deletions. Cancel leaves sync paused. Imports expose the same
  choice when necessary. Cleanup rules are in [sync.md](sync.md).
- `secrets_vault.dart` — optional encrypted key sync in a separate file,
  Argon2id in an isolate, AES-256-GCM and authenticated format parameters.
  Pending snapshots and cached derived keys use OS secure storage. No secret
  enters the rating file, exports or daily copies.
- `secrets_controller.dart` — account-scoped opt-in state, unlocking, applying
  restored keys and `divergence_source`, and uploading subsequent edits.
  The onboarding restore route is available before the required TMDB key.

## Design (Stage 6)

The look is an editing table (`lib/app/theme.dart`): a cool lightbox,
ink, film stock, and the editor's grease pencil.

- **Red is only yours.** The grease-pencil red (`primary`) marks your own
  score — on a card, in lists, on posters, the average in Stats — and your
  actions (Rate, Save). Section labels, warnings and statuses are never red.
  Edge-print amber (`tertiary`, `Reel.edge`) is for secondary figures:
  years, dates, vote counts.
- **Type:** Sofia Sans, bundled (OFL, `assets/fonts/`): Extra Condensed for
  figures and titles — tall narrow numerals like edge print on film — and
  the normal width for reading. Static weights cut from the variable fonts,
  so `FontWeight` picks the right file.
- **No plates.** Ratings on a card, the comparison blocks in Stats are
  columns ruled on top, not grey rounded cards; a note sits in the margin
  with a red rule.
- **One bold element:** the score reel. Everything around it stays quiet.
- Light and dark follow the system; both are designed, not inverted.
- `test/screenshots/` renders the main screens to PNG with the real fonts
  (`SCREENSHOTS=<dir> flutter test test/screenshots`) — the way to look at
  the design without a device; skipped in normal runs.

## Discover, cast and people (Stage 6)

- **Discover** (the first tab): a search field on top; while it is empty,
  shelves — like your favourites (TMDB recommendations for your latest
  films and series rated 8+, without what you rated), trending this week,
  in cinemas now, best of all time (discover by rating with a votes
  threshold; `/top_rated` is crowded with new titles that have a handful of
  votes). A shelf that fails or is empty is left out; all failing offline is
  one message with a retry. Shelves come through the HTTP cache: a day for
  what changes daily, a week for the rest.
- **Cast and crew** on every card (`credits`; not `aggregate_credits`,
  which is 350 KB for Game of Thrones): a strip of actors with their roles,
  and lines for creators, directors, writers, music and cinematography.
- **A person** (`features/person/`): dates, a folded biography, the
  filmography split into acting and behind the camera, without talk shows
  and news where they appear as themselves; your score next to what you
  rated. The person route sits at the tab's level and is pushed, since
  people and titles link to each other without end; back walks the pushes.
  The filmography is one list item per title, so the list builds only what
  is on screen.

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
