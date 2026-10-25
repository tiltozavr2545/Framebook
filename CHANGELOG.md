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
