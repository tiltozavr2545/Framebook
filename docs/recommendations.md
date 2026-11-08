# Personal recommendations

Discover keeps the existing horizontal poster shelves and theme. Personal
rows are **For you**, **What to choose from my watchlist**, **Work by favourite
people** and **Something different**. Editorial trending, cinema and all-time
best rows remain below them. There is no backend, new account or additional
API key; scoring happens on the device.

## Taste signals

`app/lib/data/recommendations/profile.dart` builds a profile from every live
rating, including low scores. Films contribute independently. A series
contributes once: its own score takes precedence; without one, average its
season scores, using the mean of rated episodes where a season has no score.
Seasons have equal weight, so a hundred episode scores cannot outweigh the
rest of the library. Parts inherit their series' genres and year. Imported
rating timestamps never weight preference or seed selection.

Preference combines 65% absolute distance from 5.5 and 35% distance from the
user's average, normalized by 4.5. Genres, people and decades accumulate these
signals with three neutral prior observations, reducing overconfidence from
one rating. Multi-role credits count once per person and title. Missing
credits are unknown, not negative evidence. Credits use the same evictable
cache and identity checks as people statistics; no cast/catalog enters the
permanent database or sync file.

## Candidate retrieval

`candidates.dart` retrieves from TMDB only:

- Up to two high-scored (7+) films and two series, plus one low-scored (≤4)
  seed of each kind. Daily rotation visits all eligible seeds in score/key
  order. The second positive seed favours different genres among the next
  twelve eligible titles. Recommendations associated with a disliked seed
  reduce its candidates' familiar score.
- Combined film and TV credits of up to eight favourite people, rotated
  daily for larger lists, plus up to two people with positive evidence from
  at least three rated works, also rotated daily. Learned people are selected
  after the current credits batch finishes to avoid restarting retrieval on
  every credit.
  Every profession contributes: acting, directing, writing and other crew
  work. Each filmography contributes its 60 highest-prior released titles,
  plus any matching watchlist entries.
- Discover results for the strongest genre and a rotating second genre with
  positive evidence per kind, plus one unfiltered pool per kind and the
  existing shared trending response. Discover uses popularity ordering,
  a minimum public score of 6, at least 50 movie / 25 TV
  votes and a release-date upper bound of today. Each day selects one of the
  first five pages instead of always retrieving the first page, using the
  documented `page` parameter for [movies](https://developer.themoviedb.org/reference/discover-movie)
  and [TV](https://developer.themoviedb.org/reference/discover-tv).

Rotation uses the local calendar day. Opening the app or returning from the
background on another day refreshes the retrieval plan; there is no midnight
timer and no shuffle on every navigation or scroll. The same library and day
produce the same inputs, including after restarting the app. A small library
may reuse seeds, and overlapping source results can still recommend the same
titles. Rotation changes retrieval inputs, not the taste model or saved scores.

At most 23 retrieval jobs run per pass with three workers, an eight-second
per-job timeout and 45 seconds of scheduling. Successes are streamed into
the screen before the pass finishes. Individual failures do not discard
other results; cancellation stops scheduling and publishing. Later jobs can
still use stale HTTP responses after an offline error. The separate credits index uses the limits in
[analytics](analytics.md#credit-enrichment). Requests send catalog IDs
and filters; scores, notes and the private library are never uploaded.

Completed retrieval jobs and in-flight requests are reused in a 64-entry
session LRU scoped to the catalog client, language and day. Person selections
also include watchlist membership in their identity. Failures are evicted so
Retry can try again. Editing favourites reuses unchanged seed, discovery and
person jobs. Candidate and credit updates are published in 100 ms batches,
with an immediate first useful candidate result and an unconditional final
snapshot. Foreground state gates new recommendation and credit requests;
resume can continue incomplete enrichment. Completed recommendation loads and
fully populated credit indexes remain intact across foreground changes.
If a new daily pass fails without retrieving any candidates, the last useful
session pool remains visible until a later retry succeeds. Disk HTTP caches
retain their existing lifetimes and stale-response fallback; a never-loaded
rotating source cannot supply offline data.
Interrupted candidate loads retain their current sections and resume from the
same plan's session snapshot, avoiding an empty intermediate shelf batch.
This snapshot is scoped to the catalog client and is never synced or persisted.
Already-started HTTP requests may
finish, but obsolete recommendation passes cannot publish their results.

## Ranking and explanations

`ranking.dart` merges candidates by typed natural key and combines their
provenance. Familiar ranking combines linked seed preferences, genre fit,
favourite/learned people, decade affinity and a small public-quality prior.
Public scores shrink towards 5.5 with 100 prior votes; a single 10/10 vote
cannot dominate a widely rated title.

Exploration favors genre novelty relative to the positive seeds, public
quality and some personal fit. For you alternates familiar and exploration
objectives 1:1, with at most one extra familiar slot for an odd result count.
This is a balanced allocation of ranking objectives, not a promise that half
the finite candidate pool belongs to previously unseen genres. Greedy
re-ranking penalizes recent genre and person repetitions. Ties use natural
keys; repeated requests with the same candidate data are stable.

Rated films and series with any rated parts are excluded from discovery.
Watchlisted films and series with watchlisted seasons live in the separate
watchlist row instead. That row ranks locally available entries, including
seasons, and remains usable without retrieval. All recommendation rows require
a valid release date on or before today; undated, invalid-dated and future
titles remain in the watchlist but are excluded from suggestions. It never
edits the watchlist.
Hidden titles are excluded.
Dedicated rows may reuse a title from For you; each row deduplicates its own
items.

Shell listener ownership is described in
[client architecture](client-architecture.md#lifecycle-and-rendering).

Reasons describe actual evidence: a named liked title, a favourite person,
a positively rated contributor, preferred genres, exploration or membership
in the watchlist. No predicted personal score or probability is displayed.

Ranking precomputes candidate scores and genre sets and computes row-level
diversity context once per slot. Pools exceeding 100 candidate/watchlist
entries or 80 taste signals run in an isolate after an 80 ms coalescing delay.
One ranking worker runs at a time, skipping superseded queued inputs. The
previous result can remain visible while the current one is calculated;
hidden/rated titles and watchlist removals are filtered immediately. Small
pools use the same pure ranking function synchronously. Progress-only updates
do not rerank an unchanged candidate list. These are scheduling boundaries,
not a measured guarantee about phone frame times.

Large taste-profile workers reuse a prepared credit graph for the current
published credit-index snapshot. Preparation shares immutable person records
only when ID, role, name and photo path all match, preserving every row and its
order. It yields after each 512 credits and stops superseded work. This reduces
isolate-transfer and allocation pressure without dropping contributor metadata
or repeating preparation after score changes alone. Small profiles retain the
existing synchronous path. A bounded sample of up to 16 evenly spaced credits
per work bypasses the full sharing table when fewer than 5% repeat, avoiding
extra allocation for almost entirely unique contributors. Host evidence and
its limits are recorded in the
[0.9.4 review](reviews/0.9.4/README.md#host-responsiveness-measurements).

## Not interested

The poster's menu hides the title across Discover shelves. A snackbar offers
Undo; the For you heading's hidden-items action can restore all hidden titles.
Hiding a series also hides its seasons from recommendation rows. Search,
ratings and the watchlist remain accessible and unchanged.

Hidden-title storage is defined in the
[data model](data-model.md#outside-the-database). Writes are serialized;
failures are reported and the latest optimistic change rolls back to the last
successful stored set, including overlapping failed writes. Hiding is not a
low rating and never trains the taste profile.

## Verification scope

Regression coverage is indexed in [testing](testing.md#automated-coverage-by-behavior).
The rules and scheduling thresholds above do not establish a measured
improvement in relevance or Android frame times; those require empirical checks.
