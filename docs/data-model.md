# Data schema

The local SQLite schema (through drift) and its invariants. There is no
server, so this is the project's only schema: everything the user created
lives here, and everything that came from external APIs is either a mini
snapshot or an evictable cache.

**Status: implemented in Stage 1.** The source of truth is the drift tables
in `app/lib/data/db/tables.dart`; schema snapshots per version are in
`app/drift_schemas/`. This file is for quick orientation and the "why"; when
they disagree, the code is right. CHECK constraints (the `score_half` range,
the allowed `kind`/`source`/`status`/`scale` values, season and episode
numbers) and the `ratings`/`watchlist` → `works` foreign keys are enforced by
the database itself — covered by `test/data/database_test.dart`.

How this data moves between devices is in [sync.md](sync.md); where the
external data comes from is in [external-sources.md](external-sources.md).

Tables: `works`, `ratings`, `watchlist` are synced; `external_ratings`,
`api_budget`, `sync_state` are local only.

---

## Three layers of data

| Layer | What | Where it lives | Synced | Can be lost |
|---|---|---|---|---|
| User data | ratings, notes, watchlist | `ratings`, `watchlist` | yes | **no** |
| Mini snapshot | title, year, poster, genres, external ids | `works` | yes, along with the rows referencing it | yes — reloaded from the API |
| Cache | external ratings, HTTP responses, images | `external_ratings`, disk cache | no | yes — by TTL and when space runs low |

The line between the snapshot and the catalog: `works` gets only what the
**offline list of your own ratings** can't work without — showing a row,
sorting by title/year, computing statistics by genre and decade, building a
request to another source. Overview, cast, runtime, a season's full episode
list — no: the card shows them, and they come from the API (through the HTTP
cache). If a new feature wants a field in `works`, the question to it is the
same: is it needed offline for what is already rated.

---

## `work_key` — a title's key

A natural string key derived from TMDB ids:

| Kind | Key | Example |
|---|---|---|
| film | `tmdb:movie:{tmdb_id}` | `tmdb:movie:603` |
| series | `tmdb:tv:{tmdb_id}` | `tmdb:tv:1399` |
| season | `tmdb:tv:{tmdb_id}:s{season}` | `tmdb:tv:1399:s1` |
| episode | `tmdb:tv:{tmdb_id}:s{season}:e{episode}` | `tmdb:tv:1399:s1:e3` |

Why natural rather than a UUID: two devices that rated the same film offline
must produce **one** row with a version conflict, not two rows that later
have to be glued together heuristically. A key from the source gives that for
free.

Why seasons and episodes go by number rather than by their own TMDB ids:
numbers are what the other sources use (OMDb asks `Season=1&Episode=3`), and
what a person sees. Season 0 is specials, as in TMDB.

The `tmdb:` prefix leaves room for the case where the catalog has to come
from another source (the TMDB availability risk, see
[project-brief.md](project-brief.md)). Building and parsing the key is one
pure function in one place (`lib/data/work_key.dart`), with tests; never glue
the string by hand anywhere.

### When TMDB renumbers (0.7.0)

TMDB occasionally renumbers seasons and episodes (moves specials, merges a
double episode, inserts a missing pilot), and a key built from numbers then
means another title. The rated title's own TMDB id, stored in
`works.tmdb_id`, tells where it went; the key itself never changes on its
own, and nothing moves without the user's answer.

- **Detection** compares what a screen has already loaded with the stored
  ratings, without a request of its own: a season card and an episode card
  compare the season's episode ids with every rated episode of the series,
  a series card compares its season list with the rated seasons. A rating
  whose stored id is now under another number of the same series and kind
  is a proposed move. A move to another season is found when the season it
  went to is opened. A stand-in id (the series' id, see below) is never
  matched; an id that isn't under any loaded number — it vanished, or it is
  in a season not opened yet — leaves the rating alone. The logic is a pure
  function, `proposeRenumbering` (`lib/data/library/renumbering.dart`).
- Moves that share a key are **one question**: a shift (E1 → E2 while
  E2 → E3) or a swap only works applied at once. A target that already has
  a live rating which isn't moving away is a **conflict**: the user picks
  which of the two scores stays (a merged double episode lands here).
- **Move** (`Library.moveRatings`, one transaction): the target's lineage
  snapshots are written first (the foreign key), the target's with the id
  TMDB has now; the old rating becomes a tombstone (`deleted_at`,
  `updated_at` through the usual never-backwards rule, `updated_by`); the
  target row is inserted or revived with the moved score, note,
  `created_at` and `scored_at`, replacing a live one there unless the user
  kept that one. The old `works` row stays — the tombstone refers to it.
  The old key's `external_ratings` are dropped: they were fetched by its
  numbers, for another title.
- **Keep** (`Library.keepRatings`): the rating stays on its number and now
  belongs to the title TMDB has there, so the snapshot takes that title's
  id (or the stand-in when the screen doesn't know it — the next refresh of
  that card takes the real one) and the question doesn't come back. There
  is no separate "dismissed" state.
- Until answered, the stored id survives every snapshot write — the
  refresh on opening a card, the ancestors saved with another rating, an
  edit of the rating itself: a live-rated season's or episode's own id is
  kept when TMDB now has another one under its number. Only Move, Keep, or
  rating the title anew after deleting it change it. A known id is never
  replaced by the stand-in either.
- A rating's `updated_at` changes only through Move or a conflict answer —
  user actions — never through detection or Keep.
- The sync file is unchanged: `works.tmdb_id` already travelled in it, and
  a move is an ordinary tombstone plus an ordinary rating.
- The watchlist holds only films and series, whose keys don't renumber.
  When seasons join it (Stage 6.5, item 11), a season's watchlist row has
  to follow renumbering the same way.

---

## Synced tables

### `works` — the mini snapshot

| Column | Type | Comment |
|---|---|---|
| `work_key` | text PK | see above |
| `kind` | text | `movie` / `tv` / `season` / `episode`, CHECK |
| `parent_key` | text null | season → series, episode → season; NULL for a film and a series |
| `tmdb_id` | int | the object's TMDB id (for a season/episode, their own: how a rating finds its title after renumbering) |
| `season_number` | int null | for a season and an episode |
| `episode_number` | int null | for an episode |
| `imdb_id` | text null | `tt…`; an episode has its own if TMDB knows it |
| `kp_id` | int null | Kinopoisk id; NULL means not looked up yet or not found (see `external_ratings.status`) |
| `title` | text | in the locale at the moment the snapshot was taken |
| `original_title` | text null | |
| `release_date` | text null | `YYYY-MM-DD` as it came from the API, without a time zone |
| `year` | int null | derived from `release_date`, for the index and sorting |
| `poster_path` | text null | a TMDB relative path (`/abc.jpg`), not a URL — the CDN base address comes from the configuration |
| `genre_ids` | text | JSON array of TMDB genre ids; empty for a season and an episode, which take the series' genres |
| `snapshot_updated_at` | int | UTC ms, when the snapshot was last refreshed from the API |

Invariants:

- **Everything a user row refers to, and all its ancestors, has a snapshot.**
  Rate an episode, and `works` holds the episode, its season and the series.
  Otherwise the offline list can't show "Game of Thrones · S1E3".
- The snapshot is refreshed when the card is opened (Stage 3) and, later,
  in the background every 30 days; the refresh rewrites the snapshot's own
  columns and `snapshot_updated_at`, never a rating's `updated_at`. An upsert
  never wipes a `kp_id` or an `imdb_id` found earlier: an unknown one is left
  out of the write rather than written as NULL.
- `works` rows that no `ratings` / `watchlist` row refers to (including
  through descendants) can be deleted locally on cleanup. A snapshot has no
  tombstone: it is derived data, there is nothing to "delete on other
  devices" — it simply stops being written to the sync file. Full tombstones
  retain snapshots until they are compacted after 180 days. Compact deletion
  registers retain no snapshot or foreign key; cleanup prunes unreferenced
  snapshots while retaining every referenced ancestor ([sync.md](sync.md)).
- A season's and an episode's `tmdb_id` is their own TMDB id; when TMDB
  didn't send it, the series' id stands in (the column must be positive),
  and such a stand-in is never matched when TMDB renumbers (see "When TMDB
  renumbers"). A rated one keeps its stored id through snapshot refreshes
  while TMDB has another title under its number.
  `title` is TMDB's own name for the season ("Сезон 1"), possibly empty —
  lists show the series' title with it. An episode has no `poster_path`;
  lists use the season's or the series' poster.

### `ratings` — scores

| Column | Type | Comment |
|---|---|---|
| `work_key` | text PK, FK → `works` | one rating per title |
| `score_half` | int | 2…20, CHECK; score × 2 (7.5 → 15) |
| `note` | text null | note/review, up to 10,000 characters |
| `created_at` | int | UTC ms, the first rating |
| `scored_at` | int | UTC ms, the last change of the **score** (not the note) — for "by date" sorting and "recent" in the calibration |
| `updated_at` | int | UTC ms, the last user change of any kind — merging goes by it |
| `updated_by` | text | `device_id` of the last writer — breaks ties on equal `updated_at` |
| `deleted_at` | int null | tombstone; a row with it is never shown |

Why integer half points: the calibration looks for "exactly the same"
score, and `7.5` as a `double` after a couple of round trips through JSON is
not guaranteed to be `7.5`. An integer compares without surprises. It becomes
1–10 only for display.

Why the score and the note are one row: a note without a score isn't planned
in the MVP, and one row means one conflict in merging instead of two linked
ones. The price: editing the note on one device and the score on another is
resolved for the whole row (the later one wins); for one person that is
acceptable.

Rating a title again after deletion (tombstone) is an UPDATE of the same row:
`deleted_at = NULL`, new `score_half`, `scored_at`, `updated_at`.

### `watchlist` — "Watchlist"

| Column | Type | Comment |
|---|---|---|
| `work_key` | text PK, FK → `works` | in the MVP, only `movie` and `tv` |
| `added_at` | int | UTC ms |
| `updated_at` | int | UTC ms |
| `updated_by` | text | `device_id` |
| `deleted_at` | int null | tombstone |

Rating a title sets `deleted_at` on its `watchlist` row in the same
transaction. Not the other way round: deleting a rating doesn't put the film
back on the list.

---

## Local tables

### `external_ratings` — cache of external ratings

| Column | Type | Comment |
|---|---|---|
| `work_key` | text | |
| `source` | text | `kp` / `imdb` / `tmdb` / `rt` / `metacritic` |
| `status` | text | `ok` / `notFound` / `error` |
| `value` | real null | as the source gave it |
| `scale` | int | 10 or 100 (RT in percent, Metacritic 0–100) |
| `votes` | int null | |
| `via` | text | which API returned it (`omdb`, `poiskkino`, `tmdb`) — IMDb can come from two |
| `fetched_at` | int | UTC ms |

PK is (`work_key`, `source`). `notFound` is cached just like `ok`: otherwise a
film missing from Kinopoisk would burn the PoiskKino limit on every open.
`error` lives briefly (an hour) — it is a failure, not an answer. TTLs and
the budget are in [external-sources.md](external-sources.md).

As implemented in Stage 2: an `error` row is written only where the title had
no row yet, and never replaces an `ok` or `notFound` one; the one-hour retry
pause is kept in memory by the ratings service, so a new key retries at once.
`via` matters: an IMDb row from PoiskKino counts as missing once an OMDb key
is added, and gets replaced by OMDb's value.

`works.kp_id` is remembered only for titles that have a snapshot (rated or on
the watchlist). Everything else is matched again on refresh — a lookup by
imdb id costs the same one request as a refresh by kp id, and returns the
ratings too.

Not synced: this is other people's data that goes stale, and every device
with the user's keys fetches it on its own. A new device sees the list of
ratings right after sync, and the divergence column fills in gradually.

### `api_budget` — limit spending

| Column | Type | Comment |
|---|---|---|
| `source` | text | `poiskkino` / `omdb` / `tmdb` |
| `day` | text | `YYYY-MM-DD` UTC |
| `used` | int | |

PK is (`source`, `day`). The counter goes up **before** the request. Rows
older than a week are deleted (on app start).

### `sync_state` — key-value

`device_id` (a UUID created on first launch and never changed),
`last_sync_at`, `last_remote_modified_time`, `last_sync_error`,
`purged_before`, and JSON-encoded `rating_deletions` / `watchlist_deletions`.
The compact deletion registers retain only the natural key and deletion
version, not a score, note or snapshot. They have no foreign key to `works`
and are included in the sync file even though stored in this key-value table.
No schema migration is needed for these new keys. The Drive
file's id isn't kept: every pass lists the folder anyway, to find duplicate
files. Details are in [sync.md](sync.md).

---

## Outside the database

- **API keys** — `flutter_secure_storage`, never in SQLite or the sync file.
- **Settings** (theme, language, the default source for the divergence sort,
  `divergence_source`) — `shared_preferences`. Not synced in the MVP.
- **The HTTP cache of API responses, and images** — on disk, evictable; see
  [client-architecture.md](client-architecture.md).

---

## Key queries

**The calibration** — for score `S` in the reel's gate on a title of kind
`K` (all queries over live rows, `deleted_at is null`, the same `kind`,
without the current title); it runs again as the reel moves:

1. "The same" — `score_half = S`, by `scored_at desc`, up to 4 rows.
2. "Neighbour above" — `score_half = (select min(score_half) … where score_half > S)`,
   up to 2 rows.
3. "Neighbour below" — symmetric, with `max(…) < S`.

The calibration appears only when there are enough ratings of this kind to
compare with: more than 20 live ratings for films, more than 10 for series,
seasons and episodes each (counted without the current title). Below that
the panel isn't shown at all — a handful of ratings makes "the same" and
the neighbours noise. When it is shown, an empty group says there is
nothing near.

**The hint for a series and a season** — the average of `score_half / 2.0`
over the live ratings of its children (`parent_key = X`). For a series, over
its seasons; if no season is rated but episodes are, over the episodes of all
seasons. Shown with the number of rated parts ("over 4 episodes: 7.8").

**Sorting by divergence** — `score_half / 2.0 − value` for the chosen source
(`kp` or `imdb`), absolute or signed. Rows with no cached value go to the end
of the list marked "no data" rather than dropping out. As implemented in
Stage 4, the `ok` value is joined into "My ratings" from `external_ratings`
and the sort itself is a pure function (`arrangeRatings`).

Indexes: `ratings(deleted_at, score_half)`, `ratings(scored_at)`,
`works(kind)`, `works(parent_key)`, `works(year)`.
