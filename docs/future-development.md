# Postponed features

Unscheduled work and unresolved product choices. Move an item to the
[implementation plan](implementation-plan.md) when it is scheduled and remove
it here once delivered. Completed changes belong in the
[changelog](../CHANGELOG.md).

## Share title links with an optional score

Postponed on 2026-11-06 while HTTPS App Links hosting is unresolved.
Share films, series, seasons and episodes as links opening the corresponding
Framebook card. The sender can include their own score or send the title only;
unrated titles are shared without a score. The recipient sees the included
score separately from their own rating, with wording such as "Your friend
rated this 8.5". Without Framebook, offer installation from GitHub Releases.

Verified Android App Links require an association file at the domain root,
not under the current project site's `/Framebook/` path. Choose hosting and
the link address before implementation. Sender identity, score lifetime,
retaining received scores and default inclusion remain undecided. Do not
replace this request with sharing an image.

## iOS

No implementation is scheduled. When this becomes a supported target, plan:

- A compatible macOS/Xcode build host, signing and TestFlight distribution.
- A separate Google OAuth client and the URL scheme required by sign-in.
- A decision about API keys surviving uninstall through Keychain storage.

## Comparing with friends

Explicitly postponed during Stage 6.5. A future file exchange should contain
scores only and show a one-off comparison without storing friends' libraries.
No server is planned. Presentation and matching details remain to be designed.

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

## OS background work

Consider Android WorkManager for sync and rating refresh while the app is
closed. This needs lifecycle, quota and battery policy beyond the current
foreground services.

## Rewatches

A history of several viewings with different scores and dates; the current
score is the latest. It changes the model: `ratings` stops being "one row per
title".

## Watch date

When you watched, not when you rated. A separate field in `ratings` — a sync
format change.

## Ideas for later

- **A separate "own" ratings source** — Letterboxd, for example, if an
  accessible API appears.
- **A home screen widget** — the watchlist or a random film from it.
- **A web/desktop version** — Flutter Web would hit CORS on some of the APIs;
  unlikely without a proxy server.
