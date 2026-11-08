# Stability review for 0.9.4

Review pass conducted on 2026-11-07–08 and closed after the requested repairs.
This review targeted 0.9.4+24 and did not include a release. Later repairs may
supersede individual findings; current rules belong to the
[technical references](../../README.md#product-and-technical-reference).
This record tracks confirmed findings, verification and measured limits;
it does not assert that the project has no remaining defects.

## Account selection after a failed Drive preview

The sync controller marked the Google session ready before reading the newly
selected account's Drive file. If that read failed while a previous account
was still selected locally, later automatic sync could use the new session
under the old selection without completing the first-merge confirmation.

Account selection now waits for the previous upload. Once Google accepts a
selection, the saved selection is cleared and automatic sync is gated until
the Drive preview succeeds. Failed previews preserve local data and allow
another sign-in attempt. Regression coverage checks blocked uploads, failed
previews, subsequent edits and successful retry in `sync_controller_test.dart`.
The current contract is in [sync](../../sync.md#first-sign-in-and-sign-out).
Account state is cleared before awaiting preference removal. A blocked-preference
regression checks that account-bound listeners already see a disconnected state
while the previous persisted selection is still being removed.

## Interrupted API-key storage

The key value and verification flag were written separately, with the new value
first. An interrupted second write could leave an unchecked replacement paired
with the previous key's successful verification.

Saving now clears verification before replacing the value. Interrupted writes
leave either the old value or an unverified replacement. A regression interrupts
each write boundary, reloads the store and checks successful retry in
`api_keys_test.dart`.

## Background refresh after local failures

The optional rating-refresh loop reset its active indicator in `finally`, but
let local exceptions escape its unawaited future. A transient database failure
therefore ended all later scheduled refreshes for that service instance.

The loop now catches exceptions for a failed pass and waits for the normal
interval before retrying. The lifecycle regression injects one executor read
failure and checks that the later pass still requests external ratings, with
no uncaught exception or timer retained after disposal.

## Local sync-metadata failures

Startup metadata reads and unexpected local exceptions during an automatic sync
escaped unawaited futures. Even a handled sync error could escape again when
writing its persistent error marker to the same unavailable database.

The controller now reports a recoverable failure in memory before attempting
to save the marker. Failure to persist that marker does not fail the operation
again. Startup and active-pass regressions disable metadata reads and writes,
then restore storage and verify successful retry with the local rating intact.

## Mismatched TMDB details

Detail parsing accepted any positive response ID instead of checking it against
the requested title or person. Season details similarly trusted the returned
number. A wrong successful response or a misplaced cache body could therefore
display and offer to rate another title under the requested route.

The catalog loader now validates detail identity before accepting either cache
or network data. Mismatched cached bodies are refetched, mismatched network
responses are not cached, and only a valid older response can serve as fallback.
The regressions cover movies, series, people, seasons and stale-card retention.

## Unrenderable imported event dates

The sync reader accepted any integer for rating dates and watchlist addition
dates. Values outside Dart's DateTime range could be committed successfully and
then throw while preparing rating day groups or formatting screen labels.

The reader now validates calendar event dates before application, including
comparison event dates. The boundary regressions cover positive and negative
out-of-range rating and watchlist dates through synchronous and isolate decoding.
Valid legacy files retain the same format and reading path.
An additional probe in a UTC−10 zone reproduced local-midnight construction
failure at Dart's exact lower bound. The date guard also reserves two days at
both limits so a timestamp cannot cross them during local calendar grouping.

## Card and watchlist persistence failures

Deleting a rating, toggling the card's watchlist button and updating its optional
snapshot could let storage errors escape unawaited UI futures. Watchlist-row
removal and Undo had the same problem; a late removal could also show a snackbar
through a disposed messenger.

User actions now report failure while preserving stored data and allowing retry.
Card mutation controls disable repeated taps while a write is pending. Optional
snapshot errors are contained. Watchlist Undo retains a retry action if restoring
the entry fails and checks messenger lifetime before showing feedback.

## Invalid dates and rating eligibility

The card's release guard normalized impossible dates with `DateTime.tryParse`
even though date labels already omitted them. An invalid future-looking date
could therefore hide the Rate action while displaying no release date.

The guard now uses the shared calendar validator. Regressions keep invalid
February/month values rateable and still disable rating a valid future release.

## Renumbering write failures

Move/Keep callbacks returned void and discarded their mutation futures, including
the conflict-resolution wrapper. Storage failures escaped without feedback, and
the same choice could be submitted again during the first transaction.

The shared notice now awaits each choice, disables its actions while saving and
reports failure without removing the question. Regressions fail and retry both
Move and Keep for ratings and watchlisted seasons, checking retained notes,
scores and identities as well as the final key.

## Recent-title persistence

Recent-title updates wrote preferences independently and ignored unsuccessful
boolean results. Thrown write errors escaped callbacks that opened cards or
removed history entries; optimistic state could disagree with a restart.

Writes now serialize, check their result and restore the last persisted state
when the latest draft fails. History is optional, so these failures do not
interrupt title navigation. Regressions block one write, queue a second one,
fail both by return value or exception and verify successful later persistence
through a new provider container.

## Local-library read failures

Ratings, watchlist and statistics read only the value of their async providers.
When the first local read or view preparation failed, null was interpreted as
loading and the screen could spin forever with no way to retry.

These screens now distinguish failed loading from pending loading. They show a
local-library error with Retry when there is no useful result, restart the
affected providers and keep previous results visible when available. Regressions
fail the initial stream for each tab, restore it and check that Retry reaches
the loaded empty state instead of retaining the spinner.

## Localized-title refresh failures

The foreground title-enrichment task handled catalog failures but allowed local
read/write exceptions to escape its unawaited refresh. It now contains those
exceptions and leaves incomplete work retryable on the next sync or resume.
Regressions inject both kinds of local failure, resume after restoring storage
and verify updated titles with unchanged ratings and private notes.

## Stale renumbering identity

Move prepared destination snapshots before checking whether the source was still
live, and did not require its current own TMDB ID to match the selected
destination. A stale choice after a concurrent deletion or identity adoption
could therefore alter an unrelated destination or move the wrong rating.

Moves now validate source liveness and identity inside the transaction before
any snapshot change. Rating moves also reject duplicate destinations and
cross-kind/series inputs. UI Keep choices supply the identities displayed in
the prompt and reject an intervening identity change. Regressions remove or
adopt another source identity before applying the stale choice and check that
no target rating, watchlist entry or snapshot is created.

## Version overflow

A standalone in-memory import probe reproduced a signed-integer wrap: the reader
accepted `updated_at = 9223372036854775807`, then editing changed it to
`-9223372036854775808`. The edit could subsequently lose against an older synced
version despite being the user's latest change.

Sync and encrypted-setting readers now validate version timestamps against the
representable millisecond range. Shared checked increment logic covers library
edits, watchlist fences, favourite people, replacement/restamping and encrypted
local snapshots. Exhausted versions fail without changing the transaction's
stored score, note or snapshot. Regressions cover import table variants, compact
metadata, secret snapshots, clock rollback and atomic failure at the last
supported version.

## Invalid optional favourite photos

Favourite persistence accepted any profile-image string, but the sync reader
required a relative path beginning with `/`. An empty, relative-without-slash or
absolute URL from catalog metadata could therefore produce a file the app
itself refused to read.

Persistence now drops invalid optional artwork and keeps the favourite. The
regression checks both live entries and removal tombstones through a complete
file roundtrip. All seven favourite-person tests passed after the repair.

## Unknown rating state and blank drafts

When both the individual rating query and the library snapshot were unavailable,
the card interpreted null as an unrated title. A delayed or failed read could
therefore offer a blank editor despite a persisted score and private note.
Both pending-read and failed-read regressions reproduced that behavior.

The card now waits for known state or offers Retry, while continuing to use
already loaded library ratings as before. The regressions restore the read and
open the existing editor, checking that its note and persisted data remain
intact. Sixteen focused loading, fallback and action-recovery tests passed.

## Snapshot refresh after clock rollback

Explicit identity adoption advanced the snapshot version monotonically, but a
later normal refresh wrote the current wall clock directly. With a corrected
clock behind the stored version, this moved metadata backwards and let an old
remote snapshot beat a recently confirmed Keep identity.

All full-snapshot refreshes now use checked monotonic advancement after identity
protection. Title-only localization keeps its unchanged-version contract.
Regressions check untouched user ratings and merge an old identity against the
refreshed chosen identity. The combined library, merge and editor-loading pass
passed 141 tests after this repair.

## Host responsiveness measurements

On 2026-11-08 the user requested explicit responsiveness checks and continued
host-only work while no Android device was connected. Benchmarks ran sequentially
without another project test/build workload, with two warmups and five measured
samples on the pinned SDK. They measure host CPU/SQLite work and scheduling,
not Android frame times, touch latency or memory pressure on a physical phone.

| Existing host workload | Median |
| --- | --- |
| Merge plus remote-behind check: 6,000 snapshots / 3,000 ratings / 3,000 watchlist rows | 27.395 ms |
| Selective movie watchlist read alongside 3,000 ratings | 8.022 ms |
| Former full-state read in the same watchlist fixture | 61.220 ms |
| Ranking 1,000 candidates / 1,000 watchlist rows / 500 taste signals | 68.593 ms |
| Pure taste construction: 500 titles / 150,000 credits | 57.797 ms |
| Unchanged sync application: 1,500 ratings / 1,500 watchlist rows | 154.316 ms; 11 SELECTs |

The new `ui_worker_benchmark.dart` observes a one-millisecond main-isolate timer
while production view functions run through real serialized compute workers.
It includes input/result transfer and, after repair, cold credit preparation.
Result counts are checked; no hardware-dependent timing threshold gates tests.

The contributor-heavy profile originally retained a separately allocated person
object for each work/credit. Sharing equivalent immutable leaves before transfer
preserves credit values and ordering while reducing the transferred object graph.
Preparation yields every 512 records, supports cancellation and remains cached
until the published credit-index map changes.

| 500-title / 150,000-credit worker | Before | After |
| --- | --- | --- |
| Median total preparation + worker time | 257.593 ms | 137.258 ms |
| Median longest main-isolate scheduling gap per sample | 87.181 ms | 3.323 ms |
| Range of longest scheduling gaps over five samples | 32.607–105.442 ms | 2.907–10.452 ms |

Before total samples (ms): 449.846, 268.283, 224.192, 252.592, 257.593.
After total samples (ms): 151.110, 155.655, 137.258, 130.140, 126.824.
Before gaps (ms): 97.133, 54.576, 32.607, 87.181, 105.442.
After gaps (ms): 2.955, 10.452, 3.613, 2.907, 3.323.

The after run also measured 10,000-row rating and statistics workers at medians
of 47.172 ms and 35.619 ms total; their longest scheduling gaps were
5.688–16.661 ms and 6.024–18.165 ms respectively. Those paths were unchanged,
and differences between runs are not attributed to this optimization.

Thirty focused tests passed for payload preservation/sharing/cancellation,
foreground scheduling, stable credit batches, real isolate transfer and ranking.
Phone frame profiling remains pending; these measurements do not establish FPS.

A subsequent sequential run compares raw and shared analytics messages on the
same input, retaining all 300 contributors and each one's 500-title membership:

| 500-title / 150,000-credit analytics worker | Raw | Shared |
| --- | --- | --- |
| Median total time | 235.452 ms | 205.809 ms |
| Median longest main-isolate scheduling gap | 55.034 ms | 8.910 ms |
| Range of longest scheduling gaps | 30.297–134.602 ms | 4.890–14.144 ms |

Raw gaps (ms): 134.602, 30.297, 55.034, 68.277, 30.361.
Shared gaps (ms): 12.644, 7.638, 8.910, 4.890, 14.144.
This confirmed the same transfer issue in `libraryInsightsProvider`, which now
uses the shared preparation cached for the published credit index. Eighteen
focused insights, worker and large-list layout tests passed afterward.

The repeated recommendation sample in this run measured 146.807 ms median
total and scheduling gaps of 2.615–16.101 ms (median 5.388 ms), illustrating
run-to-run variation rather than a fixed latency guarantee. Ratings/statistics
workers on 10,000 rows also occasionally exceeded 20 ms scheduling gaps in this
run; those observations are retained as limits of host responsiveness evidence.

The diversity stress check exposed unnecessary full-table allocation when all
150,000 contributors were unique. Preparation now samples up to 16 evenly
spaced credits per work, yielding in bounded batches, and returns the original
graph when fewer than 5% of sampled records repeat. A dedicated regression
checks that this bypass reuses the original rows. No contributor is discarded.

Final sequential adaptive run (two warmups / five samples):

| Workload | Raw median total | Adaptive median total | Raw scheduling-gap range | Adaptive gap range |
| --- | --- | --- | --- | --- |
| 500 titles, 150,000 credits, 30,000 distinct people | 277.069 ms | 181.861 ms | 25.504–108.848 ms | 6.316–15.112 ms |
| 500 titles, 150,000 entirely distinct people | 208.390 ms | 216.149 ms | 20.403–85.784 ms | 24.006–65.201 ms |
| Analytics with 300 shared people across 500 titles | 181.596 ms | 201.843 ms | 20.768–65.934 ms | 3.077–9.398 ms |

The final recurring-contributor taste case measured 103.667 ms median total,
with 2.261–8.788 ms scheduling gaps. These results support responsiveness gains
for repeated credit graphs, not a claim that all extreme datasets stay within
a frame budget. Completely unique graphs still incur raw transfer/GC pauses;
the adaptive path avoids adding a full sharing table rather than claiming to
eliminate that remaining host stress limit. No phone latency guarantee is made.

## Follow-up: People scroll reset

The reported 0.9.3 symptom remained outside the gesture-deferral coverage:
temporarily empty contributor insights removed role shelves and reduced the
vertical list below the viewport, clamping a scrolled position to zero.
The regression reproduced an 800-to-0 pixel reset before the repair.

People discovery now retains useful contributor groups through indexing and
insight replacement, with a stable vertical PageStorage key. The regression
checks empty and partial loading passes, completed replacement and genuinely
empty completed data. Earlier gesture and horizontal-shelf coverage remains.
The focused regression and subsequent full verification passed on the host.

## Verification

- Final `make verify TEST_ARGS='--concurrency=2 --reporter expanded'` passed:
  696 tests passed, 22 opt-in screenshot scenarios skipped, 222 Dart files
  formatted without changes, analysis clean and version-script fixtures passed.
- `make codegen` passed after the ARB changes; generated localizations are
  included. No dependency, schema, sync-format or application-version bump.
- Five existing host benchmarks and four worker scheduling/diversity cases
  passed sequentially. Measurements and their limitations are recorded above.
- Focused regressions covered failed/canceled operations, retries, stale
  identities, retained notes, clock corrections, timestamp overflow, preserved
  recommendation inputs and real worker transfer. The final editor pass passed
  18 cases including the stale-library fallback and optional calibration failure.
- `git diff --check` passed and relative documentation links were checked.
- No physical-device checks were performed; the user requested host-only work
  after ADB reported no connected device. Android frame time, touch latency,
  energy use and the outstanding two-phone scenario remain unverified.
