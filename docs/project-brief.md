# Project brief: Framebook

> A personal diary of film and TV ratings: give your own score and see right away how it compares with Kinopoisk, IMDb and the rest.

**This document records the idea as of the start (2026-10-19)** — before the
first line of code. When reality parts ways with the idea, the brief is not
rewritten: the current schema is in [data-model.md](data-model.md), the
version history in [../CHANGELOG.md](../CHANGELOG.md), what is still open in
[future-development.md](future-development.md).

---

## 1. Why it is needed

Most people's film ratings are scattered: some on Kinopoisk, some on IMDb,
some in notes, some in their heads. Every service shows its own rating and
hides the others', and there is no one to ask "how close is my taste to
Kinopoisk's, and how close to IMDb's".

Framebook is one list of your own ratings that belongs to none of those
services, with all their ratings next to it. Hence its main properties:

- **Your data is yours.** Ratings live on the device and in the user's
  Google Drive, not on someone's server. There is no account to lose, and no
  service that can shut down along with your rating history.
- **Comparison is a primary feature, not a decoration.** The "mine −
  Kinopoisk" divergence is a column the list sorts by, and the basis of the
  statistics.
- **Score calibration.** Over a year a person's scale "drifts": what used to
  be a 7 has become an 8. The "what else you rated the same" sheet right
  after rating shows what the new score lines up with, and lets you adjust
  it.

The audience is the author and a couple of friends. That removes the
requirements of publishing in app stores, but not of care: ratings collected
over years must not be lost.

---

## 2. How the product works

**A work.** A film, a series, a season or an episode. All four are rated
independently: a series' score isn't computed from its seasons', nor a
season's from its episodes'. Next to their own score, a series and a season
show a hint — the average of the already rated parts ("by episodes: 7.8").

**A score.** From 1 to 10 in steps of 0.5. The scale matches Kinopoisk's and
IMDb's, so comparing is a plain difference with no conversion. A text note
can be added to a score.

**The calibration sheet.** It appears right after a score is saved and shows:

- works of the same kind with **exactly the same** score (several, recent
  first);
- **neighbours**: several works of the same kind with the nearest
  **existing** score above and the nearest below (not necessarily ±0.5 — if
  there are no 8.5s, the neighbour above is a 9).

The kind is always the same: a film is compared with films, an episode with
episodes. The score can be changed right from the sheet.

**External ratings.** On the card next to your score: Kinopoisk, IMDb, TMDB,
Rotten Tomatoes, Metacritic — whichever of them the particular work has, and
for which the user entered keys. Each with the "mine − theirs" difference.

**Lists.** "My ratings" (sortable by date, score, year, title, and by
divergence from Kinopoisk or IMDb) and the watchlist. Rating a work removes
it from the watchlist.

**Statistics.** The distribution of your scores, the average deviation from
Kinopoisk and IMDb (signed and absolute), the average score by genre and
decade.

**Sync.** Signing in with Google is only for Drive. Without signing in the
app works fully; the data just lives on one device.

---

## 3. Decisions made before the start

| Question | Decision | Why |
|---|---|---|
| Platform | Flutter, Android; iOS postponed | The stack is familiar from Amicus; friends get an APK, no stores |
| Catalog | TMDB as the base (search, cards, seasons/episodes, posters) | The best open API with series down to episodes and with external ids |
| Kinopoisk rating | PoiskKino API (unofficial, formerly kinopoisk.dev) | Kinopoisk has no official public API |
| IMDb / RT / Metacritic | OMDb API by `imdb_id` | The only simple source of all three; IMDb has no open API |
| API keys | Users enter their own | Without a server a built-in key can be pulled out of the APK, and the limits become shared by everyone |
| Scale | 1–10, steps of 0.5 | A direct comparison with Kinopoisk and IMDb |
| What is rated | Film, series, season, episode — independently | A series can be good as a whole and weak in particular seasons |
| Local cache | A mini snapshot in the database + an evictable cache with TTLs | An offline list without storing the catalog |
| Drive | Sync with merging, a file in `appDataFolder` | Several devices; the hidden folder stays out of the way in Drive |
| Audience | Myself and a couple of friends | APK distribution, a Google OAuth app without public verification |

---

## 4. MVP

- Entering and checking API keys (TMDB required, the others optional)
- TMDB search; a film/series card; the season list; a season's episode list
- External ratings on the card, with a cache and a request budget
- A 1–10 / 0.5 score with a note for a film, series, season and episode
- The calibration sheet
- "My ratings" with sorting, including by divergence; the watchlist
- Statistics
- Sync through Google Drive, export/import to a file
- en/ru, a dark theme

Everything else is in [future-development.md](future-development.md).

---

## 5. Risks known at the start

- **TMDB availability from Russia.** Users report that `api.themoviedb.org`
  and the poster CDN are unreachable from Russia in places without a VPN or
  a DNS change. If that turned out to be so, the catalog would have to come
  from PoiskKino, and `work_key` would be built from the Kinopoisk id. This
  is checked first, in Stage 0, before the key scheme is fixed. *(Removed in
  Stage 0, 2026-10-20: none of the users go online from a Russian IP.)*
- **PoiskKino is an unofficial service** with a free limit of 200 requests a
  day. It may shut down or change its API (it has already changed its
  domain). The Kinopoisk rating is therefore an optional part of the card,
  not a load-bearing one.
- **Limits.** 200 a day on PoiskKino and 1,000 a day on OMDb mean that the
  divergence sort for a library of a thousand ratings can't be built in one
  evening. A request budget and gradual background refresh are needed — see
  [external-sources.md](external-sources.md).
- **Terms of use.** TMDB requires attribution (text and logo on the About
  screen) and allows non-commercial use; OMDb data is CC BY-NC. For a
  personal app without monetization that is fine; Kinopoisk data through a
  third-party service is a grey area, acceptable for a circle of three
  people.
- **Google OAuth in Testing mode.** While the app is in Testing status in the
  Google Cloud console, access is given only to added test users, and refresh
  tokens live 7 days. What to choose is in [operations.md](operations.md).
