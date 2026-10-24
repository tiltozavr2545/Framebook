# Postponed features

Everything deliberately left out of the MVP. Finished work doesn't go here:
the feature history is in [../CHANGELOG.md](../CHANGELOG.md), the MVP scope in
[project-brief.md](project-brief.md).

---

## iOS

Postponed by a decision at the start: for now friends get Android only. The
iOS platform code is created by `flutter create` and is in the repository,
but isn't maintained. When there is time:

- building on the M4 Mac, TestFlight from the developer account set up for
  Amicus (the process is in `docs/ios-deployment-guide.md` in lk-system);
- a separate iOS OAuth client in Google Cloud and a URL scheme for
  google_sign_in;
- the Keychain entry of flutter_secure_storage survives uninstalling the
  app — decide whether that is good or bad for API keys.

## Importing ratings from other services

- **IMDb** — the "Your Ratings" CSV export (it has `Const` = `imdb_id` and a
  1–10 score): matching `imdb_id → TMDB` through `/find/{imdb_id}`.
- **Letterboxd** — a CSV export, the 0.5–5 scale → ×2; there are no ids, only
  title and year, so it needs matching by title with manual confirmation of
  the doubtful ones — at odds with the "never match by title" rule from
  [external-sources.md](external-sources.md), hence only with a review
  screen.
- **Kinopoisk** — there is no official export; an option is parsing a saved
  HTML page of ratings or third-party exporters. Matching by `kp_id` through
  PoiskKino (it has `externalId.tmdb`), but 200 requests a day would stretch
  importing a large library over days.

An open question: when a rating already exists, which matters more — the
imported one or the local one?

## Manually linking an external id

"This is the wrong film on Kinopoisk" — a way to set `kp_id` or `imdb_id` by
hand when automatic matching was wrong or found nothing. A manual link must
be synced (`works` is derived data now), so it is a format change.

## Episode renumbering on TMDB

An episode's `work_key` is built from the season and episode numbers. If TMDB
renumbers (moves specials, merges double episodes), the rating stays on the
old number. An option: store the episode's TMDB id and offer to move the
rating when the number differs.

## Background sync and rating refresh

For now both happen only while the app is open. WorkManager on Android would
allow syncing after changes and pulling ratings once a day within the
budget.

## Cleaning up tombstones

For now they are kept forever (see [sync.md](sync.md)). They can only be
cleaned up together with a rule "a device that hasn't synced for more than N
days replaces its local state with the file rather than merging", otherwise
it would resurrect what was deleted.

## Syncing API keys and settings

So that three keys don't have to be entered again on a new device. Keys in
the user's own Drive are in their own storage, but they are still secrets off
the device; an option is encrypting them with a key derived from a password
only the user knows.

## Checking for updates in the app

A request to the GitHub Releases API on launch: if there is a newer version,
an unobtrusive banner with a link to the APK.

## Rewatches

A history of several viewings with different scores and dates; the current
score is the latest. It changes the model: `ratings` stops being "one row per
title".

## Watch date

When you watched, not when you rated. A separate field in `ratings` — a sync
format change.

## Ideas for later

- **Comparing with friends** — exchanging exports and "where my friend and I
  disagree most". Without a server, only through a file.
- **A separate "own" ratings source** — Letterboxd, for example, if an
  accessible API appears.
- **A home screen widget** — the watchlist or a random film from it.
- **A web/desktop version** — Flutter Web would hit CORS on some of the APIs;
  unlikely without a proxy server.

---

## Open questions

- The calibration sheet: does it need a "don't show" switch in settings? Not
  for now — decide after a couple of weeks of use.
- A watchlist for seasons ("finish season 3") — needed, or is the whole
  series enough?
