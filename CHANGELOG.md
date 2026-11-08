# Changelog

Changes delivered in each version, with Android build numbers. Current behavior
is maintained in the [documentation](docs/README.md), pending work in the
[implementation plan](docs/implementation-plan.md), and historical verification
evidence in [review reports](docs/reviews/README.md).
Versions are listed from oldest to newest; append new entries at the end.

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
  Old exports still import, while older app versions must update before
  syncing the new file format.
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
- Tap a cover to see it full screen, zoom in, and swipe through available
  posters or episode stills. Saved offline cards open their cached cover.
- Clearer key setup: the app and guide highlight that TMDB registration
  needs a computer, and the PoiskKino guide explains its Telegram membership
  requirements.
- Actor names and roles fit more reliably at larger text and display sizes.
- Add individual seasons to the watchlist, grouped under their series.
  Rating a season removes it; choosing a whole series replaces its seasons,
  and choosing a season replaces the whole-series selection. If TMDB changes
  season numbers, the app asks whether to move the saved entry. The sync
  format is now version 3; older exports remain readable.

## 0.7.1 — Review and fixes (build 10)

- Saved titles refresh in the selected language without changing ratings.
- Films with a future release date cannot be rated yet; they can still be
  added to the watchlist. Unknown release dates do not block rating.
- Open a person's photograph full screen and swipe through available photos.
- More reliable sync when edits, sign-out or Drive deletion overlap an
  upload; first sync waits for confirmation, including with a watchlist.
  Invalid backups are rejected before import, and searches discard stale
  responses as soon as a new query is entered.

## 0.7.2 — Sync correctness fixes (build 11)

- Sync preserves Kinopoisk and IMDb ids when snapshots tie, and translated
  titles stay local to each device instead of being uploaded back and forth.
- Encrypted key sync merges each API key independently, including deletions
  and edits made while locked. Drive requests time out, offline session
  restore stays quiet, and failed Drive deletion keeps key sync enabled.
- Key checks reject malformed service responses instead of saving the key as
  unverified, and failed update checks can retry before the daily interval.
- Sync no longer drops a Keep/Discard answer or runs a redundant pass after
  applying remote changes.
- Full-screen images fade in at their final size instead of scaling through an
  intermediate size.

## 0.7.3 — Reliability and recovery fixes (build 12)

- Reuse the restored Google session on resume instead of repeatedly starting
  account restoration.
- Preserve phone-only API keys when enabling encrypted sync, suspend key sync
  throughout Drive deletion, and close authenticated clients after each use.
- Keep episode/season external IDs attached to their identity during
  renumbering and sync. Sync format 4 remains readable by this version from
  older files; older applications must update before syncing new files.
- Refresh search and recommendation exclusions when their inputs change;
  enforce Unicode note limits and retain drafts after failed saves.
- Show retryable startup failures, exclude non-portable secure preferences
  from Android backup, and explicitly repair corrupt Drive mains from a copy
  while preserving backups and encrypted keys.
- Bound file/Drive imports and move sync encoding/decoding off the UI isolate.
  Reconcile architecture, recovery, privacy and retention documentation.
- Record the audit, resolution coverage and remaining physical-device checks
  in `docs/reviews/2026-11-02/README.md`.

## 0.7.4 — Samsung background-resume workaround (build 13)

- Request layout again on the Flutter surface after returning to the app or
  regaining window focus on Samsung Android 14. This targets a black screen
  reported on S23 after about five minutes in the background; immediate
  returns and the Nothing Phone were reported unaffected.
- Delay the request by 100 ms, cancel it when leaving the foreground or
  destroying/replacing the surface, and check focus/attachment before running.
  Other Android versions and manufacturers retain their existing behavior.
- Document the upstream evidence and physical-device validation procedure in
  [Android troubleshooting](docs/android-troubleshooting.md). On 2026-11-03 the user confirmed the signed 0.7.4
  build works after testing with the affected friend. No affected-device logs
  were captured locally, so the exact upstream cause is still inferred.

## 0.8.0 — People search and filmography (build 14)

- Search for actors, directors and other filmmakers in a dedicated People
  mode. Results show portraits and known-for titles; returning from a profile
  preserves the query and results.
- Filter a person's filmography by acting, directing, production, writing,
  music, camera and other work. Each category counts unique titles and shows
  the relevant jobs, including multiple roles on the same film or series.
- Keep the current Discover design in both themes, with wrapping role filters
  and English/Russian labels. Regression tests cover parsing, role grouping,
  pagination, stale responses, large text and navigation. The user confirmed
  the signed test build works on a connected Samsung Galaxy S23.
- No database or sync format changes; sync compatibility remains at format 4.

## 0.8.1 — Search history and quiet Drive sync (build 15)

- Reopen recently selected films and series from a dropdown below Discover's
  search field. Entries show a poster, title, media type and year.
- Keep the latest 20 opened search results across app restarts; opening the
  same title again moves it to the top. Queries themselves are not saved.
- Remove individual entries or clear history. History stays on the device
  and is excluded from exports and Google Drive sync.
- Keep automatic Google Drive sync without showing Google's sign-in window
  on each launch. Reuse the selected account through noninteractive Drive
  authorization; request another sign-in only through the settings button
  when permission needs renewal.
- Show full-screen photo previews at their final display size immediately,
  avoiding the small-photo flash before the higher-resolution image loads.
  This also applies to posters, episode stills and cached offline covers.

## 0.8.2 — Richer title cards (build 16)

- Restore the keyboard when returning from the background if it was open.
- Colour personal and source scores by their value, in both themes.
- Show world premiere dates, production countries, movie budgets and
  worldwide box office in dollars.
- Add a subtle poster-coloured background to title headers.
- Browse other films in a franchise and similar films/series from a card,
  with Back returning to the previous title.

- Refine score colours: 4–6.5 inclusive is amber, lower scores red, higher
  scores green. Use muted violet for general controls.
- Put release dates, countries and finances beside the poster, and make
  poster-coloured headers more visible.
- Scroll through all titles in three clearly separated calibration groups.

## 0.8.3 — Reliability and performance (build 17)

- Preserve successful source ratings when an older API-key request fails,
  and keep old request statuses from replacing the current card's state.
- Recover from damaged TMDB cache entries and unreadable service responses;
  keep concurrent cache writes from corrupting each other.
- Retry Google initialization after a transient failure without restarting
  the app, and show initialization failures through the sign-in UI.
- Report failed imports instead of leaving an unhandled storage error.
- Give Discover shelf captions enough room with larger text and sort long
  episode numbers numerically.
- Omit invalid numeric source fields and out-of-scale ratings.
- Avoid hashing complete sync rows when their versions already determine
  the winner. The file format and merge ordering stay unchanged.
- Expand regression coverage and validate version tools in CI. Record the
  size/performance investigation and its remaining work in
  [docs/optimization.md](docs/optimization.md).

## 0.8.4 — Smaller builds and less repeated work (build 18)

- Load watchlist entries without reading unrelated ratings, notes or snapshots;
  preserve grouped seasons and offline selection conflicts.
- Reuse successfully localized saved titles for up to a day, refresh changed
  snapshots and retry offline failures without repeatedly decoding every card.
- Suspend catalog work while backgrounded; cancel obsolete refresh timers and
  stop extra source lookups and pacing delays when no request is needed.
- Bound decoded full-screen image memory while retaining paging and zoom;
  reuse successful poster colours when cards reopen.
- Reduce the universal APK by separating debug information, preserving all
  supported architectures and retaining matching symbols separately for crash decoding.
- Remove unused icon and JSON generator dependencies. SDK, database schema,
  sync compatibility and signing certificate remain unchanged.
- Document the completed optimization work and its measured limits in
  [docs/optimization.md](docs/optimization.md).

## 0.8.5 — Library insights, favourite people and recommendations (build 19)

- Show recent-title history only from empty Discover search, keeping active
  queries and results unobstructed when the search field is focused again.
- Group the default ratings list by the local day of the latest score change.
- Explore all-time statistics through score, genre, decade and people lists,
  personal discoveries and disappointments, source preference agreement,
  author reliability, creative pairs and breadth of taste.
- Favourite people across all their roles, sync them through Drive and include
  them in backups; browse favourites, frequent contributors and popular people.
- Load people statistics gradually from an evictable cache while the screen
  remains usable. The local schema is version 2 and the sync format is version 5;
  older devices must update before syncing the new format.
- Personal recommendations now combine the full rating library, favourite
  people across all their roles and TMDB discovery, with equal familiar and
  exploration slots and short explanations.
- Choose from a separately ranked watchlist and browse favourite-people work
  or something different in the existing poster-shelf design.
- Hide Discover suggestions with Not interested, undo the action or restore
  hidden suggestions on the device; ratings and watchlist entries are preserved.
- Keep large recommendation and people-statistics calculations off the
  interface thread; reuse unchanged sources and combine rapid loading updates.
- Avoid recalculating the whole people library when adding a favourite;
  update favourite buttons only when their own person changes.
- Build expanded people statistics as they scroll into view and keep decade
  lists usable while detailed statistics are still being calculated.
- Pause new optional catalog enrichment while the app is backgrounded.
- Restore the last saved hidden-title selection if overlapping preference
  writes fail.

## 0.9.0 — Floating navigation and people browsing (build 20)

- Switch tabs with a floating glass selection that follows horizontal drags
  together with the screens. Keep the classic bar through Settings and leave
  enough space for the final list items above either navigation style.
- Close recent-title history when clearing the search query.
- Switch between Films and People with a glass slider the size of the search
  field, translating the content as it moves and retaining the query.
- Show the first 20 actors on title cards and open the complete cast from
  the cast heading. Include series actors from earlier seasons and guest
  appearances through TMDB aggregate credits.
- Give person profiles a fixed violet header frame and a centered favourite
  button. Double-tap shelf portraits to add or remove favourites, with a brief
  heart animation, confirmation message and translucent saved-heart badge.
- Use the same complete series/season credits in people statistics and
  recommendations as on title cards. Preserve every aggregate crew profession
  and refresh the previous incomplete derived-credit cache.
- Retry external-rating refresh after a device clock correction instead of
  treating future-dated cached ratings and failures as fresh indefinitely.
  Resume automatic Drive sync when its last-sync timestamp is in the future.
- Inspect cache-file ages asynchronously during startup cleanup, keeping
  filesystem metadata reads off the UI isolate's synchronous execution path.
- Apply Drive changes using the transaction's existing row snapshot instead
  of rereading every work, rating and watchlist entry. Avoid hashing identical
  row payloads and load only keys when pruning unreferenced snapshots.
- Wrap API-source headings and required/optional labels on narrow screens
  with large text in both English and Russian.
- Freeze the rating reel while saving, including an active fling, so the
  visible score and retry draft keep the value being persisted.

## 0.9.1 — Reliability and smoother resume (build 21)

- Keep the rating editor usable if loading optional calibration comparisons
  fails, preserving the note draft and any previous comparison result.
- Preserve Discover recommendation sections when returning from the
  background. Keep completed loads and resume interrupted passes using their
  existing candidates instead of briefly publishing empty shelves. Refresh the
  daily plan when returning on a different day.
- Avoid restarting fully loaded people analytics on every resume.
- Mark future-dated cached source ratings as stale consistently with refresh.
- Ignore superseded calibration replies even when the selected score returns
  to the same value while an older lookup is still pending.
- Make manual update checks bypass a concurrent automatic check that was
  skipped by the daily throttle, while still sharing real in-flight requests.
- Reject incomplete or malformed Drive file metadata as a recoverable sync
  failure instead of accepting empty concurrency markers or throwing raw errors.
- Keep fully tied ratings in deterministic order, including libraries imported
  with identical score-change timestamps.
- Allow opening and saving a rating when only the optional calibration
  threshold query fails; retain normal reporting of persistence errors.
- Require the expected probe response before marking an API key verified;
  arbitrary JSON with HTTP 200 is not sufficient.
- Keep navigation, language and theme choices usable on narrow screens with
  large text by placing their wrapping dropdowns beneath the labels.
- Omit impossible calendar dates instead of silently displaying another date
  produced by date normalization.

## 0.9.2 — Stable shelves and scrolling (build 22)

- Keep Discover shelves steady during vertical and horizontal scrolling,
  applying the latest feed when the gesture and its fling finish.
- Show the first useful recommendation batch promptly, then publish the
  completed pass instead of reshuffling shelves after every catalog response.
- Preserve each shelf's horizontal position and visited content when scrolling
  away and back, including people shelves.
- Share personal-score badge data across posters, avoiding a separate database
  query and asynchronous badge reload for every newly visible tile.
- Update people-index progress independently of the shelves, avoiding repeated
  sorting and rebuilding of all people rows just to change a loading counter.
- Keep visited title-card sections alive until the card closes, preserving
  loaded source ratings, related titles and editor state during scrolling.
- Reserve recommendation-caption space in loading placeholders and preserve
  previously loaded shelf data if a refresh fails.
- Keep title-header geometry fixed while the poster colour and border load.
- Swipe across the root pages to move between Discover, My ratings, Watchlist
  and Stats in both navigation styles. Horizontal shelves keep their gestures;
  nested cards keep their own navigation.
- Ignore note-only and external-rating updates when rebuilding recommendation
  taste profiles, preventing background refresh from reranking unchanged tastes.
- Parse large catalog JSON and encode/decode large response-cache envelopes in
  background isolates instead of blocking the interface thread.
- Remove redundant backdrop filtering over opaque navigation surfaces while
  retaining the glass selection's gradient and border.
- Keep intermediate actor-index batches from repeatedly rebuilding recommendation
  tastes and reranking all shelves during background enrichment.
- Lay out film and people shelves with fixed-width slots and stable keyed tile
  mapping, retaining mounted tile state when the feed order changes.
- Share concurrent requests for the same TMDB endpoint and parameters, including
  cache decoding, and release failed requests so retry remains possible.
- Keep actor-loading progress from rebuilding all statistics and move large
  cast/actor-director pair calculations to workers even for small libraries.
- Build large recommendation taste profiles in a serialized worker while keeping
  the previous profile visible. Newly rated titles are excluded immediately.
- Preserve expanded biographies when scrolling through a person's filmography.
- Batch ancestor snapshot reads so large season/episode libraries cannot exceed
  SQLite parameter limits when opening the ratings list.
- Keep external-rating panel geometry stable as loading captions arrive, and
  size numeric readouts and cells for large system fonts without overflow.
- Decode/encode large derived actor-credit cache payloads in background workers,
  including validation of damaged cached bodies.
- Show an already loaded personal rating while the card's individual query is
  pending, while honoring a confirmed deletion immediately.
- Reuse prepared filmography groups and combined credit ordering when switching
  a person's role filter instead of rebuilding both lists on every selection.
- Avoid rebuilding recommendation inputs when only snapshot freshness changes
  or the watchlist query repeats the same data; keep sync timestamps intact.
- Prepare preferred people, genres and recommendation seeds together with the
  taste profile so deferred sorting does not return to the interface thread.
- Prepare large rating-list filters, ordering and day groups in a serialized
  worker, retaining the previous list and ignoring superseded requests.
- Prepare statistics summaries, medians, source comparisons and people ordering
  outside the widget build; retain coherent previous summaries during updates.
- Prepare large initial filmographies in a worker, reusing the resulting role
  groups and combined credits across filter selections.

## 0.9.3 — Pair calibration and fresher recommendations (build 23)

- Add pairwise calibration to movie statistics. Choose which film you enjoyed
  more or that both were equally enjoyable; reveal existing scores after the
  answer and apply a suggested correction only after confirmation.
- Select pairs using conflicting preference chains, close scores, review
  coverage, shared genres and release years. Limit completed comparisons to
  five per local day; skipping does not spend the allowance.
- Sync comparison history through Drive and include it in exports and backups.
  Keep history when restoring an older file, and reject stale or duplicate
  answers before changing scores. Schema 3 and sync format 6 retain reading
  of earlier files; older apps must update before syncing the new format.
- Refresh personal recommendation inputs daily: rotate rated-title seeds,
  favourite and learned people, secondary genres and discovery pages while
  keeping the existing request budget and stable scrolling. Retain the last
  useful session candidates if a daily refresh fails without new results.
- Restore side-by-side labels and choices for navigation, language and theme
  in Settings at normal text sizes, with a vertical layout for large text.
- Consolidate documentation into primary topic references, a documentation
  index and separate historical validation records.

## 0.9.4 — Clearer statistics and automatic rating catch-up (build 24)

- Shorten the Russian watchlist tab label to fit larger interface scales.
- Exclude undated and invalid-dated titles from recommendations, including
  watchlist suggestions. Explain pending or unknown releases on title cards
  and require a valid past or current release date before rating any title kind.
- Distinguish planned series and series in production from ongoing series.
- Preserve vertical position on People while background indexing temporarily
  clears or partially replaces contributor shelves; publish confirmed changes
  after loading instead of collapsing the list and jumping to the top.
- Hide floating and classic bottom navigation on title, person and full cast
  pages; restore it when returning to a main tab.
- Open full-screen covers and person photos above the tab shell so navigation
  cannot overlap the image viewer.
- Keep automatic sync disabled after a failed preview of a newly selected
  Google account, and finish the previous account's upload before switching.
- Clear the previous API key's verification before writing a replacement so
  interrupted secure-storage writes cannot mark an unchecked key as verified.
- Retry optional background rating refresh on its normal schedule after a
  transient local failure instead of stopping updates until the app restarts.
- Show recoverable sync status when local metadata cannot be read or written,
  including failure to save the error marker itself, and allow a later retry.
- Reject TMDB detail responses for another title, person or season before
  caching or displaying them, and refetch mismatched cached responses.
- Reject imported event dates outside the supported calendar range before
  they can break rating groups or date labels.
- Report failed rating deletions and watchlist changes on title cards, retain
  the saved data and allow retry; ignore failures of optional snapshot refresh.
- Keep failed watchlist removal and Undo recoverable without uncaught errors,
  including completion after the original screen has closed.
- Treat invalid calendar release dates as unknown when deciding whether a film
  can be rated, rather than normalizing them into future dates.
- Keep renumbering choices retryable after a failed write and disable repeated
  Move/Keep taps while the chosen rating or season-watchlist change is saving.
- Serialize recent-title history writes and retain the last saved history when
  preferences fail, without interrupting title opening or later history changes.
- Offer Retry when ratings, watchlist or statistics cannot load local data,
  replacing an endless loading indicator while retaining useful prior data.
- Keep optional localized-title refresh retryable after a local storage error,
  without unhandled background exceptions or changes to scores and notes.
- Recheck renumbering source identity inside the transaction, so a stale
  Move/Keep choice cannot move another title's rating or overwrite its snapshot.
- Reject overflowing version timestamps in sync files and encrypted settings;
  advance local versions with checked arithmetic so an edit cannot wrap negative.
- Discard malformed optional profile-image paths before saving favourite people,
  so missing artwork cannot make their sync file unreadable.
- Reduce recommendation-update pauses in large contributor libraries by sharing
  repeated immutable credit data before worker transfer, preparing it in small
  interruptible batches and reusing it while the credit index stays unchanged.
- Use the same prepared credit graph for large people-statistics workers,
  retaining every contributor and drill-down title while reducing transfer pauses.
- Wait for a known saved-rating state before offering a blank editor, with
  Retry on failed reads, so slow loading cannot hide an existing score or note.
- Keep full snapshot-refresh versions increasing after a device clock correction,
  preserving a confirmed renumbering identity when older snapshots are merged.
- Preserve the original rating dates when correcting scores through pair
  calibration, keeping films in their existing date groups.
- Shorten the pair-calibration daily hint to the comparison allowance.
- Automatically catch up on missing Kinopoisk ratings with up to 150 daily
  requests, filling gaps before refreshing known values and preserving a
  reserve for title cards. Newly rated titles wake the queue immediately;
  unfinished work continues on later days and updates source comparisons.
- Replace the long statistics feed with a compact overview of rated titles,
  average score, highly rated posters and favourite genres. Open score
  distribution, genres/decades, actors/directors and public-score comparison
  on focused detail pages, using plain-language comparisons and fewer metrics.
- Put Compare films directly below the statistics summary, before the poster
  shelf, and highlight it as a violet primary button so the pair-comparison
  action is easy to find on entry.
- Use Discover's sliding inset control for the four statistics title kinds,
  with tap and drag selection and adaptive labels.
- Group score review in its own violet panel matching person headers, with
  a heading and explanation above the Compare films button.
- Keep the statistics overview's scroll range stable as sections enter view,
  removing height-estimation corrections during scrolling.
- Preserve Russian Cyrillic glyph forms in English mode for saved titles,
  names and notes instead of using the font's default Bulgarian forms.
