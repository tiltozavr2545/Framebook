# Correctness and responsiveness review for 0.9.5

Started on 2026-11-08 at the user's request to repeat review, repairs and
verification until stopped. The review targeted the unreleased 0.9.5+25
without a version bump. Commit and publication were authorized separately
after the review and documentation work finished. This report records confirmed
findings and evidence, not a claim that all remaining defects are known.
The user ended new review work on 2026-11-08. Existing repairs and final automated
verification are complete; physical-device acceptance remains separate.

## Watchlist mutations loading the entire sync state

Adding even a movie called `SyncStore.read()`, loading all rating notes,
snapshots, favourite people and comparison history. Series/season removal did
the same to preserve selection fences; choosing a whole series repeated this
work for each removed season. The regression with twelve seasons read the
same unrelated rating note fifteen times during add/add/remove operations.

Mutations now read only live TV watchlist rows and persisted selection fences.
Movie additions skip these reads. A group selection preserves legacy implied
fences once before removing opposite entries. The same regression reads no
unrelated notes and checks retained selection history after removal. Explicit
replacement's final fence save also uses this selective reader.

## Parts averages loading episode notes

The series/season average query returned full joined rating/snapshot rows,
including notes, and calculated the result in the interface isolate. A fixture
of one hundred rated episodes returned one hundred full rows for one average.

The reactive query now groups by title kind and calculates count/average in
SQLite. At most a season and an episode aggregate return to Dart; rated seasons
still take precedence over episodes. The regression checks the exact result,
absence of notes and bounded result rows.

## Reel comparison request buildup

Every score change immediately started a new comparison query, even while a
previous one remained blocked. Discarding stale replies protected presentation
but left all database work running. Three rapid changes started three additional
queries in both immediate and blocked-result regression fixtures.

The editor now debounces changes by 100 milliseconds and serializes lookups
through the existing latest-input worker. Revisions invalidate an old result
as soon as the score changes, before the debounce expires. Obsolete queued
scores are skipped. Disposal and saving cancel deferred work. The regression
for returning to an earlier score now checks that the earlier pending result
is discarded before the new request for that score publishes.

## External-rating storage failures

The card controller listened to its cache stream without an error handler and
started an unawaited refresh without containing database exceptions. Injected
read failures produced two uncaught errors and a loading timeout; an injected
write failure escaped too and offered no retry.

Stream and refresh failures now have separate local status, so a later stream
event cannot hide a failed write. Cached values remain visible, loading markers
stop and the panel offers Retry. Rebuilding only that controller restarts both
paths without leaving the title or changing user ratings.

## Unchanged library emissions

Drift invalidates queries at table granularity. A TMDB score for an unrated
film or a TMDB-only update to a rated title republished the entire rating
library despite no joined Kinopoisk/IMDb changes. Sync timestamps likewise
republished an unchanged watchlist. Both new regressions observed a second
identical library event where only the initial event was expected.

Both streams now compare complete visible values before publication. Rating
notes, ancestor snapshots and joined source values remain observable, as do
watchlist selection fences. The stream helper resets its previous value after
an error, forwards cancellation and keeps broadcast subscriptions independent.
This removes downstream widget/worker churn; it does not eliminate SQLite's
underlying table-level invalidation or query cost.

## Source requests after card closure

A blocked Kinopoisk request continued into an OMDb lookup after the card's
provider was disposed, spending another quota request. The regression observed
one OMDb lookup after closing the only listener. Card refresh now supplies its
build/disposal cancellation guard to the service. In-flight work may complete
and populate the cache, while subsequent sources stop without spending budget.

## Repeated search pages

Search accepted a page-one response for a page-two request and cached it under
page two. The controller then retained page one as its progress marker, making
automatic tail loading able to request the same cached page indefinitely.
Both title and people client fixtures reproduced acceptance of this response.

The catalog checks pagination before accepting cached or network responses.
Wrong pages do not enter the cache, valid stale pages remain usable and the
controller independently rejects a page that does not advance as requested.
A controller regression retains prior results, stops automatic loading on this
error and verifies successful explicit retry.

## Repeated editor opening

The Rate/Edit actions remained enabled while querying saved state and comparison
eligibility. Two rapid taps started two reads and could stack two editors. The
regression observed two threshold reads before either completed.

Opening is now gated from the first tap until the sheet closes, with edit/delete
controls disabled while a draft is opening or active. The regression releases a
blocked query, checks only one editor exists and verifies reopening after
canceling. Nine focused opening/loading/startup/update tests passed.

## Root subscriptions and key actions

The application root watched entire key-vault and update-check states although
it rendered neither. These subscriptions now keep the services alive through
listeners; panels and banners own their reactive rendering.

API-key keyboard submission bypassed the button's checking state and could
start two probes, spending two quota requests. Removal had no pending-operation
guard either. A per-key operation gate now covers checks and removal from the
first callback through persistence, including repeated callbacks before a frame.
The keyboard regression observed two probes before repair and checks that only
one request is spent and its verified key is saved afterward.
The focused key-action, layout, storage and validation pass passed 21 tests.

## People-role sorting during widget builds

People discovery filtered and sorted the entire contributor list for each
profession every time it rebuilt, despite displaying only twenty people per
role. This work now runs when constructing analytics, using its existing
background worker above the documented thresholds. Widgets traverse only the
bounded prepared shelves. Full contributor and role profiles remain available.

Fourteen focused analytics/real-transfer/scroll/layout tests passed. The
standalone host benchmark used 30,000 contributors with three roles each,
two warmups and five measured samples, without another test/build workload:

| Preparation formerly performed during rebuilding | Median | Samples (microseconds) |
| --- | --- | --- |
| Filter/sort roles and take twenty per shelf | 40.463 ms | 43422, 42717, 40131, 40029, 40463 |
| Traverse precomputed shelves for widget input | 0.040 ms | 80, 40, 570, 38, 40 |

The fixture checks identical role membership/order and retains all 30,000 people.
The second measurement excludes worker-side preparation, which now happens
when analytics changes. These are host CPU measurements for an extreme input,
not total widget-build times, Android frame times or a prediction of FPS.

## Large sync computations on the UI isolate

The codec already used isolates, but full-state merges, remote-behind checks
and stale-edit review still ran on the interface isolate. They can repeat
several times during a sync pass, import preview or replacement. Moving only
the final merge left normalization inside stale-review checks on the UI too.

`sync_compute.dart` now delegates these full-state computations above 2,000
combined records, counting every row/register type. Small inputs stay local.
The original pure algorithms remain unchanged. Detached values cross isolate
boundaries; consent decisions and writes retain their transaction boundaries.
No database, account object or provider reference enters a worker.

Real-worker regressions check byte-identical serialized state across scores,
notes, snapshots, favourite people, comparison history, fences and deletion
registers. Dropped-key sets and stale-consent fingerprints match the original
functions, including cases where the last sync acknowledges the local edit.
The store suite checks a 600-title application through this path and stale
consent with 2,001 deletion registers, followed by Keep preserving the note.

Host scheduling measurements include input/result transfer. Total operation
time can increase because spawning/copying adds overhead; reducing main-isolate
blocking is the purpose.
The final sequential host run used two warmups and five samples per case:

| Workload | Inline median total / scheduler gap | Worker median total / scheduler gap |
| --- | --- | --- |
| Merge and remote-behind | 23.676 / 23.676 ms | 49.920 / 13.971 ms |
| Stale-edit detection, merge and remote-behind | 39.230 / 39.230 ms | 69.017 / 13.255 ms |

Guarded inline gaps (microseconds): 45663, 42365, 39230, 38746, 39099.
Guarded worker gaps: 20230, 13178, 9948, 13255, 14375.
Merge-only inline gaps: 29254, 24975, 22855, 23676, 23402.
Merge-only worker gaps: 13933, 23590, 5473, 14788, 13971.
Transfer/GC can still exceed a frame budget; these host scheduling gaps do not
measure Android frames. Both benchmark cases passed their data checks.
SQLite row materialization, application and some compaction preparation still
incur local work; this is not a complete Android frame-time guarantee.

## Follow-up: comparison after a failed save

Re-review of the queue repair found that saving correctly canceled deferred
comparison work, but an immediate write failure never resumed that comparison.
The draft survived while the panel could retain another score indefinitely.
The new regression reproduced only the initial score lookup instead of the
selected-score lookup after a failed save.

Failed saving now resumes a missing selected-score comparison after unlocking
the editor, through the same serialized worker. Already matching comparisons
are reused. The note and chosen score remain in the draft.
The queue/editor follow-up pass passed twelve tests.

## Preference persistence failures

Theme, locale, navigation style and comparison-source controllers updated memory
before writing preferences, ignored a false storage result and did not serialize
overlapping changes. Thrown write failures escaped UI callbacks. The initial
failure regression observed a successful future despite rejected persistence.

Each preference now serializes writes and tracks its last successful value.
A failed latest write rolls back that selection, while an older failure cannot
replace a newer optimistic choice. Source rollback preserves other session
filters/sort controls. A shared UI action reports failure without exposing
storage details, and subsequent changes can retry normally.

Thirty focused preference/layout/encrypted-sync tests passed, covering false
results and exceptions, queued writes, later successes and source-filter
preservation. An additional disposal regression checks late failed completion.

## Insight invalidation

People aggregates watched every library emission, including refreshed IMDb/KP
scores that they never consume. A selected movie view also recomputed when only
a series changed. The regression reproduced a new insight result for an
external-score-only update.

Per-kind inputs now compare local rating and snapshot rows while excluding
external scores and snapshot-only version timestamps. A follow-up regression
also reproduced unnecessary preparation after an identical card refresh.
Source refreshes and other kinds preserve the existing result;
score, title, poster and note edits still produce current drill-down content.
Public-score comparison retains its separate live statistics input.
The focused insight, worker, recommendation and people-scroll pass passed
nineteen tests.
The timestamp follow-up and scroll-worker pass passed seven tests.

## Pair preparation recovery and current snapshots

A failed pair worker displayed both a load error and the claim that no suitable
pairs remained, with no Retry. A separate regression showed that a valid current
pair retained its old title after a local snapshot edit.

Selection failure now has explicit retryable state and suppresses the completed
message. A still-valid pair adopts current local rows while preserving the
unsaved preference and original selection reason. Neither action saves a
comparison or spends the daily allowance.
The focused screen, selection and transactional-store pass passed 27 tests.

## Unknown card watchlist membership

Cards treated a pending or failed membership read as false and enabled Add.
For an already-listed title this could appear to do nothing, while read failure
offered no recovery. Regressions for movies, series and seasons reproduced an
enabled toggle before any membership result.

The toggle now waits for known membership; failed initial reads show Retry.
The independent Rate action remains available for eligible titles. Rated cards
do not subscribe to unused membership queries. The regressions also verify
that the known listed action removes the saved entry after loading/retry.
The focused card/action/loading pass passed 44 tests.

## Update dismissal persistence

Dismissal hid the banner before storage finished, ignored false results and
allowed thrown persistence errors to escape its UI callback. The regression
observed the banner disappear while its write was still pending.

The controller shares a pending dismissal, checks successful persistence and
only then hides the matching notice. A newer notice remains visible if it
arrives during the write. The shared preference action reports failure and
keeps dismissal retryable. Tests inject false results and thrown errors, then
check retry and a newer release during pending persistence.
The focused banner/controller/update-check pass passed eight tests. The final
full run also includes the repeated-action assertion.

## Verification

Complete `make verify TEST_ARGS='--concurrency=2 --reporter expanded'` passes:

| Pass | Included repairs | Passed tests |
| --- | --- | --- |
| 1 | Selective watchlist actions and SQL part averages | 775 |
| 2 | Comparison queue, cache failures, unchanged streams, cancellation and search pagination | 791 |
| 3 | Opening guard, root listeners, people shelves and API-key action guard | 794 |
| 4 | Large sync workers, transactional application and exact stale-consent checks | 798 |
| 5 | Failed-save comparison recovery and serialized preference persistence | 810 |
| 7 (final) | Insight invalidation, pair recovery, watchlist membership and update dismissal | 821 |

Each pass skipped 22 opt-in screenshot scenarios and passed formatting,
analysis and version-script checks. Pass 3 formatted 242 Dart files unchanged.
Pass 4 formatted 246 Dart files unchanged. Pass 5 includes late preference
failure after disposal. The sixth full run caught the snapshot-timestamp
follow-up regression (812 passed, one failed); the repair passed the focused
seven-test insight/scroll run. The final run passed all 821 tests with 22
opt-in screenshot scenarios skipped, clean formatting/static analysis and
passing version-script checks. No source code changed after that run began.

The focused sync-worker, store, merge and controller suite passed 110 tests;
the additional store pass passed all four cases including large stale-consent
coverage. Earlier targeted
passes and reproduced failures are described with their findings above.
Documentation checks are recorded below. Device frame times, touch latency,
memory and energy remain unmeasured.

## Documentation consolidation

The finishing pass checked repository documentation for topic ownership,
current-versus-historical status, duplicate rules and local references.
The former `docs/optimization.md` moved to `reviews/0.8.4/README.md`;
Samsung investigation/build evidence moved to `reviews/0.7.4/README.md`,
leaving recovery and reproduction procedures in Android troubleshooting.
The review index and historical changelog links follow those moves.

The implementation plan keeps delivery status and pending acceptance only.
Testing keeps reusable commands, a compact benchmark index, scenario-to-test
mapping and device procedures; measured samples remain in review reports.
Device preference execution and large sync-worker scheduling belong to client
architecture, while source/cache rules, UI behavior and storage boundaries stay
in their primary references. The stale separate pending-release-notice description
was corrected. Public HTML pages and both API-key guides retain their audience
and language boundaries.

Final documentation validation resolved all 486 local file, heading and image
links across 37 repository Markdown files and two public HTML pages. Every
Dart test/benchmark reference in the current testing guide exists.
`git diff --check` passed. The guides were checked for internal consistency;
external provider registration pages and account-console state were not revalidated.

## Publication follow-up

After closing the review, the user requested committing all changes, pushing
them and publishing 0.9.5 with release notes following the previous release.
Version/build stays 0.9.5+25. Publication uses the signed universal-APK workflow
and the existing release certificate; notes describe user-facing changes,
installation, requirements and attribution. Authoritative assets and publication
status belong to the [release page](https://github.com/tiltozavr2545/Framebook/releases/tag/v0.9.5).
