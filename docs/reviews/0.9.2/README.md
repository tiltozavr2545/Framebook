# 0.9.2 scroll-stability review

Target: `0.9.2+22`. The reported problem was visible rebuilding and stuttering,
primarily on Discover. The author requested continued source review and repairs,
then closed the scope and authorized commit, push and release. The author subsequently requested completing the three identified remaining
areas (rating lists, statistics and initial filmographies) before publication.
Those additions are included below; unrelated scope remains closed.

## Findings and repairs

| Cause | Repair |
| --- | --- |
| Candidate batches repeatedly reranked visible shelves | Publish the first useful batch, then commit the completed pass |
| Actor-index batches bypassed candidate batching | Commit first-useful/completed credit snapshots for taste weights |
| Feed replacements changed content during gestures | Defer shelf-tree replacement until all scroll activities, including flings, end |
| Shelf sections were disposed outside the viewport | Retain visited finite sections and save independent horizontal offsets |
| Variable-extent shelves could discard tile state on reorder | Fixed-width slots and keyed child-index lookup; tiles stay lazy |
| Each poster badge opened its own live-rating query | Select one score from a shared live-library map |
| Note, external-rating and snapshot-time updates rebuilt tastes | Compare only meaningful taste inputs; preserve sync timestamp semantics |
| Equivalent watchlist rereads invalidated ranking | Suppress equivalent recommendation watchlist input |
| Large taste construction ran before the ranking worker on the UI thread | Serialized profile worker with previous-result retention and independent live exclusions |
| Derived profile getters sorted data after the worker returned | Materialize preferred people, genres and seeds with the profile |
| People progress rebuilt and sorted full browsing/statistics content | Independent progress widgets |
| A small number of huge TV casts bypassed analytics workers | Account for credit and director/actor pair volume as well as title count |
| Title sections restarted loads after scrolling back | Retain headers, editors, ratings, cast and related titles; season/episode rows remain lazy |
| Expanded biography state was discarded by lazy scrolling | Retain biography state while its route stays open |
| Role selection repeatedly rebuilt and sorted filmography | Reuse derived lists for one Person snapshot |
| A pending personal-rating query briefly showed Rate | Use the known live-library rating until the query answers; confirmed null wins |
| Loading reasons, source captions and poster borders changed geometry | Reserve caption/border space; scale numeric cells and bound long values |
| Large cache/catalog JSON and derived actor-list codecs ran on UI | Background parsing/encoding above bounded input thresholds |
| Concurrent identical TMDB requests duplicated loading/parsing | Share pending loads and clear both success and failure with try/finally |
| Glass indicators filtered an opaque solid background | Keep the gradient/highlight without redundant backdrop filtering |
| Ancestor lookups built unbounded SQL parameter lists | Read ancestor snapshots in batches of 400 keys |
| Large rating filters, ordering and day grouping ran in widget builds | Serialized worker above 200 ratings, retaining the previous coherent view |
| Basic statistics, source comparisons and people ordering still ran during rendering | Prepared worker-backed summaries and people views; precomputed score profiles |
| First preparation of a large filmography still blocked the UI | Worker preparation above 200 acting/crew credits with route-scoped reuse |

Root-page swipes were also added for Discover, My ratings, Watchlist and Stats,
in both navigation styles. Horizontal child shelves retain their gestures, nested
cards keep their own navigation, and cancelled losing gestures cannot reset the
active tab. RTL, tab boundaries and reduced-motion behavior use the existing
navigation controller.

There are no local-schema, sync-format, API-key-storage or dependency changes.
Retention is bounded to visited page sections; unbounded result rows remain lazy.

## Validation

Final `make verify` passed 597 tests (20 opt-in renderers skipped), clean
formatting and analysis, and version-script checks. `make verify-version` passes
against `0.9.1+21`. The signed universal APK built successfully; apksigner
validated the existing release certificate
`F4:07:7F:14:A1:36:FF:01:70:F1:CB:C6:4A:1A:F4:20:51:4C:0A:FD`.
Targeted regressions cover candidate/credit publication, equivalent input updates,
large profile replacement, live exclusions, cache corruption and concurrent
writers, duplicate request recovery, lazy shelf building and tile reordering,
vertical/horizontal drag deferral, source-panel geometry at text scales 1/1.8/3
in Russian, biography retention, initial personal ratings, and 1,001-season
ancestor reads. The unchanged ranking benchmark digest is
`1d7eeee141f3ce23b3ef17e3953cebbbddeb6b40df88c0290c03794c1792dd9f`.

An initial signed 0.9.2 candidate was installed over the previous app before the
continued source review. The physical-device shelf reset reproduced before that
candidate and stopped reproducing afterward in For you and Favourite people.
The author then requested source-only investigation; no further physical
reproduction was attempted. That early installation predates the later repairs.

Host-only synthetic profile benchmark (`test/benchmarks/taste_profile_benchmark.dart`):
300 acting credits per title, five samples after two warmups. Before worker and
derived-profile changes, medians were 6,464 us (20 titles), 17,240 us (80), and
66,311 us (500), under concurrent host test load. These wall-clock CPU samples
are not Android AOT/frame timings. Android View `gfxinfo` also does not cover
Flutter's rendered frames sufficiently to claim an FPS improvement; no numerical
phone speedup is claimed.

The final additional-scope checks passed 12 aggregate/worker/layout cases and 53
screen scenarios. Real-worker coverage includes 500-rating replacement while a
prior sort is blocked, dropping queued superseded requests, 600-person ordering,
statistics agreement and role grouping of a 500-title filmography. The combined checks above include these additions. The final signed APK installed successfully with `adb install -r` over the
existing app; Android reports `versionName=0.9.2`, `versionCode=22`. No uninstall
or data clearing was used.

Distribution: [v0.9.2](https://github.com/tiltozavr2545/Framebook/releases/tag/v0.9.2),
with the signed universal `framebook-0.9.2.apk`. Matching CI symbols stay in the
release workflow artifact, outside the public release assets.
