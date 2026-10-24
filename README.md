# Framebook

> A personal diary of film and TV ratings: give your own score and see right away how it compares with Kinopoisk, IMDb and the rest.

The app doesn't keep a film catalog of its own — it is loaded on demand from third-party sources (TMDB, Kinopoisk through the PoiskKino API, OMDb). All the app owns is your ratings, notes and watchlist, and they live on the device. There is no server and no sign-up: backup and sync between devices go through the user's own Google Drive.

A project for myself and a couple of friends. The original idea and the decisions made before the start are in [docs/project-brief.md](docs/project-brief.md); the local data schema is in [docs/data-model.md](docs/data-model.md).

## Status

In development, version 0.2.0. Working: API keys onboarding, search, film
and series cards down to single episodes, and ratings from Kinopoisk, IMDb,
Rotten Tomatoes, Metacritic and TMDB on every card. Your own ratings come
next (Stage 3). Progress is tracked in
[docs/implementation-plan.md](docs/implementation-plan.md). The first target
platform is Android (an APK for myself and friends); iOS is postponed
([docs/future-development.md](docs/future-development.md)).

## What the MVP will do

- Search for films and series; a card with poster, overview, seasons and episodes
- Your own score from 1 to 10 in steps of 0.5 — for a film, a series, a single season and a single episode; the scores are independent, and a series or season shows the average of its already rated parts as a hint
- A text note with the score
- A calibration sheet right after rating: what else you rated the same, and the neighbours one step above and below — always within the same kind (films with films, episodes with episodes)
- Ratings next to yours: Kinopoisk, IMDb, TMDB, Rotten Tomatoes, Metacritic — with the "mine − theirs" difference
- "My ratings" sortable by divergence from Kinopoisk or IMDb
- A watchlist
- Statistics: the distribution of your scores, the average deviation from Kinopoisk/IMDb, a breakdown by genre and decade
- Offline use for what is already rated: the list, sorting, statistics
- Sync and backup through Google Drive (the app's hidden folder), plus export/import to a file
- Two locales (en/ru), a dark theme

## Stack

- **Client:** Flutter / Dart (Android; iOS postponed)
- **State management:** Riverpod
- **Navigation:** go_router
- **Local database:** SQLite through drift
- **External data:** TMDB API (catalog, search, posters), PoiskKino API (Kinopoisk rating), OMDb API (IMDb, Rotten Tomatoes, Metacritic) — details in [docs/external-sources.md](docs/external-sources.md)
- **Sync:** Google Drive API v3, `appDataFolder`, Google Sign-In — details in [docs/sync.md](docs/sync.md)
- **CI:** GitHub Actions — `dart format`, `flutter analyze`, `flutter test` on every push/PR; a signed APK in a GitHub Release for every `v*` tag

The app contains no third-party API keys: every user gets their own (free) and enters them in settings. The TMDB key is required — without it there is no search; the PoiskKino and OMDb keys are optional, and without them a card simply shows fewer ratings. Why it works this way is in [docs/project-brief.md](docs/project-brief.md).

## Repository layout

```
app/                     — the Flutter app
  lib/features/          — search, title, ratings, watchlist, stats, sync, settings
  lib/data/              — drift schema, external API clients, caches
  lib/shared/            — what several features use at once
  test/                  — unit and widget tests
docs/                    — brief, data schema, sources, sync,
                           client design, operations, postponed work
```

## Running locally

```bash
cd app
flutter pub get
flutter run
```

There are no secrets in the build: API keys are entered in the app itself on
first launch ([how to get them](docs/api-keys.md)). After changing drift tables
or localization strings, run `make codegen`. Syncing with Google Drive needs
an OAuth client for your own `applicationId` and signing key SHA-1 — see
[docs/operations.md](docs/operations.md).

## Documentation

Current:

- [Data schema](docs/data-model.md) — local tables, keys, invariants; the main document for understanding how things work
- [External sources](docs/external-sources.md) — which APIs, what we take from them, id matching, cache, limits
- [Sync and backup](docs/sync.md) — the Google Drive file format, the merge algorithm, export/import
- [Client design](docs/client-architecture.md) — what the app is built with, and default decisions
- [Getting the API keys](docs/api-keys.md) — TMDB, PoiskKino, OMDb step by step, what goes in each field ([in Russian](docs/api-keys.ru.md))
- [Operations](docs/operations.md) — keys, Google Cloud OAuth, signing and distributing the APK
- [Postponed features](docs/future-development.md) — iOS, importing from other services, open questions
- [Implementation plan](docs/implementation-plan.md) — MVP stages and their progress
- [Changelog](CHANGELOG.md) — what appeared in which version

Historical — how the project was conceived:

- [Project brief](docs/project-brief.md) — the original idea, MVP scope and decisions made before the start
