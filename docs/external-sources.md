# External sources

Where the app gets everything the user didn't create: the catalog, posters,
other people's ratings. What of it is stored locally, and for how long, is in
[data-model.md](data-model.md).

**Status: endpoints and fields confirmed with live requests on 2026-10-23.**
The recorded responses are in `app/test/fixtures/`, captured with
`scripts/capture-fixtures.sh` (see [operations.md](operations.md)). If
anything below disagrees with a fixture, the fixture is right.

---

## Summary

| Source | Role | Key | Free limit | Required |
|---|---|---|---|---|
| [TMDB](https://developer.themoviedb.org) | catalog, search, seasons and episodes, posters, genres, `imdb_id`, TMDB rating | API Read Access Token (v4) or API key (v3) | no daily limit, a rate limit (a few dozen requests a second) | **yes** |
| [PoiskKino API](https://poiskkino.dev) (formerly kinopoisk.dev) | Kinopoisk rating, `kp_id`; fallback source of the IMDb rating | `X-API-KEY`, issued by the Telegram bot `@poiskkinodev_bot` | **200 requests a day** | no |
| [OMDb](https://www.omdbapi.com) | IMDb rating, Rotten Tomatoes, Metacritic; IMDb for episodes | `apikey`, issued by email | 1,000 requests a day | no |

Without a PoiskKino key a card has no Kinopoisk rating, and sorting by
divergence from Kinopoisk doesn't work. Without an OMDb key there is no RT or
Metacritic, and IMDb for films and series comes from PoiskKino (if its key is
set). Without both, the TMDB rating remains. The app doesn't treat this as an
error: in place of an unavailable rating the card says "add a key", and a tap
opens Sources.

Why the keys belong to the user rather than the build is in
[project-brief.md](project-brief.md). What matters here: **the limits are per
user**, and 200 PoiskKino requests a day is one person's whole budget, not the
app's.

---

## TMDB — the catalog

Base: `https://api.themoviedb.org/3`. The response language is the
`language=ru-RU` / `en-US` parameter, following the app's locale.

| What | Request |
|---|---|
| search | `GET /search/multi?query=…` — only `media_type` `movie` and `tv` are kept |
| film | `GET /movie/{id}?append_to_response=external_ids` |
| series | `GET /tv/{id}?append_to_response=external_ids` — includes the season list |
| season | `GET /tv/{id}/season/{n}` — includes every episode with its `vote_average` |
| an episode's ids in other databases | `GET /tv/{id}/season/{n}/episode/{m}/external_ids` |
| genres | `GET /genre/movie/list`, `GET /genre/tv/list` — names for the statistics by genre; the lists share most ids |
| image configuration | `GET /configuration` — base URL and poster sizes |

Posters: `{secure_base_url}{size}{poster_path}`; `w185` in lists, `w342` in
a card's header, `w500` for an episode still (all present in `poster_sizes` /
`still_sizes`).

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

**TMDB availability from Russia is not an issue for this project** (decided
2026-10-20). Users report that `api.themoviedb.org` and `image.tmdb.org` are
unreachable from Russia in places, but none of the app's users go online from
a Russian IP. So TMDB stays the base of the catalog with no fallback. From the
development machine all four APIs answer.

---

## PoiskKino — the Kinopoisk rating

Base: `https://api.poiskkino.dev/v1.5`, the key in the `X-API-KEY` header. An
unofficial service over Kinopoisk data; it has already changed its domain and
API version, so the client is isolated behind an interface, and replacing the
source is a new class, not edits all over the code.

| What | Request |
|---|---|
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

---

## OMDb — IMDb, Rotten Tomatoes, Metacritic

Base: `https://www.omdbapi.com/?apikey=…`.

| What | Request |
|---|---|
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
|---|---|---|
| `Error getting data.` | 200 | `not_found` — the id is valid, there is no such title |
| `Incorrect IMDb ID.` | 200 | `not_found` — the id is malformed |
| `Movie not found!` | 200 | `not_found` (search by title, which we don't use) |
| `Invalid API key!` | 401 | `error`, the key is wrong or not activated |
| `Request limit reached!` | 401 (per the docs, no fixture captured) | `error`, the daily limit |

An OMDb key can be 7 or 8 characters — don't check the length on entry.

---

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

Manual linking ("this is the wrong film on Kinopoisk") is in
[future-development.md](future-development.md).

---

## Cache and lifetimes

| What | Where | TTL |
|---|---|---|
| TMDB search responses | HTTP cache | 1 day |
| TMDB film/series/season cards | HTTP cache | 7 days |
| TMDB genres, configuration, an episode's external ids | HTTP cache | 30 days |
| posters | image cache | by eviction (1,500 files, 90 days) |
| external rating, `ok` | `external_ratings` | 14 days for background refresh; an open card asks again if it is older than 7 days and the budget allows |
| external rating, `not_found` | `external_ratings` | 30 days |
| external rating, `error` | `external_ratings` + the service's memory | 1 hour (see below) |
| mini snapshot | `works` | refreshed every 30 days and when the card is opened |

A stale value is **shown**, not hidden: the card shows a rating's age when it
is past its TTL. A film's rating barely changes in two weeks, while an empty
space in its place changes everything.

How failures are handled (as implemented in Stage 2,
`lib/data/ratings_service.dart`):

- A failure never overwrites an earlier value. An `error` row is written
  only where there was no row at all, so the card shows "source error"
  instead of an endless spinner.
- The one-hour pause before retrying lives in the service's memory, not in
  the table: changing a key recreates the service, and the retry should
  happen right away, not an hour later. An `error` row in the table is
  therefore always considered stale.
- Offline is not the source's answer: nothing is written and nothing is
  remembered, so the next card open retries.
- The HTTP cache (TMDB only) serves a stale entry when the network is down
  or TMDB answers with an error — an old overview beats an error screen.

---

## Request budget

Every request to PoiskKino and OMDb first increments the counter in
`api_budget` (UTC days), then goes out. The services themselves may count
days in another time zone. UTC is a conservative approximation: the counter
may reset before the real one does, so the ceilings below leave a reserve.

| Source | Interactive requests (a card is open) | Background refresh | Reserve |
|---|---|---|---|
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

As implemented in Stage 4 (`lib/data/background_refresh.dart`): the first
pass starts ten seconds after launch, then one every half hour while the app
is in the foreground; three seconds between titles that cost a request. The
TTL is the background one (14 days for a value), and TMDB is left as is —
without a card there is no TMDB vote to record. A pass ends when the network
is gone, or once every source with a key has spent its background share.

A "limit reached" answer from the service itself caps the rest of the day at
once, whatever the counter says.

---

## Key checks

When a key is entered, one trial request:

- TMDB — `GET /configuration`;
- OMDb — `?i=tt0133093` (a film that surely exists);
- PoiskKino — `GET /movie/{a known kp_id}`; it is charged to the budget.

An invalid key isn't saved; with no network the key is saved marked "not
checked".
