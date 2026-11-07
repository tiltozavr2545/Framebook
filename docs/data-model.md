# Data model

The local SQLite schema (through drift) and its invariants. There is no
server, so this is the project's only schema: everything the user created
lives here, and everything that came from external APIs is either a mini
snapshot or an evictable cache.

Schema declarations are in `app/lib/data/db/tables.dart`, migrations in
`database.dart`, and versioned snapshots in `app/drift_schemas/`. CHECK
constraints and foreign keys enforce storage boundaries; migration and
constraint tests are part of [testing](testing.md).

Schema 3 adds [pair-comparison history](pair-calibration.md), preserving
existing ratings, notes, watchlists and favourites through Drift migrations.
Synced tables are described below; `external_ratings`, `api_budget` and
`sync_state` are local tables, although selected sync metadata is serialized
into the shared file as specified in [sync](sync.md).

## Three layers of data

| Layer | What | Where it lives | Synced | Can be lost |
| --- | --- | --- | --- | --- |
| User data | ratings, notes, watchlist, favourite people, comparison history | `ratings`, `watchlist`, `favorite_people`, `pair_comparisons` | yes | **no** |
| Mini snapshot | title, year, poster, genres, external ids | `works` | yes, along with the rows referencing it | yes — reloaded from the API |
| Cache | external ratings, HTTP responses, images | `external_ratings`, disk cache | no | yes — by TTL and when space runs low |

`works` stores only what the offline library needs to display rows, sort by
title/year, group by genre/decade and identify titles in another source.
Overviews, cast, runtime and complete episode lists stay in the evictable
HTTP cache. Add a snapshot field only when the saved library needs it offline.

## `work_key` — a title's key

A natural string key derived from TMDB ids:

| Kind | Key | Example |
| --- | --- | --- |
| film | `tmdb:movie:{tmdb_id}` | `tmdb:movie:603` |
| series | `tmdb:tv:{tmdb_id}` | `tmdb:tv:1399` |
| season | `tmdb:tv:{tmdb_id}:s{season}` | `tmdb:tv:1399:s1` |
| episode | `tmdb:tv:{tmdb_id}:s{season}:e{episode}` | `tmdb:tv:1399:s1:e3` |

Natural keys make offline ratings of the same title on two devices merge
into one row with a version conflict, avoiding duplicate UUID-based rows.

Season/episode keys use numbers because those are the visible identifiers
and the parameters other sources accept, such as OMDb's `Season=1&Episode=3`.
Season 0 represents specials, following TMDB.

The `tmdb:` prefix identifies the source namespace. Build and parse keys
through `app/lib/data/work_key.dart`; never assemble them independently in
screens or clients. TMDB IDs require their movie/TV type; external matching
rules belong to [external sources](external-sources.md#matching-ids).

### When TMDB renumbers

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
  id, or the stand-in when the screen does not know it. The next refresh
  adopts the real ID. Displaced external IDs and cached scores are cleared,
  resolving the prompt without a separate dismissed state.
- Until answered, the complete stored snapshot survives identity-changing
  writes: card refresh, ancestor saves and rating edits. A live-rated part's ID is
  kept when TMDB now has another one under its number. Only Move, Keep, or
  rating the title anew after deleting it change it. A known id is never
  replaced by the stand-in either.
- A rating's `updated_at` changes only through Move or a conflict answer —
  user actions — never through detection or Keep.
- A move is represented by an ordinary tombstone and rating; it does not
  require a separate sync operation type.
- Watchlisted seasons use the same detection and Move / Keep prompt. Moves
  preserve their added date and update snapshots; a destination already
  rated is not re-added to the watchlist. Until answered, a watchlisted
  season's own TMDB id is protected from snapshot refreshes.

## Synced tables

### `works` — the mini snapshot

| Column | Type | Comment |
| --- | --- | --- |
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

- **Every rating/watchlist row and all its ancestors have snapshots.**
  Rate an episode, and `works` holds the episode, its season and the series.
  Otherwise the offline list can't show "Game of Thrones · S1E3".
- Refresh may update a saved snapshot without changing the user's rating.
  A content-language refresh changes only local `title`, without advancing
  `snapshot_updated_at`. Other snapshot refreshes advance that timestamp,
  never a rating's `updated_at`. Trigger/reuse scheduling belongs to the
  [architecture](client-architecture.md#library-writes-and-views).
  Known external IDs survive an upsert while identity is unchanged. Adopting
  another numbered TMDB object clears displaced external IDs and cached
  ratings; Move can transfer the source object's IMDb ID. Pending renumbering
  retains the complete old snapshot until the user answers.
- Cleanup may remove snapshots outside the ancestor lineage of retained
  rating/watchlist rows. Snapshots have no deletion tombstone because they
  are derived data. Compaction/retention rules belong to
  [sync](sync.md#tombstones).
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
| --- | --- | --- |
| `work_key` | text PK, FK → `works` | one rating per title |
| `score_half` | int | 2…20, CHECK; score × 2 (7.5 → 15) |
| `note` | text null | note/review, up to 10,000 Unicode code points |
| `created_at` | int | UTC ms, the first rating |
| `scored_at` | int | UTC ms, the last change of the **score** (not the note) — for "by date" sorting and "recent" in the calibration |
| `updated_at` | int | UTC ms, the last user change of any kind — merging goes by it |
| `updated_by` | text | `device_id` of the last writer — breaks ties on equal `updated_at` |
| `deleted_at` | int null | tombstone; a row with it is never shown |

Integer half points enforce the discrete scale at the storage and sync
boundaries. Calibration compares them exactly. The value becomes 1–10 for
display; no floating-point personal score is stored.

Score and note share one versioned row. Editing a note on one device and a
score on another therefore resolves as a whole-row conflict; the later row
wins. The model does not support a note without a score.

Rating a title again after deletion (tombstone) is an UPDATE of the same row:
`deleted_at = NULL`, new `score_half`, `scored_at`, `updated_at`.

### `watchlist` — "Watchlist"

| Column | Type | Comment |
| --- | --- | --- |
| `work_key` | text PK, FK → `works` | `movie`, `tv`, or `season` |
| `added_at` | int | UTC ms |
| `updated_at` | int | UTC ms |
| `updated_by` | text | `device_id` |
| `deleted_at` | int null | tombstone |

A rating write removes its watchlist entry atomically. A season rating also
records removal when no entry exists, preserving the user's choice against
older offline additions. Series/season selection fences are stored in
`sync_state`; their visibility and merge rules are specified in
[sync](sync.md#series-and-season-watchlist-choices).

### `favorite_people`

One row per positive TMDB `person_id` primary key, with `name`, nullable
relative `profile_path`, `updated_at`, `updated_by` and nullable `deleted_at`.
The name/photo form an offline mini snapshot. A favourite refers to the whole
person across professions. User changes advance its version monotonically;
analytics never edits it. Permanent removal tombstones and merging are
specified in [sync](sync.md#format-rules). Schema 2 added this table.

### `pair_comparisons`

Schema 3 adds immutable comparison events. `comparison_key` is the
primary key derived from the canonically ordered natural title keys and their
original score versions. There is no foreign key to `works`: comparison history
can outlive a title snapshot.

Each event contains `left_key` / `right_key`, their original `score_half` and
`scored_at` values, the corresponding `left_result_*` / `right_result_*` values,
`preference` (`left`, `equal`, `right`), local-calendar `day`, UTC `answered_at`
and `answered_by`. Scores retain the same CHECK range as ratings. The `day`
index supports the quota lookup. Workflow/selection belongs to
[pair calibration](pair-calibration.md), and wire ordering to
[sync](sync.md#format-rules).

## Local tables

### `external_ratings` — cache of external ratings

| Column | Type | Comment |
| --- | --- | --- |
| `work_key` | text | |
| `source` | text | `kp` / `imdb` / `tmdb` / `rt` / `metacritic` |
| `status` | text | `ok` / `notFound` / `error` |
| `value` | real null | as the source gave it |
| `scale` | int | 10 or 100 (RT in percent, Metacritic 0–100) |
| `votes` | int null | |
| `via` | text | which API returned it (`omdb`, `poiskkino`, `tmdb`) — IMDb can come from two |
| `fetched_at` | int | UTC ms |

PK is (`work_key`, `source`). `notFound` is cached as a definite answer;
absence is not. `via` distinguishes the provider that supplied an IMDb value.
TTLs, retry behavior and source-precedence rules belong to
[external sources](external-sources.md#cache-and-lifetimes).

Not synced: this is other people's data that goes stale, and every device
with the user's keys fetches it on its own. A new device sees the list of
ratings right after sync, and the divergence column fills in gradually.

### `api_budget` — limit spending

| Column | Type | Comment |
| --- | --- | --- |
| `source` | text | `poiskkino` / `omdb` / `tmdb` |
| `day` | text | `YYYY-MM-DD` UTC |
| `used` | int | |

PK is (`source`, `day`). The counter goes up **before** the request. Rows
older than a week are deleted (on app start).

### `sync_state` — key-value

`device_id` (a UUID created on first launch and never changed),
`last_sync_at`, `last_remote_modified_time`, `last_sync_error`,
`purged_before`, JSON-encoded `rating_deletions` / `watchlist_deletions`,
and `watchlist_fences` for the latest series and season selections.
The compact deletion registers retain only the natural key and deletion
version, not a score, note or snapshot. They have no foreign key to `works`
and are included in the sync file even though stored in this key-value table.
No schema migration is needed for these new keys. The Drive
file's id isn't kept: every pass lists the folder anyway, to find duplicate
files. Details are in [sync.md](sync.md).

## Outside the database

- **Recent-title history** — a bounded mini-snapshot list in
  SharedPreferences. Device-local, excluded from rating exports/Drive sync;
  malformed stored entries are skipped. UI rules are in
  [product behavior](features.md#discover-and-search).
- **API keys** — `flutter_secure_storage`, never in SQLite or the rating
  sync file. Optional password-encrypted key sync uses a separate Drive file
  and keeps the derived key in secure storage ([sync.md](sync.md)).
- **Settings** (theme, language, the default source for the divergence sort,
  `divergence_source`) — `shared_preferences`. Optional encrypted key sync
  includes only `divergence_source`; theme and language remain per-device.
- **Hidden Discover suggestions** — typed natural keys in the per-device
  `shared_preferences.recommendation_hidden` list. They are not ratings,
  watchlist deletions or negative taste evidence; no sync/export change.
- **The HTTP cache of API responses, and images** — on disk, evictable; see
  [external-sources.md](external-sources.md#cache-and-lifetimes).
- **People analytics** — compact credits in the same evictable disk cache,
  keyed by content language, natural work key and its stored TMDB identity.
  The enrichment/coverage contract is in [analytics](analytics.md#credit-enrichment).

## Storage invariants

All timestamps at the storage boundary are UTC epoch milliseconds. Release
dates remain timezone-free `YYYY-MM-DD` strings, never timestamp conversions.
API calendar-date parsing must reject impossible dates rather than normalize
them into another day.

`updated_at` advances on user changes only and monotonically within a row.
Background snapshots, external ratings and analytics never advance it.
`scored_at` changes only when the numeric score changes. Detailed merge and
clock-skew rules belong to [sync](sync.md#device-clocks).

Notes are limited to 10,000 Unicode code points, matching SQLite `length(TEXT)`
and sync validation. The editor preserves whole grapheme clusters within
that limit.

Query indexes include `ratings(deleted_at, score_half)`, `ratings(scored_at)`,
`works(kind)`, `works(parent_key)` and `works(year)`. Current comparison groups
are specified in [product behavior](features.md#rating-editor-and-lists),
and aggregate formulas in [analytics](analytics.md).

`sync_state.part_identity_merge_v4` marks the one-time cleanup of legacy
numbered-part external IDs. It changes derived data, not the schema version.
