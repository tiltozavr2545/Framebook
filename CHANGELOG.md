# Changelog

Framebook's version history. Moved out of AGENTS.md so that it isn't loaded
into context in full on every session — here it is read on demand, when it is
actually needed.

For **why** a particular decision was made, look not here but in the document
that describes it (`docs/`), or in `git log`. This is the chronology of what
appeared in which version. Entry format: what was done, version in brackets;
the version is `name+build` from `app/pubspec.yaml`.

MVP progress by stage is in [docs/implementation-plan.md](docs/implementation-plan.md).

## Before the first version

- Project documentation: brief, data schema, external sources, sync, client
  design, operations, plan and postponed work (2026-10-19, no code yet).
- App skeleton (0.0.1+1): a Flutter project in `app/` on 3.32.8 with
  dependencies chosen for it, an Android build modelled on Amicus (SDK 36,
  AGP 8.9.3, the release build refuses to build without a signing key),
  Makefile, git hooks, CI, a script that captures external API fixtures.
- Release signing key (in GitHub secrets and in a copy outside the
  repository) and the `release-apk.yml` workflow: a `vX.Y.Z` tag → a signed
  APK in a GitHub Release. The risk of TMDB being unavailable from Russia is
  removed — the users don't go online from Russian IPs (0.0.1+1).
- Fixtures of all three APIs captured with live keys; the "to check" notes
  in `docs/external-sources.md` closed. Kinopoisk matching reworked to
  "imdb_id first": a search by tmdb id mixes up films and series with the
  same number. A step-by-step key guide in `docs/api-keys.md` (0.0.1+1).

## 0.1.0 — Stage 1 (first release, build 3)

- Local database (drift): all six tables from `docs/data-model.md` with CHECK
  constraints and foreign keys, schema snapshot v1, `device_id` on first
  launch, tracking of daily API limits.
- `WorkKey`: building and parsing a title's key, the chain of ancestors.
- Onboarding and Settings → Sources: entering TMDB, PoiskKino and OMDb keys,
  checking them with a trial request, storing them in secure storage, a link
  to the guide. Without a TMDB key the app stays on onboarding.
- A shell with the Search / My ratings / Watchlist / Stats tabs (placeholders
  for now), language (en/ru) and theme settings.
- The `INTERNET` permission in the release build; a CI check that the
  generated code is up to date.
- The key field's hint moved below the field — on a phone it was cut off with
  an ellipsis.

## 0.2.0 — Stage 2 (build 4)

- Search for films and series as you type, with paging; posters through an
  image cache.
- Film and series cards, the season list, a season screen with its
  episodes, an episode card. Cards nest inside the Search tab, so back
  walks episode → season → series → results.
- External ratings on every card: Kinopoisk (PoiskKino), IMDb, Rotten
  Tomatoes and Metacritic (OMDb), TMDB. Cache → daily budget → request; ids
  are matched by imdb id, or by tmdb id plus type — never by title. Each
  cell has its own state: value, stale value with its date, no data, add a
  key, loading, failure reason.
- Our own on-disk TMDB cache with real TTLs and an offline fallback,
  replacing `dio_cache_interceptor`.
- "About" screen with the TMDB logo and attribution, data sources, licenses.
- Key buttons in Sources wrap on a narrow screen instead of overflowing.
- Repository text (docs, comments) is now in English. The key guide the app
  opens comes in the UI's language: `docs/api-keys.md` in English,
  `docs/api-keys.ru.md` in Russian.

## 0.3.0 — Stage 3 (build 5)

- Your own ratings, 1–10 in steps of 0.5, with a note, on a film, a series,
  a season or an episode — independently. Saved in one transaction with the
  snapshots of the title and its ancestors; deletion is a tombstone, with a
  confirmation.
- The calibration sheet after a new or changed score: what else of the same
  kind you rated the same, and the nearest scores above and below; −/+
  nudges the score by half a point right there.
- A series and a season show the average of their rated parts; season and
  episode lists show your score next to each.
- My ratings tab: filter by kind, sort by date rated, score, year or title;
  works offline. Rows open the card inside the tab.
- Watchlist tab: add from a film or series card, remove with undo; rating a
  title takes it off the list.
- Opening a card refreshes the snapshots of titles you have rated or listed.

## 0.4.0 — Stage 4 (build 6)

- "Mine − theirs" next to Kinopoisk, IMDb and TMDB on the card of a rated
  title. Rotten Tomatoes and Metacritic are other scales and get none.
- My ratings sorts by divergence from Kinopoisk or IMDb: furthest apart,
  "I rate higher", "I rate lower"; titles without the value go last. The
  source chosen is remembered.
- Background refresh: while the app is open, the external ratings of rated
  titles are fetched within the background share of the daily budget, with
  "ratings loaded for N of M" in the divergence sort and the statistics.
- Stats tab: count and average, the distribution of your scores, the
  average deviation from Kinopoisk and IMDb (signed and absolute, and over
  how many ratings), the average by genre and by decade; a kind filter.
  Works offline, except genre names the first time.
- Releases: the workflow verifies the APK's signature and certificate before
  publishing.

## 0.5.0 — Stage 5 (build 7)

- Sync through your own Google Drive: sign in with Google in Settings →
  Sync and backup, and ratings, notes and the watchlist are merged between
  your devices — on launch, on returning to the app, half a minute after a
  change, and with the button. The app gets access only to its own hidden
  folder in your Drive (`drive.appdata`).
- Merging is last write wins per title; a first sign-in on a device with
  ratings asks before merging and shows how many there will be.
- Daily copies in Drive for the last 7 days, restorable from the same
  screen; deleting the data from Drive; signing out keeps everything.
- Export to a file and import from one (merge, or replace everything) —
  works without Google.
- A home page and a privacy policy on GitHub Pages
  (https://tiltozavr2545.github.io/Framebook/).
- Fix: a cached external rating that changed to "not found" could keep its
  old value in the database.

## 0.6.0 — Stage 6 (build 8)

- A new look: an editing table — a cool lightbox, ink and film, with the
  grease-pencil red kept for your own scores and actions. Sofia Sans, light
  and dark themes by the system.
- The score reel: pull a strip of film through the gate to choose a score,
  1–10 by 0.5, with a click per frame. Your other ratings of the same kind
  at that score, and the nearest ones below and above, show above it and
  change as it moves; the separate comparison sheet is gone.
- Discover replaces Search: the search field over shelves — like your
  favourites, trending this week, in cinemas now, best of all time.
- Cast and crew on every card, guest stars on episodes; a person page with
  their filmography, your score next to what you rated.
- A card that can't load offline opens from what was saved with your
  rating or watchlist entry.
- Cards: the title large, your score as a big red figure, the note in the
  margin, the other ratings as ruled columns. Stats: your average as the big
  figure.
- The app's icon and splash screen; the version on the About screen;
  shorter tab names.

## 0.7.0 — Stage 6.5 (build 9)

- When TMDB renumbers a season or an episode you rated (moves specials,
  merges a double episode), the series, season or episode card notices it
  from what it already loaded and asks inline: move the rating to the
  title's new number, or keep it where it is. If the new number already has
  your rating, you choose which score stays. The sync file format is
  unchanged.
- Deleted ratings and watchlist entries are compacted after 180 days, freeing
  their notes and unneeded title snapshots. Small deletion records remain so
  old devices and exported backups cannot silently bring them back. Sync
  asks before removing unsynced local edits and lets you keep them instead.
  The sync file is now version 2; old exports still import, while older app
  versions must update before syncing.
- Optionally sync your API keys and preferred comparison source through a
  separate password-encrypted file in your Google Drive. Restore them on
  first launch without entering the TMDB key again; each device remembers
  its encryption key in secure storage. Theme and language stay local,
  and rating exports and daily copies never include your API keys.
- Framebook checks for new releases once a day and offers a link to the
  release page. You can dismiss the banner until the next version, or check
  manually from About.
- The score comparison panel appears once you have enough ratings of the
  same kind to make the comparison useful.
- New ratings start at 5 on the score reel; editing a rating opens at its
  existing score.
