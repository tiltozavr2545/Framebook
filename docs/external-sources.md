# External sources

Where the app gets everything the user didn't create: the catalog, posters,
other people's ratings. What of it is stored locally, and for how long, is in
[data-model.md](data-model.md).

Initial API fixtures were captured on 2026-10-23 and are stored under
`app/test/fixtures/`. They record observed responses, not a guarantee that a
live provider remains unchanged. Capture procedures belong to
[testing](testing.md#capturing-api-fixtures), and registration steps to the
[API key guide](api-keys.md).

## Summary

| Source | Role | Key | Free limit | Required |
| --- | --- | --- | --- | --- |
| [TMDB](https://developer.themoviedb.org) | catalog, search, seasons and episodes, posters, genres, `imdb_id`, TMDB rating | API Read Access Token (v4) or API key (v3) | no daily limit, a rate limit (a few dozen requests a second) | **yes** |
| [PoiskKino API](https://poiskkino.dev) (formerly kinopoisk.dev) | Kinopoisk rating, `kp_id`; fallback source of the IMDb rating | `X-API-KEY`, issued by the Telegram bot `@poiskkinodev_bot` | **200 requests a day** | no |
| [OMDb](https://www.omdbapi.com) | IMDb rating, Rotten Tomatoes, Metacritic; IMDb for episodes | `apikey`, issued by email | 1,000 requests a day | no |

Without a PoiskKino key a card has no Kinopoisk rating, and sorting by
divergence from Kinopoisk doesn't work. Without an OMDb key there is no RT or
Metacritic, and IMDb for films and series comes from PoiskKino (if its key is
set). Without both, the TMDB rating remains. The app doesn't treat this as an
error: in place of an unavailable rating the card says "add a key", and a tap
opens Sources.

Quotas belong to each key, so all installations sharing one key also share
its request budget.

## TMDB — the catalog

Base: `https://api.themoviedb.org/3`. The response language is the
`language=ru-RU` / `en-US` parameter, following the app's locale.

| What | Request |
| --- | --- |
| title search | `GET /search/multi?query=…` — only `media_type` `movie` and `tv` are kept |
| people search | `GET /search/person?query=…` |
| person profile / filmography | `GET /person/{id}?append_to_response=combined_credits` |
| film | `GET /movie/{id}?append_to_response=external_ids,credits,release_dates` |
| movie collection | `GET /collection/{id}` — parts of the collection identified by `belongs_to_collection` |
| similar titles | `GET /movie/{id}/similar`, `/tv/{id}/similar` — first page, based on genres and keywords |
| series | `GET /tv/{id}?append_to_response=external_ids,aggregate_credits` — includes the season list and cast across all seasons |
| season | `GET /tv/{id}/season/{n}?append_to_response=aggregate_credits` — includes every episode with its `vote_average` and the season's aggregate cast |
| an episode's ids in other databases | `GET /tv/{id}/season/{n}/episode/{m}/external_ids` |
| genres | `GET /genre/movie/list`, `GET /genre/tv/list` — names for the statistics by genre; the lists share most ids |
| discovery shelves | `GET /trending/all/week`, `/movie/now_playing`, and movie/TV discover by rating with a vote threshold |
| popular people | `GET /person/popular` — first page for People discovery |
| analytics credits | `GET /movie/{id}/credits`; series and season details with appended `aggregate_credits`; episode details with appended `credits` and guest stars — verified against the rated snapshot's TMDB identity, cached locally only |
| personal discovery | `GET /discover/movie`, `/discover/tv` — genre/general candidate pools; retrieval/ranking budgets are in [recommendations.md](recommendations.md) |
| cover variants | `GET /movie/{id}/images`, `/tv/{id}/images`, `/tv/{id}/season/{n}/images`, `/tv/{id}/season/{n}/episode/{m}/images` — posters, or episode stills |
| person photos | `GET /person/{id}/images` — profile photos for the full-screen viewer |
| image configuration | `GET /configuration` — base URL and poster sizes |

Posters: `{secure_base_url}{size}{poster_path}`; `w185` in lists, `w342` in
a card's header, `w300` for an episode still. The full-screen viewer uses
`w780` posters and original stills when available in the configuration.
Variant requests omit the `language` filter. The viewer's image-selection
rules are in [product behavior](features.md#images-offline-use-and-keyboard).

What the fixtures confirmed:

- A film has `imdb_id` both at the root of the response and in
  `external_ids` — take the root one; `external_ids` is there for series.
- An episode's `imdb_id` from `episode/{m}/external_ids` matches what OMDb
  returns for that episode (`tt1829962` = Game of Thrones S1E3).
- Season 0 (specials) comes in a series' season list with
  `vote_average: 0.0`. **Zero on TMDB means "no votes", not a score of 0**:
  `vote_average == 0` is read as `not_found`.
- `/search/multi` in Russian finds films and series mixed together (four
  films and a series for «Матрица»); people are dropped by `media_type`.
- A nonexistent id is HTTP 404 with `status_code: 34`; a wrong key is
  `status_code: 7`.

Attribution is mandatory: the About screen shows the TMDB logo and the text
"This product uses the TMDB API but is not endorsed or certified by TMDB".

## PoiskKino — the Kinopoisk rating

Base: `https://api.poiskkino.dev/v1.5`, the key in the `X-API-KEY` header. An
unofficial service over Kinopoisk data; it has already changed its domain and
API version, so the client is isolated behind an interface, and replacing the
source is a new class, not edits all over the code.

| What | Request |
| --- | --- |
| first match when `imdb_id` is known | `GET /movie?externalId.imdb={imdb_id}` |
| first match without `imdb_id` | `GET /movie?externalId.tmdb={tmdb_id}` + filtering the results by `isSeries` (see below) |
| refresh by a known `kp_id` | `GET /movie/{kp_id}` |

From the response we take `id` (→ `works.kp_id`), `rating.kp`, `votes.kp`,
`rating.imdb`, `votes.imdb`. Kinopoisk and IMDb come in one request. A list
(`/movie?…`) is `{docs: [...], hasNext, …}`; list items carry no external
ids, only `/movie/{kp_id}` has them.

**A search by tmdb id is ambiguous.** TMDB numbers films and series
separately: film 603 (The Matrix) and series 603 are different titles.
PoiskKino stores the tmdb id without a type, and `externalId.tmdb=603`
returns both — the first was a 1997 series, «Салон Вероники» (fixture
`movie_by_tmdb_603.json`). Therefore:

1. There is an `imdb_id` (almost always) — search by it: an imdb id is
   globally unique. A single result is taken even if the two databases
   disagree on the type (a TMDB miniseries can be a film on Kinopoisk).
2. There isn't — search by tmdb id and keep the items whose `isSeries`
   matches the TMDB type (`movie` → `false`, `tv` → `true`). Filter by
   `isSeries`, not `type`: `type` splits into `movie`, `cartoon`, `anime`,
   `tv-series`, `animated-series`, and a `type=movie` filter would lose
   cartoons. Exactly one left — that's it; zero or several — `not_found`.

This is exactly why the "no guessing" rule applies (section "Matching ids"):
taking the first result, the app would have shown a Kinopoisk rating of 5.9
for The Matrix.

Other things from the fixtures:

- An empty result is HTTP 200 with `docs: []`, which is `not_found`.
- A tmdb id outside 1…2,000,000 is HTTP 400 with a validation error. That is
  a bad request, not "not found"; such an id is never sent.
- **Seasons and episodes have no Kinopoisk rating**: `/season` returns
  episode numbers, titles, dates and overviews, but not a single rating
  field. PoiskKino is never asked about a `season`/`episode`.

## OMDb — IMDb, Rotten Tomatoes, Metacritic

Base: `https://www.omdbapi.com/?apikey=…`.

| What | Request |
| --- | --- |
| film / series | `?i={imdb_id}` |
| episode | `?i={episode imdb_id}`; if TMDB doesn't know the episode's id — `?i={series imdb_id}&Season={n}&Episode={m}` |
| season | `?i={series imdb_id}&Season={n}` — the episode list with `imdbRating`; a season has no IMDb rating of its own, so the **episode average** is shown, clearly labelled |

From the response: `imdbRating` (the string `"8.7"`) + `imdbVotes` (a string
with commas, `"2,284,373"`), the `Ratings` array (`Rotten Tomatoes` as
`"83%"`, `Metacritic` as `"73/100"`). Numbers come **as strings** — parsing is
explicit only. `"N/A"` is `not_found`, not zero.

For a series and an episode `Ratings` holds only IMDb: OMDb has RT and
Metacritic for films.

A season's average is taken over episodes with a numeric `imdbRating`; `"N/A"`
ones are skipped. A season's episode list can contain extra items — Game of
Thrones season 1 has an unrated "episode 0".

Errors come as `Response: "False"` with a text in `Error`, and differ only by
that text:

| `Error` | HTTP | Means |
| --- | --- | --- |
| `Error getting data.` | 200 | `not_found` — the id is valid, there is no such title |
| `Incorrect IMDb ID.` | 200 | `not_found` — the id is malformed |
| `Movie not found!` | 200 | `not_found` (search by title, which we don't use) |
| `Invalid API key!` | 401 | `error`, the key is wrong or not activated |
| `Request limit reached!` | 401 (per the docs, no fixture captured) | `error`, the daily limit |

An OMDb key can be 7 or 8 characters — don't check the length on entry.

## Matching ids

The anchor id is TMDB's (`work_key` is built from it). The others are derived
along a chain and stored in `works`, so they aren't looked up again:

```
TMDB id ──external_ids──▶ imdb_id ──▶ OMDb
   │                         │
   │                         └──externalId.imdb──▶ PoiskKino ──▶ kp_id
   │                                                  ▲
   └──externalId.tmdb + isSeries filter (when there is no imdb_id)
```

The rule: **never match by title and year.** A wrongly attached rating is
worse than a missing one — it silently spoils the divergence sort and the
statistics. Not found by id is `not_found`, period.

Known `kp_id` values are retained only for titles with library snapshots.
Other titles are matched again on refresh; lookup by IMDb ID costs the same
request as refresh by Kinopoisk ID and returns the ratings too.

Manual linking ("this is the wrong film on Kinopoisk") is in
[future-development.md](future-development.md).

## Cache and lifetimes

TMDB responses use the file cache; PoiskKino/OMDb results use local
`external_ratings` rows. IMDb from PoiskKino is considered missing once an
OMDb key is added, allowing replacement by the preferred OMDb result.

| What | Where | TTL |
| --- | --- | --- |
| TMDB search responses | HTTP cache | 1 day |
| TMDB fast shelves / slow shelves | HTTP cache | 1 day / 7 days |
| TMDB film/series/season cards | HTTP cache | 7 days |
| TMDB genres, configuration, an episode's external ids | HTTP cache | 30 days |
| posters | image cache | by eviction (1,500 files, 90 days) |
| external rating, `ok` | `external_ratings` | 14 days for background refresh; an open card asks again if it is older than 7 days and the budget allows |
| external rating, `not_found` | `external_ratings` | 30 days |
| external rating, `error` | `external_ratings` + the service's memory | 1 hour (see below) |
| mini snapshot | `works` | refreshed when a card is opened or a user saves that title; saved translated titles are refreshed separately with 24-hour reuse per language/key generation |

A stale value is **shown**, not hidden: the card shows a rating's age when it
is past its TTL. A film's rating barely changes in two weeks, while an empty
space in its place changes everything.

An external rating fetched after the current device time is stale too: a
clock correction must not postpone refresh until that future date. Failure
throttling likewise applies only when its recorded time is not in the future.
HTTP cache pruning reads file modification times asynchronously.

Failure policy in `app/lib/data/ratings_service.dart`:

- A failure never overwrites an earlier value. An `error` row is written
  only where there was no row at all, so the card shows "source error"
  instead of an endless spinner. Absence is checked atomically at insertion,
  so a late failure from an older service instance cannot erase a successful
  refresh. Card request statuses are scoped to each provider build, preventing
  a response using an old key from replacing the new request's status.
- The one-hour pause before retrying lives in the service's memory, not in
  the table: changing a key recreates the service, and the retry should
  happen right away, not an hour later. An `error` row in the table is
  therefore always considered stale.
- Offline is not the source's answer: nothing is written and nothing is
  remembered, so the next card open retries.
- The HTTP cache (TMDB only) serves a stale entry when the network is down
  or TMDB returns a transient/service error, including an unreadable HTTP 200
  body. Explicit HTTP 401/404 responses remain rejected-key/not-found errors. A
  damaged cached body is a miss and is fetched again. Concurrent writes use
  separate staging files before atomically replacing the published entry.

Numeric API fields are optional when malformed: identifiers and counts must
be integers, and floating-point values must be finite. Ratings must fit their
source scale (positive and at most 10 for TMDB/Kinopoisk/IMDb; 0–100 for
Rotten Tomatoes/Metacritic). Invalid values are omitted, including overflowing
JSON exponents and string values such as `Infinity`; a bad field must not
attach data to a rounded title ID or poison statistics.

## Request budget

Every request to PoiskKino and OMDb first increments the counter in
`api_budget` (UTC days), then goes out. The services may count days in another time zone, so the counter can reset
before the provider does. The ceilings leave a reserve, and provider quota
errors still stop spending for the day.

| Source | Interactive requests (a card is open) | Background refresh | Reserve |
| --- | --- | --- | --- |
| PoiskKino (200) | up to 120 | up to 60 | 20 |
| OMDb (1000) | up to 600 | up to 300 | 100 |

There is one counter per source, so the split is enforced with ceilings on
that shared counter (`lib/data/budget.dart`): background refresh runs only
while less than its share (60 / 300) has been spent today, and requests from
an open card run while less than `daily − reserve` (180 / 900) has. The card
is guaranteed at least the "interactive" column, and gets more on days when
background refresh didn't run. When the ceiling is reached the cell keeps its
cached value and says "daily limit used up".

**Background refresh** runs while the app is open (no OS background tasks in
the MVP): a queue of rated titles that have no rating at all, then the
oldest. It goes with pauses, without parallelism. A library of 1,000 films
fills up with Kinopoisk ratings in about two to three weeks of normal use.
That is expected and visible to the user: the statistics say how many
ratings the divergence was computed over.

Scheduling in `app/lib/data/background_refresh.dart`: the first
pass starts ten seconds after launch, then one every half hour while the app
is in the foreground; three seconds between titles that cost a request. The
TTL is the background one (14 days for a value), and TMDB is left as is —
without a card there is no TMDB vote to record. A pass ends when the network
is gone, or once every source with a key has spent its background share.
A paused app waits for a lifecycle signal without a periodic
timer, and disposal during a request cannot schedule another pass. No timer
is created without budgeted source keys. Cancellation is checked between
sources; a lookup already in flight can finish, including shared card work.
Pacing records actual lookups after acquiring budget, so local missing-ID
results and joins to an existing request add no extra delay. The queue does
not select rating notes or unrelated series snapshots.

A "limit reached" answer from the service itself caps the rest of the day at
once, whatever the counter says.

## Key checks

Source clients request plain text and parse JSON explicitly with `tryJson`.
Letting Dio decode proxy HTML can turn a source error into an `unknown`
transport exception that looks offline. API 4xx/5xx bodies remain source
responses rather than being thrown before classification.

When a key is entered, one trial request:

- TMDB — `GET /configuration`;
- OMDb — `?i=tt0133093` (a film that surely exists);
- PoiskKino — `GET /movie/{a known kp_id}`; it is charged to the budget.

An invalid key isn't saved; with no network the key is saved marked "not
checked". Trial requests receive plain text and parse JSON explicitly. A
malformed or proxy HTML response is a source failure and does not save the key
as if the phone were merely offline.

HTTP 200 must also carry the expected probe: TMDB's image configuration with
a secure image base and poster sizes, PoiskKino's requested title ID, or OMDb's
successful response with the requested IMDb ID. An unrelated JSON object is
not evidence that the key works. Invalid calendar dates are omitted from
localized display rather than normalized into a different day.

## Additional card facts

Movie details include production countries, budget and worldwide revenue
(in USD); zero/nonpositive amounts are unknown and omitted. Appended release
dates supply the earliest known valid calendar date, falling back to the
primary release date. Movie collections and similar lists use the seven-day
detail/slow-shelf cache, with the same stale-cache fallback as other TMDB
responses. They do not consume PoiskKino or OMDb request budgets. They are
optional sections: failures do not prevent rating or viewing the main card.
